class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts do |t|
      t.string :number, null: false
      t.decimal :balance, precision: 10, scale: 2, null: false, default: 0
      t.references :currency, null: false, foreign_key: true
      t.references :holder, null: false, foreign_key: true

      t.timestamps
    end

    add_index :accounts, :number, unique: true
  end
end
