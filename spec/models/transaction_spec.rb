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

  describe '#convert_recipient_amount' do
    it 'converts recipient amount using exchange rate if currencies differ' do
      transaction.valid?
      expect(transaction.recipient_amount).to eq(150.0)
    end

    it 'sets recipient amount equal to sender amount if currencies are the same' do
      transaction.recipient.currency = sender_account.currency
      transaction.valid?
      expect(transaction.recipient_amount).to eq(100.0)
    end
  end

  describe '#sufficient_balance?' do
    it "returns true if sender's balance is greater than or equal to sender amount" do
      expect(transaction.send(:sufficient_balance?)).to be true
    end

    it "returns false if sender's balance is less than sender amount" do
      transaction.sender_amount = 1100
      expect(transaction.send(:sufficient_balance?)).to be false
    end
  end

  describe '#sender_and_recipient_must_be_different_users' do
    let(:same_account) { create(:account, currency: currency1, balance: 1000) }

    it 'is invalid if sender and recipient are the same account' do
      invalid_transaction = Transaction.new(
        sender: same_account,
        recipient: same_account,
        sender_amount: 100,
        kind: :immediate,
        status: :pending
      )
      expect(invalid_transaction).not_to be_valid
      expect(invalid_transaction.errors[:recipient]).to include('must belong to a different user than the sender')
    end

    it 'is valid if sender and recipient are different accounts' do
      valid_transaction = Transaction.new(
        sender: sender_account,
        recipient: recipient_account,
        sender_amount: 100,
        kind: :immediate,
        status: :pending
      )
      expect(valid_transaction).to be_valid
    end
  end
end
