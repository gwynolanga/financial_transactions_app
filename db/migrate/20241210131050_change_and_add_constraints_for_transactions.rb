# frozen_string_literal: true

class ChangeAndAddConstraintsForTransactions < ActiveRecord::Migration[7.1]
  def change
    change_table :transactions, bulk: true do |t|
      t.change_default :sender_amount, from: nil, to: '0.0'
      t.change_default :recipient_amount, from: nil, to: '0.0'

      t.change_null :sender_id, null: true
      t.change_null :recipient_id, null: true

      t.remove_check_constraint 'sender_amount > 0', name: 'chk_transactions_sender_amount_positive'
      t.check_constraint 'sender_amount >= 0', name: 'chk_transactions_sender_amount_positive_or_zero'

      t.remove_check_constraint 'recipient_amount > 0', name: 'chk_transactions_recipient_amount_positive'
      t.check_constraint 'recipient_amount >= 0', name: 'chk_transactions_recipient_amount_positive_or_zero'

      t.remove_check_constraint 'sender_id != recipient_id', name: 'chk_transactions_sender_recipient_different'
      t.check_constraint 'sender_id != recipient_id AND (sender_id IS NOT NULL OR recipient_id IS NOT NULL)',
                         name: 'chk_transactions_sender_and_recipient_must_be_different'

      t.remove_check_constraint 'kind IN (0, 1)', name: 'chk_transactions_kind_valid_range'
    end

    add_check_constraint :transactions, 'kind IN (0, 1, 2, 3)', name: 'chk_transactions_kind_valid_range'

    chk_immediate_expression = '(kind = 0 AND sender_amount > 0 AND recipient_id IS NOT NULL) OR kind != 0'
    chk_immediate_name = 'chk_transactions_immediate_kind_transaction'
    add_check_constraint :transactions, chk_immediate_expression, name: chk_immediate_name

    chk_scheduled_expression = '(kind = 1 AND sender_amount > 0 AND execution_date IS NOT NULL AND recipient_id IS NOT NULL) OR kind != 1'
    chk_scheduled_name = 'chk_transactions_scheduled_kind_transaction'
    add_check_constraint :transactions, chk_scheduled_expression, name: chk_scheduled_name

    chk_deposit_expression = '(kind = 2 AND sender_id IS NULL AND sender_amount = 0 AND recipient_amount > 0) OR kind != 2'
    chk_deposit_name = 'chk_transactions_deposit_kind_transaction'
    add_check_constraint :transactions, chk_deposit_expression, name: chk_deposit_name

    chk_withdrawal_expression = '(kind = 3 AND recipient_id IS NULL AND recipient_amount = 0 AND sender_amount > 0) OR kind != 3'
    chk_withdrawal_name  = 'chk_transactions_withdrawal_kind_transaction'
    add_check_constraint :transactions, chk_withdrawal_expression, name: chk_withdrawal_name
  end
end
