# frozen_string_literal: true

# spec/services/transactions/notifier_spec.rb
require 'rails_helper'

RSpec.describe Transactions::Notifier, type: :service do
  let(:sender) { create(:account) }
  let(:recipient) { create(:account) }
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
      let(:transaction) { create(:transaction, sender:, recipient:) }

      context 'when sender and recipient have the same user' do
        let(:user) { create(:user) }
        let(:sender) { create(:account, user: user) }
        let(:recipient) { create(:account, user: user) }

        it 'returns sender and recipient messages' do
          message = {
            notice: notifier.message_builder.sender_message,
            warning: notifier.message_builder.recipient_message
          }
          expect(notifier.send(:notify_successful_transaction)).to eq(message)
        end
      end

      context 'when sender and recipient have different users' do
        it 'sends recipient message to recipient user' do
          message = { warning: notifier.message_builder.recipient_message }
          expect(notifier).to receive(:send_message).with(message, recipient.user)
          notifier.send(:notify_successful_transaction)
        end

        it 'returns sender message' do
          message = { notice: notifier.message_builder.sender_message }
          expect(notifier.send(:notify_successful_transaction)).to eq(message)
        end
      end
    end

    context 'when transaction is scheduled' do
      context 'when transaction is completed' do
        let(:transaction) { create(:transaction, :scheduled, :completed, sender:, recipient:) }

        it 'sends sender message to sender user and recipient message to recipient user' do
          sender_message = { warning: notifier.message_builder.sender_message }
          recipient_message = { warning: notifier.message_builder.recipient_message }

          expect(notifier).to receive(:send_message).with(sender_message, sender.user)
          expect(notifier).to receive(:send_message).with(recipient_message, recipient.user)
          notifier.send(:notify_successful_transaction)
        end

        it 'returns empty hash' do
          expect(notifier.send(:notify_successful_transaction)).to eq({})
        end
      end

      context 'when transaction is not completed' do
        let(:transaction) { create(:transaction, :scheduled, sender:, recipient:) }

        it 'returns sender message' do
          message = { notice: notifier.message_builder.sender_message }
          expect(notifier.send(:notify_successful_transaction)).to eq(message)
        end
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
