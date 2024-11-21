# frozen_string_literal: true

class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions do |t|
      t.decimal :amount, precision: 10, scale: 16, null: false
      t.integer :kind, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.datetime :execution_date
      t.references :currency, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :accounts }
      t.references :recipient, null: false, foreign_key: { to_table: :accounts }

      t.timestamps

      t.check_constraint 'amount > 0', name: 'chk_transactions_amount_positive'
      t.check_constraint 'kind IN (0, 1)', name: 'chk_transactions_kind_valid_range'
      t.check_constraint 'status IN (0, 1, 2, 3)', name: 'chk_transactions_status_valid_range'
    end
  end
end
