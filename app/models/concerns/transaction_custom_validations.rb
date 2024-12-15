# frozen_string_literal: true

# app/models/concerns/transaction_custom_validations.rb
module TransactionCustomValidations
  extend ActiveSupport::Concern

  included do
    validate :validate_sender_and_recipient_must_be_different
    validate :validate_immediate_transaction, if: -> { immediate? }
    validate :validate_scheduled_transaction, if: -> { scheduled? }
    validate :validate_deposit_transaction, if: -> { deposit? }
    validate :validate_withdrawal_transaction, if: -> { withdrawal? }
  end

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
    validate_sender_absence
    validate_amount(sender_amount, 0, :sender_amount, 'must be equal to 0 for deposit transactions')
    validate_positive_amount(recipient_amount, :recipient_amount, 'must be greater than 0 for deposit transactions')
  end

  # Validation for withdrawal transactions (kind = 3)
  def validate_withdrawal_transaction
    validate_recipient_absence
    validate_amount(recipient_amount, 0, :recipient_amount, 'must be equal to 0 for withdrawal transactions')
    validate_positive_amount(sender_amount, :sender_amount, 'must be greater than 0 for withdrawal transactions')
  end

  def validate_sender_absence
    errors.add(:sender, 'must be null for deposit transactions') if sender.present?
  end

  def validate_recipient_absence
    errors.add(:recipient, 'must be null for withdrawal transactions') if recipient.present?
  end

  def validate_amount(value, expected, attribute, error_message)
    return unless value.present? && value != expected

    errors.add(attribute, error_message)
  end

  def validate_positive_amount(value, attribute, error_message)
    return unless value.present? && (value.negative? || value.zero?)

    errors.add(attribute, error_message)
  end
end
