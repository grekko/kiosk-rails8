module ApplicationHelper
  def formatted_price(price_in_cents)
    price = (price_in_cents / 100.to_f)
    number_to_currency(price, unit: "EUR", separator: ",", delimiter: "", format: "%n %u")
  end

  def formatted_date(date)
    return unless date

    date.to_date.iso8601
  end

  def payment_message(payment)
    <<~MESSAGE
      Hallo #{payment.client.name},

      auf deinem Comuna-Bierdeckel stehen aktuell: #{formatted_price(payment.amount_in_cents)}.

      #{payment_drinks_lines(payment).join("\n")}

      #{payment_details(payment)}
    MESSAGE
  end

  def payment_details(payment)
    <<~MESSAGE
      Du kannst die Rechnung gerne per PayPal oder SEPA begleichen:
      #{paypal_payment_url(payment.amount_in_cents)}

      DE91500105175411307099
    MESSAGE
  end

  def paypal_payment_url(amount_in_cents)
    <<~MESSAGE
      https://paypal.me/gregoryigelmund/#{(amount_in_cents/100.to_f).round(2)}
    MESSAGE
  end

  def payment_drinks_lines(payment)
    payment.settlements.flat_map(&:positions).flat_map.each_with_object({}) do |position, hash|
      hash[position.drink.name] ||= { price_in_cents: position.drink_price_in_cents, amount: 0 }
      hash[position.drink.name][:amount] += position.amount
    end.map do |(name, details)|
      "#{details[:amount]} x #{name} (#{formatted_price(details[:price_in_cents])})"
    end
  end

  def lines_for_settlement(settlement)
    settlement.positions.map do |position|
      "#{position.amount} x #{position.drink.name} (#{formatted_price(position.drink_price_in_cents)})"
    end
  end

  def external?
    controller.class.ancestors.include?(External::BaseController)
  end
end
