# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Transactions', type: :request do
  let(:user) { create(:user) }
  let(:currency) { create(:currency) }
  let(:account) { create(:account, user: user, currency: currency) }
  let(:recipient_account) { create(:account, currency: currency) }
  let(:valid_attributes) do
    { sender_amount: 100, kind: :immediate, recipient_id: recipient_account.id }
  end
  let(:invalid_attributes) do
    { sender_amount: nil, kind: nil, recipient_id: nil }
  end

  before do
    sign_in user
  end

  describe 'GET /show' do
    let(:transaction) { create(:transaction, sender: account, recipient: recipient_account) }

    it 'returns the transaction details and page number' do
      get account_transaction_path(account, transaction)
      expect(response).to be_successful
      expect(assigns(:transaction)).to eq(transaction)
      expect(assigns(:page)).to eq(1)
    end

    it 'renders the show template' do
      get account_transaction_path(account, transaction)
      expect(response).to render_template(:show)
    end
  end

  describe 'GET /new' do
    it 'assigns a new transaction to @transaction' do
      get new_account_transaction_path(account)
      expect(response).to be_successful
      expect(assigns(:transaction)).to be_a_new(Transaction)
    end

    it 'renders the new template' do
      get new_account_transaction_path(account)
      expect(response).to render_template(:new)
    end
  end

  describe 'POST /create' do
    context 'with valid parameters' do
      it 'creates a new transaction' do
        expect do
          post account_transactions_path(account), params: { transaction: valid_attributes }
        end.to change(Transaction, :count).by(1)
      end

      it 'redirects to the account page with a success notice' do
        post account_transactions_path(account), params: { transaction: valid_attributes }
        expect(response).to redirect_to(account_path(account))
        expect(flash[:notice]).to eq('The transfer was successfully completed.')
      end

      it 'handles scheduled transactions' do
        valid_attributes[:kind] = :scheduled
        valid_attributes[:execution_date] = 1.day.from_now
        post account_transactions_path(account), params: { transaction: valid_attributes }
        expect(Transaction.last).to be_deferred
      end

      it 'notifies on completed immediate transactions' do
        notifier_double = instance_double(TransactionNotifier, call: true)
        allow(TransactionNotifier).to receive(:new).and_return(notifier_double)

        post account_transactions_path(account), params: { transaction: valid_attributes }
        expect(Transaction.last).to be_completed
        expect(notifier_double).to have_received(:call)
      end

      it 'sets the transaction status to failed if completion fails' do
        allow_any_instance_of(Transaction).to receive(:complete!).and_return(false)
        post account_transactions_path(account), params: { transaction: valid_attributes }
        expect(Transaction.last).to be_failed
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new transaction' do
        expect do
          post account_transactions_path(account), params: { transaction: invalid_attributes }
        end.not_to change(Transaction, :count)
      end

      it 'renders the new template with unprocessable entity status' do
        post account_transactions_path(account), params: { transaction: invalid_attributes }
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /cancel' do
    let!(:transaction) { create(:transaction, sender: account, recipient: recipient_account, status: :pending) }

    context 'when the transaction is successfully cancelled' do
      it 'marks the transaction as cancelled' do
        patch cancel_account_transaction_path(account, transaction)
        expect(transaction.reload).to be_canceled
      end

      it 'calls the cancel! method on the transaction' do
        expect_any_instance_of(Transaction).to receive(:cancel!)

        patch cancel_account_transaction_path(account, transaction)
      end

      it 'redirects to the account page with a success notice' do
        patch cancel_account_transaction_path(account, transaction)
        expect(response).to redirect_to(account_path(account))
        expect(flash[:notice]).to eq('Transaction was successfully cancelled.')
      end
    end

    context 'when responding with turbo stream' do
      it 'returns a turbo stream response' do
        patch cancel_account_transaction_path(account, transaction),
              headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
