# frozen_string_literal: true

# spec/services/transactions/message_builder_spec.rb
require 'rails_helper'

RSpec.describe Transactions::MessageBuilder do
  describe '#sender_message' do
    context 'when transaction is immediate' do
      let(:transaction) { build(:transaction, :completed, kind: :immediate) }
      let(:message_builder) { described_class.new(transaction) }

      it 'returns the correct sender message' do
        expected_message = <<~MESSAGE.strip.gsub(/\s+/, ' ')
          Transfer is successful. You have sent #{transaction.sender_amount} #{transaction.sender_currency_name}
          to account number: #{transaction.recipient.human_number}. You now have #{transaction.sender.balance}
          #{transaction.sender_currency_name} remaining.
        MESSAGE

        expect(message_builder.sender_message).to eq(expected_message)
      end
    end

    context 'when transaction is scheduled' do
      let(:transaction) { build(:transaction, :completed, :scheduled) }
      let(:message_builder) { described_class.new(transaction) }

      it 'returns the correct sender message' do
        expected_message = <<~MESSAGE.strip.gsub(/\s+/, ' ')
          Transfer is scheduled. The amount of #{transaction.sender_amount} #{transaction.sender_currency_name}
          will be debited from your account number: #{transaction.recipient.human_number}. Execution date:
          #{transaction.execution_date}.
        MESSAGE

        expect(message_builder.sender_message).to eq(expected_message)
      end
    end

    context 'when transaction is deposit' do
      let(:transaction) { build(:transaction, :completed, :deposit) }
      let(:message_builder) { described_class.new(transaction) }

      it 'returns an empty sender message' do
        expect(message_builder.sender_message).to be_empty
      end
    end

    context 'when transaction is withdrawal' do
      let(:transaction) { build(:transaction, :completed, :withdrawal) }
      let(:message_builder) { described_class.new(transaction) }

      it 'returns the correct sender message' do
        expected_message = <<~MESSAGE.strip.gsub(/\s+/, ' ')
          Withdrawal is successful. #{transaction.sender_amount} #{transaction.sender_currency_name} has been
          withdrawn from your account: #{transaction.sender.human_number}. You now have #{transaction.sender.balance}
          #{transaction.sender_currency_name} remaining.
        MESSAGE

        expect(message_builder.sender_message).to eq(expected_message)
      end
    end
  end

  describe '#recipient_message' do
    context 'when transaction is either immediate or scheduled' do
      let(:expected_message) do
        <<~MESSAGE.strip.gsub(/\s+/, ' ')
          Payment is successful. #{transaction.sender_user_full_name} has sent you #{transaction.recipient_amount}
          #{transaction.recipient_currency_name} to your account number: #{transaction.recipient.human_number}.
          You now have #{transaction.recipient.balance} #{transaction.recipient_currency_name} available.
        MESSAGE
      end

      context 'when transaction is immediate' do
        let(:transaction) { build(:transaction, :completed, kind: :immediate) }
        let(:message_builder) { described_class.new(transaction) }

        it 'returns the correct recipient message' do
          expect(message_builder.recipient_message).to eq(expected_message)
        end
      end

      context 'when transaction is scheduled' do
        let(:transaction) { build(:transaction, :completed, :scheduled) }
        let(:message_builder) { described_class.new(transaction) }

        it 'returns the correct recipient message' do
          expect(message_builder.recipient_message).to eq(expected_message)
        end
      end
    end

    context 'when transaction is deposit' do
      let(:transaction) { build(:transaction, :completed, :deposit) }
      let(:message_builder) { described_class.new(transaction) }

      it 'returns the correct recipient message' do
        expected_message = <<~MESSAGE.strip.gsub(/\s+/, ' ')
          Deposit is successful. #{transaction.recipient_amount} #{transaction.recipient_currency_name} has been
          deposited into your account: #{transaction.recipient.human_number}. You now have
          #{transaction.recipient.balance} #{transaction.recipient_currency_name} available.
        MESSAGE

        expect(message_builder.recipient_message).to eq(expected_message)
      end
    end

    context 'when transaction is withdrawal' do
      let(:transaction) { build(:transaction, :completed, :withdrawal) }
      let(:message_builder) { described_class.new(transaction) }

      it 'returns an empty recipient message' do
        expect(message_builder.recipient_message).to be_empty
      end
    end
  end

  describe '#failed_sender_message' do
    let(:expected_message) do
      <<~MESSAGE.strip.gsub(/\s+/, ' ')
        Transaction with id=#{transaction.id} is failed. Insufficient funds in your account:
        #{transaction.sender.human_number}. Sender amount > Sender balance:
        #{transaction.sender_amount} > #{transaction.sender.balance}.
      MESSAGE
    end

    context 'when transaction is immediate' do
      let(:transaction) { build(:transaction, :failed, kind: :immediate) }
      let(:message_builder) { described_class.new(transaction) }

      it 'returns the correct failed sender message' do
        expect(message_builder.failed_sender_message).to eq(expected_message)
      end
    end

    context 'when transaction is scheduled' do
      let(:transaction) { build(:transaction, :failed, :scheduled) }
      let(:message_builder) { described_class.new(transaction) }

      it 'returns the correct failed sender message' do
        expect(message_builder.failed_sender_message).to eq(expected_message)
      end
    end

    context 'when transaction is deposit' do
      let(:transaction) { build(:transaction, :failed, :deposit) }
      let(:message_builder) { described_class.new(transaction) }

      it 'returns an empty failed sender message' do
        expect(message_builder.failed_sender_message).to be_empty
      end
    end

    context 'when transaction is withdrawal' do
      let(:transaction) { build(:transaction, :failed, :withdrawal) }
      let(:message_builder) { described_class.new(transaction) }

      it 'returns the correct failed sender message' do
        expect(message_builder.failed_sender_message).to eq(expected_message)
      end
    end
  end
end
