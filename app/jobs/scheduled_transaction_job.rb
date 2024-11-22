# frozen_string_literal: true

class ScheduledTransactionJob < ApplicationJob
  queue_as :default

  def perform(transaction_id)
    Transaction.find(transaction_id).complete!
  end
end
