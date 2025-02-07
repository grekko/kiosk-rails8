module ApplicationHelper
  def formatted_price(price_in_cents)
    price = (price_in_cents / 100.to_f)
    number_to_currency(price, unit: "EUR", separator: ",", delimiter: "")
  end

  def formatted_date(date)
    return unless date

    date.to_date.iso8601
  end

  def payment_message(payment)
    details_by_drink = {}

    payment.settlements.flat_map(&:positions).flat_map do |position|
      details_by_drink[position.drink.name] ||= { price_in_cents: position.drink_price_in_cents, amount: 0 }
      details_by_drink[position.drink.name][:amount] += position.amount
    end
    drinks_lines = details_by_drink.map do |(name, details)|
      "- #{details[:amount]} x #{name} (#{formatted_price(details[:price_in_cents])})"
    end

    <<~MESSAGE
        Hallo #{payment.client.name},

        auf deinem Comuna-Bierdeckel stehen aktuell: #{formatted_price(payment.amount_in_cents)}.

        #{drinks_lines.join("\n")}

        Du kannst die Rechnung gerne per PayPal oder SEPA begleichen:
        https://paypal.me/gregoryigelmund/#{(payment.amount_in_cents/100.to_f).round(2)}

        DE91500105175411307099
    MESSAGE
  end
end
