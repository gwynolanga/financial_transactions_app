# frozen_string_literal: true

class ExchangeRate < ApplicationRecord
  belongs_to :base_currency, class_name: 'Currency'
  belongs_to :target_currency, class_name: 'Currency'

  validate :validate_normalized_pair_uniqueness

  private

  def validate_normalized_pair_uniqueness
    normalized_base, normalized_target = [base_currency.id, target_currency.id].minmax

    return unless ExchangeRate.exists?(base_currency_id: normalized_base, target_currency_id: normalized_target)

    errors.add(:base, 'This currency combination already exists')
  end
end
