# frozen_string_literal: true

# app/services/transactions/message_builder.rb
module Transactions
  class MessageBuilder
    attr_reader :transaction

    def initialize(transaction)
      @transaction = transaction
    end

    # Assumes transaction is in a valid state for building the message
    def sender_message
      successful_messages_by_kind[:sender]
    end

    # Assumes transaction is in a valid state for building the message
    def recipient_message
      successful_messages_by_kind[:recipient]
    end

    # Assumes transaction is in a valid state for building the message
    def failed_sender_message
      failed_messages_by_kind[:sender]
    end

    private

    def successful_messages_by_kind
      case transaction_kind
      when :deposit then { sender: '', recipient: deposit_message }
      when :withdrawal then { sender: withdrawal_message, recipient: '' }
      when :immediate then { sender: transfer_message_from_sender, recipient: transfer_message_to_recipient }
      else { sender: scheduled_transfer_message_from_sender, recipient: transfer_message_to_recipient }
      end
    end

    def failed_messages_by_kind
      case transaction_kind
      when :deposit then { sender: '', recipient: '' }
      else { sender: failed_transfer_message_from_sender, recipient: '' }
      end
    end

    def transaction_kind
      transaction.kind.to_sym
    end

    def scheduled_transfer_message_from_sender
      sender_amount = transaction.sender_amount
      sender_currency_name = transaction.sender_currency_name
      recipient_account_number = transaction.recipient.human_number
      execution_date = transaction.execution_date

      <<~MESSAGE.strip.gsub(/\s+/, ' ')
        Transfer is scheduled. The amount of #{sender_amount} #{sender_currency_name} will be debited from your#{' '}
        account number: #{recipient_account_number}. Execution date: #{execution_date}.
      MESSAGE
    end

    def transfer_message_from_sender
      sender_amount = transaction.sender_amount
      sender_currency_name = transaction.sender_currency_name
      sender_account_balance = transaction.sender.balance
      recipient_account_number = transaction.recipient.human_number

      <<~MESSAGE.strip.gsub(/\s+/, ' ')
        Transfer is successful. You have sent #{sender_amount} #{sender_currency_name} to account number:#{' '}
        #{recipient_account_number}. You now have #{sender_account_balance} #{sender_currency_name} remaining.
      MESSAGE
    end

    def transfer_message_to_recipient
      sender_user_full_name = transaction.sender_user_full_name
      recipient_amount = transaction.recipient_amount
      recipient_currency_name = transaction.recipient_currency_name
      recipient_account_balance = transaction.recipient.balance
      recipient_account_number = transaction.recipient.human_number

      <<~MESSAGE.strip.gsub(/\s+/, ' ')
        Payment is successful. #{sender_user_full_name} has sent you #{recipient_amount} #{recipient_currency_name}#{' '}
        to your account number: #{recipient_account_number}. You now have #{recipient_account_balance}#{' '}
        #{recipient_currency_name} available.
      MESSAGE
    end

    def deposit_message
      recipient_amount = transaction.recipient_amount
      recipient_currency_name = transaction.recipient_currency_name
      recipient_account_number = transaction.recipient.human_number
      recipient_account_balance = transaction.recipient.balance

      <<~MESSAGE.strip.gsub(/\s+/, ' ')
        Deposit is successful. #{recipient_amount} #{recipient_currency_name} has been deposited into your account:#{' '}
        #{recipient_account_number}. You now have #{recipient_account_balance} #{recipient_currency_name} available.
      MESSAGE
    end

    def withdrawal_message
      sender_amount = transaction.sender_amount
      sender_currency_name = transaction.sender_currency_name
      sender_account_number = transaction.sender.human_number
      sender_account_balance = transaction.sender.balance

      <<~MESSAGE.strip.gsub(/\s+/, ' ')
        Withdrawal is successful. #{sender_amount} #{sender_currency_name} has been withdrawn from your account:#{' '}
        #{sender_account_number}. You now have #{sender_account_balance} #{sender_currency_name} remaining.
      MESSAGE
    end

    def failed_transfer_message_from_sender
      sender_account_number = transaction.sender.human_number
      sender_amount = transaction.sender_amount
      sender_account_balance = transaction.sender.balance

      <<~MESSAGE.strip.gsub(/\s+/, ' ')
        Transaction with id=#{transaction.id} is failed. Insufficient funds in your account: #{sender_account_number}.
        Sender amount > Sender balance: #{sender_amount} > #{sender_account_balance}.
      MESSAGE
    end
  end
end
