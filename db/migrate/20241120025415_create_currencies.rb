class CreateCurrencies < ActiveRecord::Migration[7.1]
  def change
    create_table :currencies do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :currencies, :name, unique: true
  end
end
