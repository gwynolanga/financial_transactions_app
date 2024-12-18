# frozen_string_literal: true

# app/models/concerns/transaction_state_machine.rb
module TransactionStateMachine
  extend ActiveSupport::Concern

  included do
    include AASM

    aasm whiny_transitions: false, column: :status, enum: true do
      state :pending, initial: true
      state :deferred
      state :completed
      state :canceled
      state :failed

      after_all_transitions :apply_currency_conversion

      event :defer do
        transitions from: :pending, to: :deferred, after: :schedule_transaction
      end

      event :complete do
        transitions from: %i[pending deferred], to: :completed, guard: :sufficient_balance?, after: :process_transaction
      end

      event :cancel do
        transitions from: %i[pending deferred], to: :canceled
      end

      event :fail do
        transitions from: %i[pending deferred], to: :failed
      end
    end
  end

  private

  # Convert recipient_amount based on sender and recipient currencies
  def apply_currency_conversion
    return unless sender && recipient

    self.recipient_amount = if sender.currency_name == recipient.currency_name
                              sender_amount
                            else
                              ExchangeRate.convert(sender_amount, sender.currency, recipient.currency)
                            end
  end

  def schedule_transaction
    ScheduledTransactionJob.set(wait_until: execution_date).perform_later(id)
  end

  def process_transaction
    Transactions::Processor.call(self)
  end

  def sufficient_balance?
    return true if deposit?

    sender.balance >= sender_amount
  end
end
