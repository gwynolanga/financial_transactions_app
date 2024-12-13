# frozen_string_literal: true

class ScheduledTransactionJob < ApplicationJob
  queue_as :default

  def perform(transaction_id)
    transaction = Transaction.find(transaction_id)

    return if transaction.canceled?

    transaction.complete! || transaction.fail!
    TransactionNotifier.new(transaction).call
  end
end
