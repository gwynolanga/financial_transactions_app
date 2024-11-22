# frozen_string_literal: true

class Transaction < ApplicationRecord
  include AASM

  aasm whiny_transitions: false, column: :status, enum: true do
    state :pending, initial: true
    state :completed
    state :canceled
    state :failed

    event :complete do
      transitions from: [:pending], to: :completed
    end

    event :cancel do
      transitions from: [:pending], to: :canceled
    end

    event :fail do
      transitions from: [:pending], to: :failed
    end
  end

  belongs_to :sender, class_name: 'Account'
  belongs_to :recipient, class_name: 'Account'

  enum :kind, { immediate: 0, scheduled: 1 }, validate: true
  enum :status, { pending: 0, completed: 1, canceled: 2, failed: 3 }, validate: true

  validates :sender_amount, presence: true, numericality: { greater_than: 0 }
  validates :recipient_amount, presence: true, numericality: { greater_than: 0 }
  validates :kind, presence: true
  validates :status, presence: true
end
