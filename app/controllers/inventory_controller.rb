class InventoryController < ApplicationController
  def show
    @ordered_drink_count = OrderPosition.group(:drink_id).sum(:amount)
    @settled_drink_count = SettlementPosition.group(:drink_id).sum(:amount)
    @drinks = Drink.all
  end
end
