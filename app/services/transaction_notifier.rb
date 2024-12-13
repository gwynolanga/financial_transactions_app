# frozen_string_literal: true

class TransactionNotifier
  attr_reader :transaction

  def initialize(transaction)
    @transaction = transaction
  end

  def call
    transaction.failed? ? notify_failed_transaction : notify_successful_transaction
  end

  private

  def notify_failed_transaction
    if transaction.defered?
      send_message({ alert: failed_message }, sender_user)
    else
      { alert: failed_message }
    end
  end

  def notify_successful_transaction
    if transaction.deposit?
      { notice: recipient_message }
    elsif transaction.withdrawal?
      { notice: sender_message }
    else
      send_message({ warning: sender_message }, sender_user) if transaction.scheduled?
      send_message({ warning: recipient_message }, recipient_user)
      { notice: sender_message }
    end
  end

  def transaction_kind_messages
    case transaction_kind
    when :deposit then { sender: '', recipient: deposit_message }
    when :withdrawal then { sender: withdrawal_message, recipient: '' }
    when :immediate then { sender: transfer_message_from_sender, recipient: transfer_message_to_recipient }
    else { sender: scheduled_transfer_message_from_sender, recipient: transfer_message_to_recipient }
    end
  end

  def transaction_kind
    transaction.kind.to_sym
  end

  def sender_user
    transaction.sender.user
  end

  def sender_message
    transaction_kind_messages[:sender]
  end

  def recipient_user
    transaction.recipient.user
  end

  def recipient_message
    transaction_kind_messages[:recipient]
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
      Transfer is successful. You has sent #{sender_amount} #{sender_currency_name} to account number:#{' '}
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

  def failed_message
    sender_account_number = transaction.sender.human_number
    sender_amount = transaction.sender_amount
    sender_account_balance = transaction.sender.balance

    <<~MESSAGE.strip.gsub(/\s+/, ' ')
      Transaction with id=#{transaction.id} is failed. Insufficient funds in your account: #{sender_account_number}.
      Sender amount > Sender balance: #{sender_amount} > #{sender_account_balance}.
    MESSAGE
  end

  def send_message(flash_message, recipient)
    Turbo::StreamsChannel.broadcast_render_later_to(
      [recipient, 'flash_messages'],
      partial: 'layouts/shared/flash',
      locals: { flash: flash_message, transaction: transaction } # put transaction for refreshing transactions table
    )
  end
end
