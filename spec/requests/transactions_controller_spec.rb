# frozen_string_literal: true

# spec/requests/transactions_spec.rb
require 'rails_helper'

RSpec.describe TransactionsController, type: :request do
  let(:user) { create(:user) }
  let(:currency) { create(:currency) }
  let(:sender) { create(:account, user: user, currency: currency) }
  let(:recipient) { create(:account, currency: currency) }

  before { sign_in(user) }

  describe 'GET /show' do
    let(:transaction) { create(:transaction, sender: sender, recipient: recipient) }

    it 'returns a successful response' do
      get account_transaction_path(sender, transaction)
      expect(response).to have_http_status(:ok)
      expect(assigns(:transaction)).to eq(transaction)
      expect(assigns(:page)).to eq(1)
    end

    it 'renders the show template' do
      get account_transaction_path(sender, transaction)
      expect(response).to render_template(:show)
    end
  end

  describe 'GET /new' do
    it 'returns a successful response' do
      get new_account_transaction_path(sender)
      expect(response).to have_http_status(:ok)
      expect(assigns(:transaction)).to be_a_new(Transaction)
    end

    it 'renders the new template' do
      get new_account_transaction_path(sender)
      expect(response).to render_template(:new)
    end
  end

  describe 'POST /create' do
    context 'when creating a new immediate transaction' do
      context 'with valid params' do
        let(:params) do
          { transaction: { kind: :immediate, sender_amount: 100, recipient_id: recipient.id } }
        end

        it 'creates a new transaction and redirects to the account page' do
          expect { post account_transactions_path(sender), params: params }.to change(Transaction, :count).by(1)
          expect(response).to redirect_to(account_path(sender))
          expect(flash[:notice]).to eq(Transactions::MessageBuilder.new(Transaction.last).sender_message)
        end
      end

      context 'with invalid params' do
        it 'does not create a new transaction with invalid sender_amount' do
          params = { transaction: { kind: :immediate, sender_amount: nil, recipient_id: recipient.id } }
          expect { post account_transactions_path(sender), params: params }.not_to change(Transaction, :count)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:new)
        end

        it 'does not create a new transaction with invalid recipient_id' do
          params = { transaction: { kind: :immediate, sender_amount: 100, recipient_id: nil } }
          expect { post account_transactions_path(sender), params: params }.not_to change(Transaction, :count)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:new)
        end
      end
    end

    context 'when creating a new scheduled transaction' do
      context 'with valid params' do
        let(:params) do
          {
            transaction: {
              kind: :scheduled,
              sender_amount: 100,
              execution_date: 1.day.from_now,
              recipient_id: recipient.id
            }
          }
        end

        it 'creates a new transaction and redirects to the account page' do
          expect { post account_transactions_path(sender), params: params }.to change(Transaction, :count).by(1)
          expect(response).to redirect_to(account_path(sender))
          expect(flash[:notice]).to eq(Transactions::MessageBuilder.new(Transaction.last).sender_message)
        end
      end

      context 'with invalid params' do
        it 'does not create a new transaction with invalid sender_amount' do
          params = {
            transaction: {
              kind: :scheduled,
              sender_amount: nil,
              execution_date: 1.day.from_now,
              recipient_id: recipient.id
            }
          }

          expect { post account_transactions_path(sender), params: params }.not_to change(Transaction, :count)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:new)
        end

        it 'does not create a new transaction with invalid execution_date' do
          params = {
            transaction: {
              kind: :scheduled,
              sender_amount: 100,
              execution_date: nil,
              recipient_id: nil
            }
          }

          expect { post account_transactions_path(sender), params: params }.not_to change(Transaction, :count)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:new)
        end

        it 'does not create a new transaction with invalid recipient_id' do
          params = {
            transaction: {
              kind: :scheduled,
              sender_amount: 100,
              execution_date: 1.day.from_now,
              recipient_id: nil
            }
          }

          expect { post account_transactions_path(sender), params: params }.not_to change(Transaction, :count)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:new)
        end
      end
    end

    context 'when creating a new deposit transaction' do
      context 'with valid params' do
        let(:params) do
          { transaction: { kind: :deposit, recipient_amount: 100 } }
        end

        it 'creates a new transaction and redirects to the account page' do
          expect { post account_transactions_path(sender), params: params }.to change(Transaction, :count).by(1)
          expect(response).to redirect_to(account_path(sender))
          expect(flash[:notice]).to eq(Transactions::MessageBuilder.new(Transaction.last).recipient_message)
        end
      end

      context 'with invalid params' do
        it 'does not create a new transaction with invalid recipient_amount' do
          params = { transaction: { kind: :deposit, recipient_amount: nil } }
          expect { post account_transactions_path(sender), params: params }.not_to change(Transaction, :count)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:new)
        end
      end
    end

    context 'when creating a new withdrawal transaction' do
      context 'with valid params' do
        let(:params) do
          { transaction: { kind: :withdrawal, sender_amount: 100 } }
        end

        it 'creates a new transaction and redirects to the account page' do
          expect { post account_transactions_path(sender), params: params }.to change(Transaction, :count).by(1)
          expect(response).to redirect_to(account_path(sender))
          expect(flash[:notice]).to eq(Transactions::MessageBuilder.new(Transaction.last).sender_message)
        end
      end

      context 'with invalid params' do
        it 'does not create a new transaction with invalid sender_amount' do
          params = { transaction: { kind: :withdrawal, sender_amount: nil } }
          expect { post account_transactions_path(sender), params: params }.not_to change(Transaction, :count)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:new)
        end
      end
    end
  end

  describe 'PATCH /cancel' do
    let(:transaction) { create(:transaction, :scheduled, sender: sender, recipient: recipient) }

    it 'cancels the transaction' do
      patch cancel_account_transaction_path(sender, transaction)
      expect(transaction.reload).to be_canceled
    end

    it 'redirects to the account' do
      patch cancel_account_transaction_path(sender, transaction)
      expect(response).to redirect_to(account_path(sender))
      expect(flash[:notice]).to eq('Transaction was successfully cancelled.')
    end

    it 'responds with turbo stream if format is turbo_stream' do
      patch cancel_account_transaction_path(sender, transaction, format: :turbo_stream)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(transaction.reload).to be_canceled
    end
  end
end
