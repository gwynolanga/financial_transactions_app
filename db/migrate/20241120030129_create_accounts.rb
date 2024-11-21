# frozen_string_literal: true

class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts do |t|
      t.string :number, null: false
      t.decimal :balance, precision: 10, scale: 16, null: false, default: 0
      t.references :currency, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps

      t.index :number, unique: true
      t.index %i[user_id currency_id], unique: true
      t.check_constraint 'char_length(number) = 16', name: 'chk_accounts_number_equality'
      t.check_constraint 'balance >= 0', name: 'chk_accounts_balance_positive_or_zero'
    end
  end
end
