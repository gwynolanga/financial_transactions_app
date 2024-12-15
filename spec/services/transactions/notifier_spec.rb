# frozen_string_literal: true

# spec/services/transactions/notifier_spec.rb
require 'rails_helper'

RSpec.describe Transactions::Notifier, type: :service do
  let(:sender) { create(:account) }
  let(:recipient) { create(:account) }
  let(:transaction) { create(:transaction, sender:, recipient:) }
  let(:notifier) { described_class.new(transaction) }

  describe '#call' do
    context 'when transaction is deferred' do
      let(:transaction) { create(:transaction, :deferred, sender:, recipient:) }

      it 'notifies about successful transaction' do
        expect(notifier).to receive(:notify_successful_transaction)
        notifier.call
      end
    end

    context 'when transaction is completed' do
      let(:transaction) { create(:transaction, :completed, sender:, recipient:) }

      it 'notifies about successful transaction' do
        expect(notifier).to receive(:notify_successful_transaction)
        notifier.call
      end
    end

    context 'when transaction is failed' do
      let(:transaction) { create(:transaction, :failed, sender:, recipient:) }

      it 'notifies about failed transaction' do
        expect(notifier).to receive(:notify_failed_transaction)
        notifier.call
      end
    end
  end

  describe '#notify_successful_transaction' do
    context 'when transaction is deposit' do
      let(:transaction) { create(:transaction, :deposit, recipient:) }

      it 'returns recipient message' do
        message = { notice: notifier.message_builder.recipient_message }
        expect(notifier.send(:notify_successful_transaction)).to eq(message)
      end
    end

    context 'when transaction is withdrawal' do
      let(:transaction) { create(:transaction, :withdrawal, sender:) }

      it 'returns sender message' do
        message = { notice: notifier.message_builder.sender_message }
        expect(notifier.send(:notify_successful_transaction)).to eq(message)
      end
    end

    context 'when transaction is immediate' do
      it 'returns sender message' do
        message = { notice: notifier.message_builder.sender_message }
        expect(notifier.send(:notify_successful_transaction)).to eq(message)
      end
    end

    context 'when transaction is scheduled' do
      let(:transaction) { create(:transaction, :scheduled, sender:, recipient:) }

      it 'sends sender and recipient messages via Transactions::MessageSender' do
        sender_params = [{ warning: notifier.message_builder.sender_message }, sender.user, transaction]
        recipient_params = [{ warning: notifier.message_builder.recipient_message }, recipient.user, transaction]

        expect(Transactions::MessageSender).to receive(:send_message).with(*sender_params)
        expect(Transactions::MessageSender).to receive(:send_message).with(*recipient_params)
        notifier.send(:notify_successful_transaction)
      end

      it 'returns sender message' do
        message = { notice: notifier.message_builder.sender_message }
        expect(notifier.send(:notify_successful_transaction)).to eq(message)
      end
    end
  end

  describe '#notify_failed_transaction' do
    context 'when transaction is scheduled' do
      let(:transaction) { create(:transaction, :scheduled, :failed, sender:, recipient:) }

      it 'sends failed sender message to sender user' do
        message = { alert: notifier.message_builder.failed_sender_message }
        expect(notifier).to receive(:send_message).with(message, sender.user)
        notifier.send(:notify_failed_transaction)
      end
    end

    context 'when transaction is not scheduled' do
      let(:transaction) { create(:transaction, :failed, sender:, recipient:) }

      it 'returns failed sender message' do
        message = { alert: notifier.message_builder.failed_sender_message }
        expect(notifier.send(:notify_failed_transaction)).to eq(message)
      end
    end
  end
end
