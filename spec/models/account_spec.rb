# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account, type: :model do
  let(:user) { create(:user) }
  let(:currency) { create(:currency) }
  let(:recipient_currency) { create(:currency) }
  let(:account) { create(:account, user: user, currency: currency) }

  before do
    create(:exchange_rate, base_currency: currency, target_currency: recipient_currency, value: 1.5)
  end

  describe 'callbacks' do
    context 'before validation' do
      it 'generates a unique account number if not provided' do
        new_account = Account.new(user: user, currency: currency, balance: 1000)
        expect(new_account.number).to be_nil
        new_account.valid?
        expect(new_account.number).to be_present
        expect(new_account.number.length).to eq(16)
      end

      it 'does not overwrite an existing account number' do
        custom_number = '1234567890123456'
        new_account = Account.new(user: user, currency: currency, balance: 1000, number: custom_number)
        new_account.valid?
        expect(new_account.number).to eq(custom_number)
      end
    end
  end

  describe '#transactions' do
    let(:recipient_account) { create(:account, currency: recipient_currency) }
    let!(:outgoing_transaction) { create(:transaction, sender: account, recipient: recipient_account) }
    let!(:incoming_transaction) do
      create(:transaction, sender: recipient_account, recipient: account, status: :completed)
    end
    let!(:pending_incoming_transaction) do
      create(:transaction, sender: recipient_account, recipient: account, status: :pending)
    end

    it 'returns all transactions where the account is sender or recipient' do
      expect(account.transactions).to match_array([outgoing_transaction, incoming_transaction])
    end

    it 'does not return pending incoming transactions' do
      expect(account.transactions).not_to include(pending_incoming_transaction)
    end
  end

  describe '#human_number' do
    it 'formats the account number into human-readable groups of 4 digits' do
      account.number = '1234567890123456'
      expect(account.human_number).to eq('1234 5678 9012 3456')
    end
  end

  describe '#build_transaction' do
    let(:recipient_account) { create(:account) }

    context 'when type is :outgoing' do
      it 'builds an outgoing transaction' do
        transaction = account.build_transaction({ recipient_id: recipient_account.id, sender_amount: 100 },
                                                type: :outgoing)
        expect(transaction).to be_a(Transaction)
        expect(transaction.sender).to eq(account)
      end
    end

    context 'when type is :incoming' do
      it 'builds an incoming transaction' do
        transaction = account.build_transaction({ sender_id: recipient_account.id, recipient_amount: 100 },
                                                type: :incoming)
        expect(transaction).to be_a(Transaction)
        expect(transaction.recipient).to eq(account)
      end
    end

    context 'when type is invalid' do
      it 'raises an ArgumentError' do
        expect do
          account.build_transaction({}, type: :invalid_type)
        end.to raise_error(ArgumentError, 'Invalid transaction type. Use :outgoing or :incoming.')
      end
    end
  end
end
