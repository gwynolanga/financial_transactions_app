# frozen_string_literal: true

class CreateExchangeRates < ActiveRecord::Migration[7.1]
  def change
    create_table :exchange_rates do |t|
      t.decimal :amount, precision: 2, scale: 2, null: false
      t.references :base_currency, null: false, foreign_key: true
      t.references :target_currency, null: false, foreign_key: true

      t.timestamps

      t.index '(LEAST(base_currency_id, target_currency_id), GREATEST(base_currency_id, target_currency_id))',
              unique: true, name: 'index_exchange_rates_on_normalized_pair'
      t.check_constraint 'amount > 0', name: 'amount_check'
    end
  end
end
