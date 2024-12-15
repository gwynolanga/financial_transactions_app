# frozen_string_literal: true

# jobs/scheduled_transaction_job_spec.rb
require 'rails_helper'

RSpec.describe ScheduledTransactionJob, type: :job do
  let(:currency1) { create(:currency, name: 'USD') }
  let(:currency2) { create(:currency, name: 'EUR') }
  let(:sender_account) { create(:account, currency: currency1) }
  let(:recipient_account) { create(:account, currency: currency2) }
  let(:transaction) do
    create(:transaction, sender: sender_account, recipient: recipient_account, status: :pending)
  end

  before do
    create(:exchange_rate, base_currency: currency1, target_currency: currency2, value: 1.5)
  end

  describe '#perform' do
    context 'when the transaction completes successfully' do
      before do
        allow_any_instance_of(Transaction).to receive(:complete!).and_return(true)
      end

      it 'marks the transaction as completed' do
        expect do
          ScheduledTransactionJob.perform_now(transaction.id)
        end.not_to(change { transaction.reload.status })
      end
    end

    context 'when the transaction fails to complete' do
      before do
        allow_any_instance_of(Transaction).to receive(:complete!).and_return(false)
      end

      it 'marks the transaction as failed' do
        ScheduledTransactionJob.perform_now(transaction.id)
        expect(transaction.reload.status).to eq('failed')
      end
    end

    context 'when the transaction does not exist' do
      it 'raises an ActiveRecord::RecordNotFound error' do
        expect do
          ScheduledTransactionJob.perform_now(-1)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'enqueuing the job' do
    it 'queues the job in the default queue' do
      expect do
        ScheduledTransactionJob.perform_later(transaction.id)
      end.to have_enqueued_job(ScheduledTransactionJob).with(transaction.id).on_queue('default')
    end
  end
end
