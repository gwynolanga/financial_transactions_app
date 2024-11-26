# frozen_string_literal: true

class AccountsController < ApplicationController
  def index
    @accounts = current_user.accounts
  end

  def show
    @pagy, @transactions = pagy(account.transactions.order(created_at: :desc))
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def new
    @account = current_user.accounts.build
  end

  def create
    @account = current_user.accounts.build(account_params)

    if @account.save
      redirect_to(account_path(@account), notice: 'Account was successfully created.')
    else
      render(:new, status: :unprocessable_entity, locals: { account: @account })
    end
  end

  private

  def account
    @account ||= current_user.accounts.find(params[:id])
  end

  def account_params
    params.require(:account).permit(:balance, :currency_id)
  end
end
