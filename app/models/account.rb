class Account < ApplicationRecord
  belongs_to :currency
  belongs_to :holder, class_name: 'User', foreign_key: 'holder_id'

  validates :number, presence: true, uniqueness: true
  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
