# frozen_string_literal: true

class CreateCurrencies < ActiveRecord::Migration[7.1]
  def change
    create_table :currencies do |t|
      t.string :name, null: false

      t.timestamps

      t.index :name, unique: true
    end
  end
end
