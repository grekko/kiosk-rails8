# Made-up example data so a fresh development database shows something on every admin page.
# Development only; skipped once any Drink exists, so running db:seed again adds nothing.
return unless Rails.env.development?
return if Drink.exists?

ActiveRecord::Base.transaction do
  month = Date.current.prev_month.beginning_of_month

  # name => [default price, Settlement Price], in cents; the Order adds 8 cents deposit per bottle
  drinks = { "Pils" => [ 80, 120 ], "Radler" => [ 85, 130 ], "Mate" => [ 90, 150 ], "Wasser" => [ 30, 60 ] }.to_h do |name, (purchase, selling)|
    drink = Drink.create!(name:, price_in_cents: purchase)
    drink.settlement_prices.create!(valid_from: month, price_in_cents: selling)
    [ name, drink ]
  end

  order = Order.create!(ordered_at: month)
  drinks.each_value do |drink|
    order.positions.create!(drink:, amount: 24, price_in_cents: 24 * drink.price_in_cents, deposit_in_cents: 24 * 8)
  end

  anna = Client.create!(name: "Anna Beispiel", email: "anna@example.com")
  ben = Client.create!(name: "Ben Muster")
  dora = Client.create!(name: "Dora Test", email: "dora@example.com")
  Client.create!(name: "Carla Probe", email: "carla@example.com").suspend!

  report = MonthlyReport.create!(title: "#{%w[Januar Februar März April Mai Juni Juli August September Oktober November Dezember][month.month - 1]} #{month.year}", description: "Example data")

  settle = lambda do |client, amounts|
    settlement = report.settlements.create!(client:, generated_at: month.end_of_month)
    amounts.each { |name, amount| settlement.positions.create!(drink: drinks.fetch(name), amount:) }
    settlement
  end

  settle.(dora, "Mate" => 3, "Wasser" => 2)                       # stays draft
  settle.(ben, "Pils" => 5, "Radler" => 2).complete!
  settle.(anna, "Pils" => 4, "Mate" => 1).complete!
  Payment.create_for_client(anna) # marks Anna's Settlement paid
end
