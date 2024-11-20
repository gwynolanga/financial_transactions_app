# frozen_string_literal: true

class Account < ApplicationRecord
  belongs_to :currency
  belongs_to :user

  has_many :transactions_as_sender, class_name: 'Transaction', foreign_key: 'sender_id', dependent: :destroy,
                                    inverse_of: :sender
  has_many :transactions_as_recipient, class_name: 'Transaction', foreign_key: 'recipient_id', dependent: :destroy,
                                       inverse_of: :recipient

  validates :number, presence: true, uniqueness: true, length: { is: 16 }
  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: { scope: :currency_id }
end
