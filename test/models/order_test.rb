require "test_helper"

class OrderTest < ActiveSupport::TestCase
  setup do
    @drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 120)
    @order = Order.create!(ordered_at: Date.current)
  end

  test "requires an order date" do
    assert_not Order.new.valid?
  end

  test "an empty order costs nothing" do
    assert_equal 0, @order.price_in_cents
    assert_equal 0, @order.deposit_in_cents
    assert_equal 0, @order.total_price_in_cents
  end

  test "sums price and deposit over all positions" do
    @order.positions.create!(drink: @drink, amount: 10, price_in_cents: 1200, deposit_in_cents: 150)
    @order.positions.create!(drink: @drink, amount: 5, price_in_cents: 600, deposit_in_cents: 75)

    assert_equal 1800, @order.price_in_cents
    assert_equal 225, @order.deposit_in_cents
  end

  test "total is price plus deposit, computed by the database" do
    position = @order.positions.create!(drink: @drink, amount: 10, price_in_cents: 1200, deposit_in_cents: 150)

    assert_equal 1350, position.reload.total_price_in_cents
    assert_equal 1350, @order.total_price_in_cents
  end

  test "destroying an order takes its positions with it" do
    @order.positions.create!(drink: @drink, amount: 10, price_in_cents: 1200, deposit_in_cents: 150)

    assert_difference -> { OrderPosition.count }, -1 do
      @order.destroy!
    end
  end
end
