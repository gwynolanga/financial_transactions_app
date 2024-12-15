# frozen_string_literal: true

# app/services/transactions/notifier.rb
module Transactions
  class Notifier < BaseService
    attr_reader :transaction, :message_builder

    def initialize(transaction)
      super()
      @transaction = transaction
      @message_builder = MessageBuilder.new(transaction)
    end

    def call
      if transaction.deferred? || transaction.completed?
        notify_successful_transaction
      elsif transaction.failed?
        notify_failed_transaction
      end
    end

    private

    def notify_failed_transaction
      if transaction.scheduled?
        send_message({ alert: message_builder.failed_sender_message }, sender_user)
      else
        { alert: message_builder.failed_sender_message }
      end
    end

    def notify_successful_transaction
      if transaction.deposit?
        { notice: message_builder.recipient_message }
      elsif transaction.withdrawal?
        { notice: message_builder.sender_message }
      else
        handle_immediate_or_scheduled_transaction
      end
    end

    def handle_immediate_or_scheduled_transaction
      if transaction.scheduled?
        send_message({ warning: message_builder.sender_message }, sender_user)
        send_message({ warning: message_builder.recipient_message }, recipient_user)
      end
      { notice: message_builder.sender_message }
    end

    def sender_user
      transaction.sender.user
    end

    def recipient_user
      transaction.recipient.user
    end

    def send_message(message, recipient)
      MessageSender.send_message(message, recipient, transaction)
    end
  end
end
