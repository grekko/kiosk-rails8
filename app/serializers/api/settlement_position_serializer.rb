class Api::SettlementPositionSerializer
  def self.call(position)
    {
      id: position.id,
      settlement_id: position.settlement_id,
      drink_id: position.drink_id,
      drink_name: position.drink.name,
      amount: position.amount,
      price_in_cents: position.price_in_cents
    }
  end
end
