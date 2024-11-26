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
      transitions from: %i[pending deferred], to: :completed, guard: :sufficient_balance?, after: :process_transaction
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

  delegate :currency_name, to: :sender, prefix: :sender, allow_nil: true
  delegate :currency_name, to: :recipient, prefix: :recipient, allow_nil: true
  delegate :user_full_name, to: :sender, prefix: :sender, allow_nil: true
  delegate :user_full_name, to: :recipient, prefix: :recipient, allow_nil: true

  before_validation :convert_recipient_amount, if: :pending?

  private

  def convert_recipient_amount
    return unless sender && recipient

    self.recipient_amount = if sender.currency_name == recipient.currency_name
                              sender_amount
                            else
                              ExchangeRate.convert(sender_amount, sender.currency, recipient.currency)
                            end
  end

  def schedule_transaction
    ScheduledTransactionJob.set(wait_until: execution_date || Time.zone.now).perform_later(id)
  end

  def process_transaction
    ActiveRecord::Base.transaction do
      sender.with_lock do
        recipient.with_lock do
          sender.update!(balance: sender.balance - sender_amount)
          recipient.update!(balance: recipient.balance + recipient_amount)
        end
      end
    end
  end

  def sufficient_balance?
    sender.balance >= sender_amount
  end
end
