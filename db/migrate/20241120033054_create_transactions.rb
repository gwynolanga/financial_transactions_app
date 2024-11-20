class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions do |t|
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :kind, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.datetime :execution_date
      t.references :currency, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: true
      t.references :recipient, null: false, foreign_key: true

      t.timestamps

      t.check_constraint 'amount > 0', name: 'amount_check'
      t.check_constraint 'kind IN (0, 1)', name: 'kind_enum_check'
      t.check_constraint 'status IN (0, 1, 2, 3)', name: 'status_enum_check'
    end
  end
end
