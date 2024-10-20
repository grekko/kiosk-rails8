class CreateOrderPositions < ActiveRecord::Migration[8.0]
  def change
    create_table :order_positions do |t|
      t.belongs_to(:order, foreign_key: true, null: false)
      t.belongs_to(:drink, foreign_key: true, null: false)

      t.integer :amount, null: false, default: 0
      t.integer :price_in_cents, null: false, default: 0
      t.integer :deposit_in_cents, null: false, default: 0

      t.timestamps
    end
  end
end
