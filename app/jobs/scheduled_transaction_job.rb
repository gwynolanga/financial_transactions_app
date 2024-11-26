# frozen_string_literal: true

class ScheduledTransactionJob < ApplicationJob
  queue_as :default

  def perform(transaction_id)
    transaction = Transaction.find(transaction_id)
    transaction.fail! unless transaction.complete!
  end
end
