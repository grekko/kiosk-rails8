require "test_helper"

class DrinkTest < ActiveSupport::TestCase
  setup do
    @drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 120)
  end

  test "falls back to the purchase price when no settlement price exists" do
    assert_equal 120, @drink.price_in_cents_at(date: Date.current)
    assert_nil @drink.current_settlement_price
  end

  test "uses a settlement price that is already valid" do
    @drink.settlement_prices.create!(valid_from: 1.day.ago.to_date, price_in_cents: 150)

    assert_equal 150, @drink.price_in_cents_at(date: Date.current)
  end

  test "a settlement price applies on the day it becomes valid" do
    @drink.settlement_prices.create!(valid_from: Date.current, price_in_cents: 150)

    assert_equal 150, @drink.price_in_cents_at(date: Date.current)
  end

  test "ignores settlement prices that are not valid yet" do
    @drink.settlement_prices.create!(valid_from: Date.current + 1, price_in_cents: 150)

    assert_equal 120, @drink.price_in_cents_at(date: Date.current)
  end

  test "picks the newest price that is valid at the given date" do
    @drink.settlement_prices.create!(valid_from: 2.years.ago.to_date, price_in_cents: 100)
    @drink.settlement_prices.create!(valid_from: 1.year.ago.to_date, price_in_cents: 150)
    @drink.settlement_prices.create!(valid_from: Date.current + 1, price_in_cents: 200)

    assert_equal 100, @drink.price_in_cents_at(date: 18.months.ago.to_date)
    assert_equal 150, @drink.price_in_cents_at(date: Date.current)
  end

  test "insertion order does not decide which price wins" do
    @drink.settlement_prices.create!(valid_from: 1.year.ago.to_date, price_in_cents: 150)
    @drink.settlement_prices.create!(valid_from: 2.years.ago.to_date, price_in_cents: 100)

    assert_equal 150, @drink.price_in_cents_at(date: Date.current)
  end

  test "ignores deactivated settlement prices" do
    price = @drink.settlement_prices.create!(valid_from: 1.year.ago.to_date, price_in_cents: 150)
    price.deactivate

    assert_equal 120, @drink.price_in_cents_at(date: Date.current)
    assert_nil @drink.current_settlement_price
  end

  test "falls back to the newest active price when a newer one is deactivated" do
    @drink.settlement_prices.create!(valid_from: 2.years.ago.to_date, price_in_cents: 100)
    @drink.settlement_prices.create!(valid_from: 1.year.ago.to_date, price_in_cents: 150).deactivate

    assert_equal 100, @drink.price_in_cents_at(date: Date.current)
  end
end
