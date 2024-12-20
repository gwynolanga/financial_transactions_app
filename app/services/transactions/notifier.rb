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
        {}
      else
        { alert: message_builder.failed_sender_message }
      end
    end

    def notify_successful_transaction
      case transaction.kind.to_sym
      when :deposit then handle_successful_deposit
      when :withdrawal then handle_successful_withdrawal
      when :immediate then handle_successful_immediate_transaction
      else handle_successful_scheduled_transaction
      end
    end

    def handle_successful_deposit
      { notice: message_builder.recipient_message }
    end

    def handle_successful_withdrawal
      { notice: message_builder.sender_message }
    end

    def handle_successful_immediate_transaction
      if sender_user == recipient_user
        { notice: message_builder.sender_message, warning: message_builder.recipient_message }
      else
        send_message({ warning: message_builder.recipient_message }, recipient_user)
        { notice: message_builder.sender_message }
      end
    end

    def handle_successful_scheduled_transaction
      if transaction.scheduled? && transaction.completed?
        send_message({ warning: message_builder.sender_message }, sender_user)
        send_message({ warning: message_builder.recipient_message }, recipient_user)
        {}
      else
        { notice: message_builder.sender_message }
      end
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
