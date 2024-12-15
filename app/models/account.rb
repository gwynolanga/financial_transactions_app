# frozen_string_literal: true

# app/models/account.rb
class Account < ApplicationRecord
  belongs_to :currency
  belongs_to :user

  has_many :outgoing_transactions, class_name: 'Transaction', foreign_key: 'sender_id', dependent: :destroy,
                                   inverse_of: :sender
  has_many :incoming_transactions, class_name: 'Transaction', foreign_key: 'recipient_id', dependent: :destroy,
                                   inverse_of: :recipient

  validates :number, presence: true, uniqueness: true, length: { is: 16 }
  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency_id, uniqueness: { scope: :user_id }

  delegate :name, to: :currency, prefix: true
  delegate :full_name, to: :user, prefix: true

  before_validation :generate_unique_account_number, on: :create

  def transactions
    Transaction.includes(sender: %i[user currency], recipient: %i[user currency])
               .references(:users, :currencies)
               .where(sender_id: id).or(Transaction.where(recipient_id: id))
  end

  def human_number
    number.scan(/\d{4}/).join(' ')
  end

  def build_transaction(attributes = {}, type:)
    case type
    when :outgoing
      outgoing_transactions.build(attributes)
    when :incoming
      incoming_transactions.build(attributes)
    else
      raise(ArgumentError, 'Invalid transaction type. Use :outgoing or :incoming.')
    end
  end

  private

  def generate_unique_account_number
    return if number.present?

    loop do
      self.number = SecureRandom.random_number(10**16).to_s.rjust(16, '0')
      break unless Account.exists?(number: number)
    end
  end
end
