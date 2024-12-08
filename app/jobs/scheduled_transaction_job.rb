# frozen_string_literal: true

class ScheduledTransactionJob < ApplicationJob
  queue_as :default

  def perform(transaction_id)
    transaction = Transaction.find(transaction_id)

    return if transaction.canceled?

    if transaction.complete!
      TransactionNotifier.new(transaction).call
    else
      transaction.fail!
    end
  end
end
