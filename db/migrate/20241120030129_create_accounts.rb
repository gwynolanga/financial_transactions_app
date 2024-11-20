# frozen_string_literal: true

class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts do |t|
      t.string :number, null: false
      t.decimal :balance, precision: 10, scale: 2, null: false, default: 0
      t.references :currency, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps

      t.index :number, unique: true
      t.index %i[user_id currency_id], unique: true
      t.check_constraint 'char_length(number) = 16', name: 'number_check'
      t.check_constraint 'balance >= 0', name: 'balance_check'
    end
  end
end
