require "test_helper"

class DrinkInventoryTest < ActiveSupport::TestCase
  setup do
    @drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 120)
    @client = Client.create!(name: "Alice-#{SecureRandom.hex(4)}")
    @report = MonthlyReport.create!(title: "January")
  end

  def row_for(drink) = DrinkInventory.all_rows.find { |row| row.id == drink.id }

  test "a drink that was never ordered or settled counts as zero" do
    row = row_for(@drink)

    assert_equal 0, row.ordered_count
    assert_equal 0, row.settled_count
    assert_equal 0, row.remaining_count
    assert_equal 0, row.purchase_price
  end

  test "remaining stock is what was ordered minus what was settled" do
    order_drinks(10)
    settle_drinks(4)

    row = row_for(@drink)

    assert_equal 10, row.ordered_count
    assert_equal 4, row.settled_count
    assert_equal 6, row.remaining_count
  end

  test "sums counts across several orders and settlements" do
    order_drinks(10)
    order_drinks(5)
    settle_drinks(3)
    settle_drinks(2)

    row = row_for(@drink)

    assert_equal 15, row.ordered_count
    assert_equal 5, row.settled_count
    assert_equal 10, row.remaining_count
  end

  test "values remaining stock at purchase and current selling price" do
    @drink.settlement_prices.create!(valid_from: 1.day.ago.to_date, price_in_cents: 200)
    order_drinks(10)
    settle_drinks(4)

    row = row_for(@drink)

    assert_equal 720, row.purchase_price  # 6 * 120
    assert_equal 1200, row.selling_price  # 6 * 200
  end

  test "settling more than was ordered reports negative stock" do
    order_drinks(2)
    settle_drinks(5)

    row = row_for(@drink)

    assert_equal(-3, row.remaining_count)
    assert_equal(-360, row.purchase_price)
  end

  private

  def order_drinks(amount)
    order = Order.create!(ordered_at: Date.current)
    order.positions.create!(drink: @drink, amount: amount, price_in_cents: 120 * amount)
  end

  def settle_drinks(amount)
    settlement = Settlement.create!(client: @client, monthly_report: @report, generated_at: Date.current)
    settlement.positions.create!(drink: @drink, amount: amount)
  end
end
