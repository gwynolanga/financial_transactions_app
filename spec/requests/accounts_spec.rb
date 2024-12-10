# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Accounts', type: :request do
  let(:user) { create(:user) }
  let(:currency) { create(:currency) }
  let(:recipient_currency) { create(:currency) }
  let(:account) { create(:account, user: user, currency: currency) }
  let(:recipient_account) { create(:account, currency: recipient_currency) }
  let(:valid_attributes) { { currency_id: currency.id } }
  let(:invalid_attributes) { { currency_id: nil } }

  before do
    sign_in user
    create(:exchange_rate, base_currency: currency, target_currency: recipient_currency, value: 1.5)
  end

  describe 'GET /index' do
    it 'returns the list of accounts for the current user' do
      account
      get accounts_path
      expect(response).to be_successful
      expect(assigns(:accounts)).to eq([account])
    end

    it 'renders the index template' do
      get accounts_path
      expect(response).to render_template(:index)
    end
  end

  describe 'GET /show' do
    let!(:transaction1) { create(:transaction, sender: account, recipient: recipient_account, created_at: 1.day.ago) }
    let!(:transaction2) { create(:transaction, sender: account, recipient: recipient_account, created_at: 2.days.ago) }

    it 'returns the transactions ordered by created_at descending' do
      get account_path(account)
      expect(response).to be_successful
      expect(assigns(:transactions)).to eq([transaction1, transaction2])
    end

    it 'renders the show template in HTML format' do
      get account_path(account)
      expect(response).to render_template(:show)
    end
  end

  describe 'GET /new' do
    it 'assigns a new account to @account' do
      get new_account_path
      expect(response).to be_successful
      expect(assigns(:account)).to be_a_new(Account)
    end

    it 'renders the new template' do
      get new_account_path
      expect(response).to render_template(:new)
    end
  end

  describe 'POST /create' do
    context 'with valid parameters' do
      it 'creates a new account' do
        expect do
          post accounts_path, params: { account: valid_attributes }
        end.to change(Account, :count).by(1)
      end

      it 'redirects to the created account' do
        post accounts_path, params: { account: valid_attributes }
        expect(response).to redirect_to(account_path(Account.last))
        expect(flash[:notice]).to eq('Account was successfully created.')
      end

      it 'responds with turbo_stream format when requested' do
        post accounts_path, params: { account: valid_attributes }, as: :turbo_stream
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new account' do
        expect do
          post accounts_path, params: { account: invalid_attributes }
        end.not_to change(Account, :count)
      end

      it 'renders the new template with unprocessable entity status' do
        post accounts_path, params: { account: invalid_attributes }
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
