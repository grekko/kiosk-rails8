module ApplicationHelper
  def formatted_price(price_in_cents)
    price = (price_in_cents / 100.to_f)
    number_to_currency(price, unit: "EUR", separator: ",", delimiter: "")
  end
end
