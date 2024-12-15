# frozen_string_literal: true

# spec/services/transaction_notifier_spec.rb
require 'rails_helper'

RSpec.describe Transactions::MessageSender, type: :service do
  describe '.send_message' do
    let(:flash_message) { { notice: 'Test notice message' } }
    let(:recipient) { create(:user) }
    let(:transaction) { create(:transaction, :completed) }

    before { allow(Turbo::StreamsChannel).to receive(:broadcast_render_later_to) }

    it 'broadcasts the flash message to the recipient using Turbo::StreamsChannel' do
      described_class.send_message(flash_message, recipient, transaction)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_render_later_to).with(
        [recipient, 'flash_messages'],
        partial: 'layouts/shared/flash',
        locals: { flash: flash_message, transaction: transaction }
      )
    end

    context 'with different types of flash messages' do
      it 'handles :notice messages' do
        described_class.send_message({ notice: 'Notice example' }, recipient, transaction)

        expect(Turbo::StreamsChannel).to have_received(:broadcast_render_later_to).with(
          [recipient, 'flash_messages'],
          partial: 'layouts/shared/flash',
          locals: { flash: { notice: 'Notice example' }, transaction: transaction }
        )
      end

      it 'handles :alert messages' do
        described_class.send_message({ alert: 'Alert example' }, recipient, transaction)

        expect(Turbo::StreamsChannel).to have_received(:broadcast_render_later_to).with(
          [recipient, 'flash_messages'],
          partial: 'layouts/shared/flash',
          locals: { flash: { alert: 'Alert example' }, transaction: transaction }
        )
      end

      it 'handles :warning messages' do
        described_class.send_message({ warning: 'Warning example' }, recipient, transaction)

        expect(Turbo::StreamsChannel).to have_received(:broadcast_render_later_to).with(
          [recipient, 'flash_messages'],
          partial: 'layouts/shared/flash',
          locals: { flash: { warning: 'Warning example' }, transaction: transaction }
        )
      end
    end
  end
end
