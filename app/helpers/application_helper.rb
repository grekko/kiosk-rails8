module ApplicationHelper
  def formatted_price(price_in_cents)
    price = (price_in_cents / 100.to_f)
    number_to_currency(price, unit: "EUR", separator: ",", delimiter: "")
  end

  def formatted_date(date)
    return unless date

    date.to_date.iso8601
  end
end
