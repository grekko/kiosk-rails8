class AddTotalPriceInCentsToOrderPositions < ActiveRecord::Migration[8.0]
  def change
    add_column :order_positions, :total_price_in_cents, :virtual, as: "price_in_cents + deposit_in_cents", stored: false
  end
end
