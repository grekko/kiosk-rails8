class InventoryController < ApplicationController
  def show
    @ordered_drink_count = OrderPosition.group(:drink_id).sum(:amount)
    @settled_drink_count = SettlementPosition.group(:drink_id).sum(:amount)
    @drinks = Drink.all

    @ordered_in_cents = OrderPosition.sum(:price_in_cents)
    @settled_in_cents = SettlementPosition.joins(:settlement).where(settlements: { aasm_state: :paid }).sum(:price_in_cents)
    @unsettled_in_cents = SettlementPosition.joins(:settlement).where(settlements: { aasm_state: :completed }).sum(:price_in_cents)
  end
end
