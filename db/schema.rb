# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_11_26_174858) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "number", null: false
    t.decimal "balance", precision: 16, scale: 6, default: "0.0", null: false
    t.bigint "currency_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_id"], name: "index_accounts_on_currency_id"
    t.index ["number"], name: "index_accounts_on_number", unique: true
    t.index ["user_id", "currency_id"], name: "index_accounts_on_user_id_and_currency_id", unique: true
    t.index ["user_id"], name: "index_accounts_on_user_id"
    t.check_constraint "balance >= 0::numeric", name: "chk_accounts_balance_positive_or_zero"
    t.check_constraint "char_length(number::text) = 16", name: "chk_accounts_number_equality"
  end

  create_table "currencies", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_currencies_on_name", unique: true
  end

  create_table "exchange_rates", force: :cascade do |t|
    t.decimal "value", precision: 16, scale: 6, null: false
    t.bigint "base_currency_id", null: false
    t.bigint "target_currency_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "LEAST(base_currency_id, target_currency_id), GREATEST(base_currency_id, target_currency_id)", name: "index_exchange_rates_on_normalized_pair", unique: true
    t.index ["base_currency_id"], name: "index_exchange_rates_on_base_currency_id"
    t.index ["target_currency_id"], name: "index_exchange_rates_on_target_currency_id"
    t.check_constraint "value > 0::numeric", name: "chk_exchange_rates_value_positive"
  end

  create_table "transactions", force: :cascade do |t|
    t.decimal "sender_amount", precision: 16, scale: 6, null: false
    t.decimal "recipient_amount", precision: 16, scale: 6, null: false
    t.integer "kind", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "execution_date"
    t.bigint "sender_id", null: false
    t.bigint "recipient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipient_id"], name: "index_transactions_on_recipient_id"
    t.index ["sender_id"], name: "index_transactions_on_sender_id"
    t.check_constraint "kind = ANY (ARRAY[0, 1])", name: "chk_transactions_kind_valid_range"
    t.check_constraint "recipient_amount > 0::numeric", name: "chk_transactions_recipient_amount_positive"
    t.check_constraint "sender_amount > 0::numeric", name: "chk_transactions_sender_amount_positive"
    t.check_constraint "sender_id <> recipient_id", name: "chk_transactions_sender_recipient_different"
    t.check_constraint "status = ANY (ARRAY[0, 1, 2, 3, 4])", name: "chk_transactions_status_valid_range"
  end

  create_table "users", force: :cascade do |t|
    t.string "full_name", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.check_constraint "char_length(full_name::text) >= 10 AND char_length(full_name::text) <= 50", name: "chk_users_full_name_valid_range"
  end

  add_foreign_key "accounts", "currencies"
  add_foreign_key "accounts", "users"
  add_foreign_key "exchange_rates", "currencies", column: "base_currency_id"
  add_foreign_key "exchange_rates", "currencies", column: "target_currency_id"
  add_foreign_key "transactions", "accounts", column: "recipient_id"
  add_foreign_key "transactions", "accounts", column: "sender_id"
end
