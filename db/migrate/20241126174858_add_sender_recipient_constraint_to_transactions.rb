# frozen_string_literal: true

class AddSenderRecipientConstraintToTransactions < ActiveRecord::Migration[7.1]
  def change
    add_check_constraint :transactions, 'sender_id != recipient_id',
                         name: 'chk_transactions_sender_recipient_different'
  end
end
