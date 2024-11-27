# frozen_string_literal: true

class ScheduledTransactionJob < ApplicationJob
  queue_as :default

  def perform(transaction_id)
    transaction = Transaction.find(transaction_id)
    if transaction.complete!
      FlashMessageSender.new(transaction).call
    else
      transaction.fail!
    end
  end
end
