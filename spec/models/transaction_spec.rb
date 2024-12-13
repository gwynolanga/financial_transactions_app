# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transaction, type: :model do
  let(:currency1) { create(:currency, name: 'USD') }
  let(:currency2) { create(:currency, name: 'EUR') }
  let(:sender_account) { create(:account, currency: currency1, balance: 1000) }
  let(:recipient_account) { create(:account, currency: currency2, balance: 500) }
  let(:exchange_rate) { create(:exchange_rate, base_currency: currency1, target_currency: currency2, value: 1.5) }

  before do
    exchange_rate
  end

  let(:transaction) do
    create(:transaction,
           sender: sender_account,
           recipient: recipient_account,
           sender_amount: 100,
           kind: :immediate,
           status: :pending)
  end

  describe '#apply_currency_conversion' do
    let(:transaction) { build(:transaction, sender: sender_account, recipient: recipient_account, sender_amount: 100) }

    it 'converts recipient amount using exchange rate if currencies differ' do
      transaction.complete!
      expect(transaction.recipient_amount).to eq(150.0)
    end

    it 'sets recipient amount equal to sender amount if currencies are the same' do
      recipient_account.update!(currency: sender_account.currency)
      transaction.complete!
      expect(transaction.recipient_amount).to eq(100.0)
    end
  end

  describe '#sufficient_balance?' do
    let(:transaction) { build(:transaction, sender: sender_account, sender_amount: 100) }

    it 'returns true if sender has sufficient balance' do
      expect(transaction.send(:sufficient_balance?)).to be true
    end

    it 'returns false if sender has insufficient balance' do
      transaction.sender_amount = 1100.to_d
      expect(transaction.send(:sufficient_balance?)).to be false
    end
  end

  describe 'validations' do
    context 'when sender and recipient are the same' do
      let(:transaction) { build(:transaction, sender: sender_account, recipient: sender_account) }

      it 'is invalid' do
        expect(transaction).not_to be_valid
        expect(transaction.errors[:base]).to include('sender and recipient must be different')
      end
    end

    context 'for immediate transactions' do
      let(:transaction) { build(:transaction, kind: :immediate, recipient: nil) }

      it 'requires a recipient' do
        expect(transaction).not_to be_valid
        expect(transaction.errors[:recipient]).to include('must be present for immediate transactions')
      end
    end

    context 'for scheduled transactions' do
      let(:transaction) { build(:transaction, kind: :scheduled, execution_date: nil) }

      it 'requires an execution date' do
        expect(transaction).not_to be_valid
        expect(transaction.errors[:execution_date]).to include('must be present for scheduled transactions')
      end
    end

    context 'for deposit transactions' do
      let(:transaction) { build(:transaction, :deposit, sender: sender_account) }

      it 'requires sender to be nil' do
        expect(transaction).not_to be_valid
        expect(transaction.errors[:sender]).to include('must be null for deposit transactions')
      end
    end

    context 'for withdrawal transactions' do
      let(:transaction) { build(:transaction, :withdrawal, recipient: recipient_account) }

      it 'requires recipient to be nil' do
        expect(transaction).not_to be_valid
        expect(transaction.errors[:recipient]).to include('must be null for withdrawal transactions')
      end
    end
  end
end
