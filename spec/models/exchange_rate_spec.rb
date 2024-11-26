# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExchangeRate, type: :model do
  let(:currency1) { create(:currency, name: 'USD') }
  let(:currency2) { create(:currency, name: 'EUR') }
  let(:exchange_rate) { create(:exchange_rate, base_currency: currency1, target_currency: currency2, value: 1.5) }

  describe '.convert' do
    before do
      create(:exchange_rate, base_currency: currency1, target_currency: currency2, value: 1.5)
    end

    context 'when the exchange rate exists for the given currencies' do
      it 'converts the amount using the direct exchange rate' do
        result = ExchangeRate.convert(100, currency1, currency2)
        expect(result).to eq(150.0)
      end

      it 'converts the amount using the reversed exchange rate' do
        result = ExchangeRate.convert(150, currency2, currency1)
        expect(result).to eq(100.0)
      end
    end

    context 'when the exchange rate does not exist' do
      let(:currency3) { create(:currency, name: 'GBP') }

      it 'raises an error' do
        expect do
          ExchangeRate.convert(100, currency1, currency3)
        end.to raise_error(RuntimeError, "Exchange rate not found for #{currency1} to #{currency3}.")
      end
    end
  end
end
