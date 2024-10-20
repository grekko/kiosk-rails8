class CreateSettlementPrices < ActiveRecord::Migration[8.0]
  def change
    create_table :settlement_prices do |t|
      t.belongs_to(:drink, foreign_key: true, null: false)
      t.date :valid_from, null: false
      t.integer :price_in_cents, null: false, default: 0

      t.timestamps
    end
  end
end
