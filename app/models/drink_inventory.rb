class DrinkInventory
  def self.all_rows = new.call

  def initialize
    @drinks = Drink.all
    @ordered_counts_by_drink_id = OrderPosition.group(:drink_id).sum(:amount)
    @settled_counts_by_drink_id = SettlementPosition.group(:drink_id).sum(:amount)
  end

  def call
    @drinks.map do |drink|
      ordered_count = @ordered_counts_by_drink_id.fetch(drink.id, 0)
      settled_count = @settled_counts_by_drink_id.fetch(drink.id, 0)
      remaining_count = ordered_count - settled_count

      DrinkInventory::Row.new(
        id: drink.id,
        name: drink.name,
        ordered_count:,
        settled_count:,
        remaining_count:,
        purchase_price: drink.price_in_cents * remaining_count,
        selling_price: drink.current_price_in_cents * remaining_count,
      )
    end
  end
end
