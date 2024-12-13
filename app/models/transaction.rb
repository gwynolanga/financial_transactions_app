# frozen_string_literal: true

class Transaction < ApplicationRecord
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

  belongs_to :sender, class_name: 'Account', optional: true
  belongs_to :recipient, class_name: 'Account', optional: true

  enum :kind, { immediate: 0, scheduled: 1, deposit: 2, withdrawal: 3 }, validate: true
  enum :status, { pending: 0, deferred: 1, completed: 2, canceled: 3, failed: 4 }, validate: true

  validates :sender_amount, presence: true
  validates :recipient_amount, presence: true
  validates :kind, presence: true
  validates :status, presence: true

  validate :validate_sender_and_recipient_must_be_different
  validate :validate_immediate_transaction, if: -> { immediate? }
  validate :validate_scheduled_transaction, if: -> { scheduled? }
  validate :validate_deposit_transaction, if: -> { deposit? }
  validate :validate_withdrawal_transaction, if: -> { withdrawal? }

  delegate :currency_name, to: :sender, prefix: :sender, allow_nil: true
  delegate :currency_name, to: :recipient, prefix: :recipient, allow_nil: true
  delegate :user_full_name, to: :sender, prefix: :sender, allow_nil: true
  delegate :user_full_name, to: :recipient, prefix: :recipient, allow_nil: true

  private

  # Ensure sender and recipient are not the same account
  def validate_sender_and_recipient_must_be_different
    return unless sender == recipient

    errors.add(:base, :sender_and_recipient_invalid, message: 'sender and recipient must be different')
  end

  # Validation for immediate transactions (kind = 0)
  def validate_immediate_transaction
    errors.add(:recipient, 'must be present for immediate transactions') if recipient.blank?
    return unless sender_amount.present? && (sender_amount.negative? || sender_amount.zero?)

    errors.add(:sender_amount, 'must be greater than 0 for immediate transactions')
  end

  # Validation for scheduled transactions (kind = 1)
  def validate_scheduled_transaction
    errors.add(:recipient, 'must be present for scheduled transactions') if recipient.blank?
    errors.add(:execution_date, 'must be present for scheduled transactions') if execution_date.blank?
    return unless sender_amount.present? && (sender_amount.negative? || sender_amount.zero?)

    errors.add(:sender_amount, 'must be greater than 0 for scheduled transactions')
  end

  # Validation for deposit transactions (kind = 2)
  def validate_deposit_transaction
    errors.add(:sender, 'must be null for deposit transactions') if sender.present?
    if sender_amount.present? && !sender_amount.zero?
      errors.add(:sender_amount, 'must be equal to 0 for deposit transactions')
    end
    return unless recipient_amount.present? && (recipient_amount.negative? || recipient_amount.zero?)

    errors.add(:recipient_amount, 'must be greater than 0 for deposit transactions')
  end

  # Validation for withdrawal transactions (kind = 3)
  def validate_withdrawal_transaction
    errors.add(:recipient, 'must be null for withdrawal transactions') if recipient.present?
    if recipient_amount.present? && !recipient_amount.zero?
      errors.add(:recipient_amount, 'must be equal to 0 for withdrawal transactions')
    end
    return unless sender_amount.present? && (sender_amount.negative? || sender_amount.zero?)

    errors.add(:sender_amount, 'must be greater than 0 for withdrawal transactions')
  end

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
    ScheduledTransactionJob.set(wait_until: execution_date || Time.zone.now).perform_later(id)
  end

  def process_transaction
    ActiveRecord::Base.transaction do
      case kind
      when 'deposit' then process_deposit
      when 'withdrawal' then process_withdrawal
      else process_transfer
      end
    end
  end

  def process_deposit
    recipient.with_lock do
      recipient.update!(balance: recipient.balance + recipient_amount)
    end
  end

  def process_withdrawal
    sender.with_lock do
      sender.update!(balance: sender.balance - sender_amount)
    end
  end

  def process_transfer
    sender.with_lock do
      recipient.with_lock do
        sender.update!(balance: sender.balance - sender_amount)
        recipient.update!(balance: recipient.balance + recipient_amount)
      end
    end
  end

  def sufficient_balance?
    return true if deposit?

    sender.balance >= sender_amount
  end
end
