# frozen_string_literal: true

class Currency < ApplicationRecord
  has_many :accounts, dependent: :destroy
  has_many :base_currency_rates, class_name: 'ExchangeRate', foreign_key: 'base_currency_id', dependent: :destroy,
                                 inverse_of: :base_currency
  has_many :target_currency_rates, class_name: 'ExchangeRate', foreign_key: 'target_currency_id', dependent: :destroy,
                                   inverse_of: :target_currency

  validates :name, presence: true, uniqueness: true
end
