require "test_helper"

class InventoryControllerTest < ActionDispatch::IntegrationTest
  test "show lists each drink with its remaining count" do
    drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 150)
    Order.create!(ordered_at: Time.current).positions.create!(drink:, amount: 20, price_in_cents: 2400, deposit_in_cents: 300)
    settlement = Settlement.create!(client: Client.create!(name: "Alice-#{SecureRandom.hex(4)}"), monthly_report: MonthlyReport.create!(title: "Januar 2026"), generated_at: Date.new(2026, 1, 31))
    SettlementPosition.create!(settlement:, drink:, amount: 3)

    get root_path

    assert_response :success
    assert_select "#drinks tr", text: /#{drink.name}\s*20\s*3\s*17/
    assert_select "#finance", text: /Ordered\s*24,00/
  end

  test "show renders without any drinks or orders" do
    get root_path

    assert_response :success
  end
end
