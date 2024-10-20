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

ActiveRecord::Schema[8.0].define(version: 2024_10_20_183615) do
  create_table "clients", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "drinks", force: :cascade do |t|
    t.string "name", null: false
    t.integer "price_in_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

# Could not dump table "order_positions" because of following StandardError
#   Unknown type '' for column 'total_price_in_cents'


  create_table "orders", force: :cascade do |t|
    t.date "ordered_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "settlement_positions", force: :cascade do |t|
    t.integer "settlement_id", null: false
    t.integer "drink_id", null: false
    t.integer "amount", default: 1, null: false
    t.integer "price_in_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["drink_id"], name: "index_settlement_positions_on_drink_id"
    t.index ["settlement_id"], name: "index_settlement_positions_on_settlement_id"
  end

  create_table "settlements", force: :cascade do |t|
    t.integer "client_id", null: false
    t.date "generated_at", null: false
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_settlements_on_client_id"
  end

  add_foreign_key "order_positions", "drinks"
  add_foreign_key "order_positions", "orders"
  add_foreign_key "settlement_positions", "drinks"
  add_foreign_key "settlement_positions", "settlements"
  add_foreign_key "settlements", "clients"
end
