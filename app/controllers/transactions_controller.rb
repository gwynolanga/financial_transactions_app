# frozen_string_literal: true

class TransactionsController < ApplicationController
  def show
    @transaction = account.transactions.find(transaction_id)
  end

  def new
    @transaction = account.build_transaction(type: :outgoing)
  end

  def create
    @transaction = current_user.accounts.find(account_id).build_transaction(transaction_params, type: :outgoing)

    if @transaction.save
      handle_transaction_status
      redirect_to(account_path(account), notice: 'Transaction was successfully created.')
    else
      render(:new, status: :unprocessable_entity, locals: { account: account, transaction: @transaction })
    end
  end

  private

  def handle_transaction_status
    if @transaction.scheduled?
      @transaction.defer!
    else
      @transaction.fail! unless @transaction.complete!
    end
  end

  def account
    @account ||= current_user.accounts.find(account_id)
  end

  def account_id
    params[:account_id]
  end

  def transaction_id
    params[:id]
  end

  def transaction_params
    params.require(:transaction).permit(:sender_amount, :kind, :execution_date, :recipient_id)
  end
end
