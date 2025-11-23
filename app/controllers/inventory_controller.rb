class InventoryController < ApplicationController
  def show
    @drink_inventory_rows = DrinkInventory.all_rows
    @ordered_in_cents = OrderPosition.sum(:price_in_cents)
    @settled_in_cents = SettlementPosition.joins(:settlement).where(settlements: { aasm_state: :paid }).sum(:price_in_cents)
    @unsettled_in_cents = SettlementPosition.joins(:settlement).where(settlements: { aasm_state: :completed }).sum(:price_in_cents)
  end
end
