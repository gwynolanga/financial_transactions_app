# frozen_string_literal: true

# app/models/transaction.rb
class Transaction < ApplicationRecord
  include TransactionCustomValidations
  include TransactionStateMachine

  belongs_to :sender, class_name: 'Account', optional: true
  belongs_to :recipient, class_name: 'Account', optional: true

  enum :kind, { immediate: 0, scheduled: 1, deposit: 2, withdrawal: 3 }, validate: true
  enum :status, { pending: 0, deferred: 1, completed: 2, canceled: 3, failed: 4 }, validate: true

  validates :sender_amount, presence: true
  validates :recipient_amount, presence: true
  validates :kind, presence: true
  validates :status, presence: true

  delegate :currency_name, to: :sender, prefix: :sender, allow_nil: true
  delegate :currency_name, to: :recipient, prefix: :recipient, allow_nil: true
  delegate :user_full_name, to: :sender, prefix: :sender, allow_nil: true
  delegate :user_full_name, to: :recipient, prefix: :recipient, allow_nil: true
end
