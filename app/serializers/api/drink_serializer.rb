class Api::DrinkSerializer
  def self.call(drink)
    {
      id: drink.id,
      name: drink.name,
      price_in_cents: drink.price_in_cents,
      current_settlement_price_in_cents: drink.current_price_in_cents
    }
  end
end
