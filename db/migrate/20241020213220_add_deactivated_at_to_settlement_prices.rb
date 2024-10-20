class AddDeactivatedAtToSettlementPrices < ActiveRecord::Migration[8.0]
  def change
    add_column :settlement_prices, :deactivated_at, :datetime
  end
end
