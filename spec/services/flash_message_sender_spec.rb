# frozen_string_literal: true

# spec/services/flash_message_sender_spec.rb

require 'rails_helper'

RSpec.describe FlashMessageSender, type: :service do
  let(:sender_user) { create(:user, full_name: 'Sender User') }
  let(:recipient_user) { create(:user, full_name: 'Recipient User') }
  let(:sender_currency) { create(:currency, name: 'USD') }
  let(:recipient_currency) { create(:currency, name: 'EUR') }

  let(:transaction) do
    create(:transaction, sender: sender_account, recipient: recipient_account, sender_amount: 200.0)
  end
  let(:sender_account) do
    create(:account, user: sender_user, currency: sender_currency, balance: 1000.0, number: '1234567890123400')
  end
  let(:recipient_account) do
    create(:account, user: recipient_user, currency: recipient_currency, balance: 500.0, number: '1234567890123401')
  end

  let!(:exchange_rate) do
    create(:exchange_rate, base_currency: sender_currency, target_currency: recipient_currency, value: 1.5)
  end

  describe '#call' do
    let(:flash_message_sender) { described_class.new(transaction) }

    before do
      allow(Turbo::StreamsChannel).to receive(:broadcast_render_later_to)
    end

    it 'builds the correct message' do
      message = flash_message_sender.send(:build_message)

      expect(message).to include('Sender User')
      expect(message).to include('200.0')
      expect(message).to include('USD')
      expect(message).to include('1234 5678 9012 3401')
      expect(message).to include('500.0')
      expect(message).to include('EUR')
    end

    it 'sends the message to the recipient\'s flash messages channel' do
      flash_message_sender.call

      expect(Turbo::StreamsChannel).to have_received(:broadcast_render_later_to).with(
        [recipient_user, 'flash_messages'],
        partial: 'layouts/shared/personal_flash',
        locals: { flash: { warning: 'Sender User has sent 200.0 USD to account number: 1234 5678 9012 3401. Total account balance: 500.0 EUR' } }
      )
    end
  end
end
