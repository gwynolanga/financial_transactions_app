# frozen_string_literal: true

# app/services/transactions/processor.rb
module Transactions
  class Processor < BaseService
    attr_reader :transaction

    def initialize(transaction)
      super()
      @transaction = transaction
    end

    def call
      # From AASM for Transaction model, transition to completed status
      return unless transaction.pending? || transaction.deferred?

      ActiveRecord::Base.transaction do
        case transaction.kind
        when 'deposit' then process_deposit
        when 'withdrawal' then process_withdrawal
        else process_transfer
        end
      end
    end

    private

    def process_deposit
      transaction.recipient.with_lock do
        transaction.recipient.update!(balance: transaction.recipient.balance + transaction.recipient_amount)
      end
    end

    def process_withdrawal
      transaction.sender.with_lock do
        transaction.sender.update!(balance: transaction.sender.balance - transaction.sender_amount)
      end
    end

    def process_transfer
      with_locked_sender_and_recipient do
        update_sender_balance
        update_recipient_balance
      end
    end

    def with_locked_sender_and_recipient(&block)
      transaction.sender.with_lock do
        transaction.recipient.with_lock(&block)
      end
    end

    def update_sender_balance
      transaction.sender.update!(balance: transaction.sender.balance - transaction.sender_amount)
    end

    def update_recipient_balance
      transaction.recipient.update!(balance: transaction.recipient.balance + transaction.recipient_amount)
    end
  end
end
