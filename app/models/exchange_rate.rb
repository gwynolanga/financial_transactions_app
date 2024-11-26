# frozen_string_literal: true

class ExchangeRate < ApplicationRecord
  belongs_to :base_currency, class_name: 'Currency'
  belongs_to :target_currency, class_name: 'Currency'

  validate :validate_normalized_pair_uniqueness

  delegate :name, to: :base_currency, prefix: true
  delegate :name, to: :target_currency, prefix: true

  def self.convert(amount, from_currency, to_currency)
    exchange_rate = find_by(base_currency: from_currency, target_currency: to_currency) ||
                    find_by(base_currency: to_currency, target_currency: from_currency)

    raise("Exchange rate not found for #{from_currency} to #{to_currency}.") unless exchange_rate

    if exchange_rate.base_currency == from_currency
      amount * exchange_rate.value
    else
      amount / exchange_rate.value
    end
  end

  private

  def validate_normalized_pair_uniqueness
    normalized_base, normalized_target = [base_currency.id, target_currency.id].minmax

    return unless ExchangeRate.exists?(base_currency_id: normalized_base, target_currency_id: normalized_target)

    errors.add(:base, 'This currency combination already exists')
  end
end
