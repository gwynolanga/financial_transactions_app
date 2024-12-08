# frozen_string_literal: true

class TransactionNotifier
  def initialize(transaction)
    @transaction = transaction
  end

  def call
    message = build_message
    send_message(message)
  end

  private

  def build_message
    sender_user_full_name = @transaction.sender_user_full_name
    sender_amount = @transaction.sender_amount
    sender_currency_name = @transaction.sender_currency_name
    recipient_account_number = @transaction.recipient.human_number
    recipient_account_balance = @transaction.recipient.balance
    recipient_currency_name = @transaction.recipient_currency_name

    <<~MESSAGE.strip.gsub(/\s+/, ' ')
      #{sender_user_full_name} has sent #{sender_amount} #{sender_currency_name} to account number:#{' '}
      #{recipient_account_number}. Total account balance: #{recipient_account_balance} #{recipient_currency_name}
    MESSAGE
  end

  def send_message(message)
    Turbo::StreamsChannel.broadcast_render_later_to(
      [@transaction.recipient.user, 'flash_messages'],
      partial: 'layouts/shared/flash',
      locals: { flash: { warning: message } }
    )
  end
end
