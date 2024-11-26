# frozen_string_literal: true

# spec/factories/exchange_rates.rb
FactoryBot.define do
  factory :exchange_rate do
    association :base_currency, factory: :currency
    association :target_currency, factory: :currency
    value { 1.5 }

    after(:build) do |exchange_rate|
      if exchange_rate.base_currency == exchange_rate.target_currency
        raise 'Base currency and target currency must be different'
      end
    end
  end
end
