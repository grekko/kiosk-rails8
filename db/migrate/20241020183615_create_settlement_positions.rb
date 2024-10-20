class CreateSettlementPositions < ActiveRecord::Migration[8.0]
  def change
    create_table :settlement_positions do |t|
      t.belongs_to(:settlement, foreign_key: true, null: false)
      t.belongs_to(:drink, foreign_key: true, null: false)

      t.integer :amount, null: false, default: 1
      t.integer :price_in_cents, null: false, default: 0

      t.timestamps
    end
  end
end
