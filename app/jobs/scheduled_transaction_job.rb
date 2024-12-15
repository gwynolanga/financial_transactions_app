# frozen_string_literal: true

# app/jobs/scheduled_transaction_job.rb
class ScheduledTransactionJob < ApplicationJob
  queue_as :default

  def perform(transaction_id)
    transaction = Transaction.find(transaction_id)

    return if transaction.canceled?

    transaction.complete! || transaction.fail!
    Transactions::Notifier.call(transaction)
  end
end
