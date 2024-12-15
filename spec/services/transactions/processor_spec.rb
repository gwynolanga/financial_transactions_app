# frozen_string_literal: true

# spec/services/transactions/processor_spec.rb
require 'rails_helper'

RSpec.describe Transactions::Processor, type: :service do
  describe '#call' do
    let(:sender) { create(:account, balance: 500.0) }
    let(:recipient) { create(:account, balance: 300.0) }

    context 'when the transaction is pending or deferred' do
      context 'when the transaction is a deposit' do
        let(:transaction) { create(:transaction, :deposit, recipient: recipient, recipient_amount: 200.0) }

        it 'increases the recipient balance' do
          expect { described_class.call(transaction) }.to change { recipient.reload.balance }.by(200.0)
        end

        it 'does not change the sender balance' do
          expect { described_class.call(transaction) }.not_to(change { sender.reload.balance })
        end
      end

      context 'when the transaction is a withdrawal' do
        let(:transaction) { create(:transaction, :withdrawal, sender: sender, sender_amount: 150.0) }

        it 'decreases the sender balance' do
          expect { described_class.call(transaction) }.to change { sender.reload.balance }.by(-150.0)
        end

        it 'does not change the recipient balance' do
          expect { described_class.call(transaction) }.not_to(change { recipient.reload.balance })
        end
      end

      context 'when the transaction is a transfer' do
        let(:transaction) do
          create(:transaction, sender: sender, recipient: recipient, sender_amount: 100.0, recipient_amount: 100.0)
        end

        it 'decreases the sender balance' do
          expect { described_class.call(transaction) }.to change { sender.reload.balance }.by(-100.0)
        end

        it 'increases the recipient balance' do
          expect { described_class.call(transaction) }.to change { recipient.reload.balance }.by(100.0)
        end
      end

      context 'when sender has insufficient balance for withdrawal or transfer' do
        let(:transaction) do
          create(:transaction, sender: sender, recipient: recipient, sender_amount: 600.0, recipient_amount: 600.0)
        end

        it 'raises an ActiveRecord::RecordInvalid error' do
          expect { described_class.call(transaction) }.to raise_error(ActiveRecord::RecordInvalid)
          expect(transaction.sender.reload.balance).to eq(sender.balance)
          expect(transaction.recipient.reload.balance).to eq(recipient.balance)
        end
      end
    end

    context 'when the transaction is not pending or deferred' do
      let(:transaction) { create(:transaction, :completed) }

      it 'does not process the transaction' do
        expect_any_instance_of(described_class).not_to receive(:process_deposit)
        expect_any_instance_of(described_class).not_to receive(:process_withdrawal)
        expect_any_instance_of(described_class).not_to receive(:process_transfer)

        described_class.call(transaction)
      end
    end
  end
end
