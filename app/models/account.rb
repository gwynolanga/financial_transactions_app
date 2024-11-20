class Account < ApplicationRecord
  belongs_to :currency
  belongs_to :user

  validates :number, presence: true, uniqueness: true, length: { is: 16 }
  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: { scope: :currency_id }
end
