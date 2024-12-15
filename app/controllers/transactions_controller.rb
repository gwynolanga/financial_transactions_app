# frozen_string_literal: true

# app/controllers/transactions_controller.rb
class TransactionsController < ApplicationController
  def show
    @page = calculate_page_by(transaction)
  end

  def new
    @transaction = build_transaction
  end

  def create
    @transaction = build_transaction

    if @transaction.save
      @transaction.scheduled? ? @transaction.defer! : @transaction.complete! || @transaction.fail!
      redirect_to(account_path(account), Transactions::Notifier.call(@transaction))
    else
      render(:new, status: :unprocessable_entity, locals: { account: account, transaction: @transaction })
    end
  end

  def cancel
    transaction.cancel!

    respond_to do |format|
      format.html { redirect_to(account_path(account), notice: 'Transaction was successfully cancelled.') }
      format.turbo_stream
    end
  end

  private

  def calculate_page_by(transaction)
    index = account.transactions.order(created_at: :desc).index(transaction)
    (index / Pagy::DEFAULT[:limit]) + 1
  end

  def build_transaction
    case transaction_kind
    when 'deposit' then account.build_transaction(deposit_params, type: :incoming)
    when 'withdrawal' then account.build_transaction(withdrawal_params, type: :outgoing)
    else account.build_transaction(transaction_params, type: :outgoing)
    end
  end

  def account
    @account ||= current_user.accounts.find(account_id)
  end

  def transaction
    @transaction ||= account.transactions.find(transaction_id)
  end

  def account_id
    params[:account_id]
  end

  def transaction_id
    params[:id]
  end

  def transaction_kind
    transaction_params[:kind]
  end

  def transaction_params
    params.fetch(:transaction, {}).permit(:sender_amount, :recipient_amount, :kind, :execution_date, :recipient_id)
  end

  def deposit_params
    transaction_params.slice(:recipient_amount, :kind)
  end

  def withdrawal_params
    transaction_params.slice(:sender_amount, :kind)
  end
end
