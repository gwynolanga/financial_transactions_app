# frozen_string_literal: true

# app/services/transactions/message_sender.rb
module Transactions
  class MessageSender
    # put transaction for refreshing transactions table or transaction modal window
    # Assumes transaction is in a valid state for sending messages
    def self.send_message(message, recipient, transaction)
      Turbo::StreamsChannel.broadcast_render_later_to(
        [recipient, 'flash_messages'],
        partial: 'layouts/shared/flash',
        locals: { flash: message, transaction: transaction }
      )
    end
  end
end
