# frozen_string_literal: true

class Transaction < ApplicationRecord
  include AASM

  aasm whiny_transitions: false, column: :status, enum: true do
    state :pending, initial: true
    state :deferred
    state :completed
    state :canceled
    state :failed

    event :defer do
      transitions from: :pending, to: :deferred, after: :schedule_transaction
    end

    event :complete do
      transitions from: %i[pending deferred], to: :completed, after: :finalize_transaction
    end

    event :cancel do
      transitions from: %i[pending deferred], to: :canceled
    end

    event :fail do
      transitions from: %i[pending deferred], to: :failed
    end
  end

  belongs_to :sender, class_name: 'Account'
  belongs_to :recipient, class_name: 'Account'

  enum :kind, { immediate: 0, scheduled: 1 }, validate: true
  enum :status, { pending: 0, deferred: 1, completed: 2, canceled: 3, failed: 4 }, validate: true

  validates :sender_amount, presence: true, numericality: { greater_than: 0 }
  validates :recipient_amount, presence: true, numericality: { greater_than: 0 }
  validates :kind, presence: true
  validates :status, presence: true

  before_validation :convert_recipient_amount, if: :pending?

  private

  def convert_recipient_amount
    self.recipient_amount = if sender.currency_name == recipient.currency_name
                              sender_amount
                            else
                              ExchangeRate.convert(sender_amount, sender.currency, recipient.currency)
                            end
  end

  def schedule_transaction
    ScheduledTransactionJob.set(wait_until: execution_date).perform_later(id)
  end

  def finalize_transaction
    ApplicationRecord.transaction do
      raise ActiveRecord::Rollback if sender.balance < sender_amount

      transfer_funds
    end
  rescue StandardError => e
    fail!
    Rails.logger.error("Transaction failed: #{e.message}")
  end

  def transfer_funds
    sender.with_lock do
      recipient.with_lock do
        sender.update!(balance: sender.balance - sender_amount)
        recipient.update!(balance: recipient.balance + recipient_amount)
      end
    end
  end
end
