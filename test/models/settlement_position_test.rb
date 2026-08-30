require "test_helper"

class SettlementPositionTest < ActiveSupport::TestCase
  setup do
    @client = Client.create!(name: "Alice-#{SecureRandom.hex(4)}")
    @report = MonthlyReport.create!(title: "January")
    @drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 120)
    @settlement = Settlement.create!(client: @client, monthly_report: @report, generated_at: Date.current)
  end

  test "prices itself from the drink price on create" do
    position = @settlement.positions.create!(drink: @drink, amount: 2)

    assert_equal 240, position.price_in_cents
  end

  test "reprices when the amount changes" do
    position = @settlement.positions.create!(drink: @drink, amount: 2)

    position.update!(amount: 5)

    assert_equal 600, position.reload.price_in_cents
    assert_equal 600, @settlement.reload.price_in_cents
  end

  test "reprices when the drink changes" do
    other_drink = Drink.create!(name: "Cola-#{SecureRandom.hex(4)}", price_in_cents: 200)
    position = @settlement.positions.create!(drink: @drink, amount: 2)

    position.update!(drink: other_drink)

    assert_equal 400, position.reload.price_in_cents
  end

  test "uses the settlement price valid at the settlement date, not today's" do
    @drink.settlement_prices.create!(valid_from: 1.year.ago.to_date, price_in_cents: 90)
    settled_last_year = Settlement.create!(client: @client, monthly_report: @report, generated_at: 6.months.ago.to_date)

    position = settled_last_year.positions.create!(drink: @drink, amount: 2)

    assert_equal 180, position.price_in_cents
  end
end
