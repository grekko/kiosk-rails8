require "test_helper"

class LeaderboardTest < ActiveSupport::TestCase
  test "returns grouped and sorted data for paid settlements only" do
    # Setup Data
    client_a = Client.create!(name: "Alice", email: "alice@example.com")
    client_b = Client.create!(name: "Bob", email: "bob@example.com")

    drink_coke = Drink.create!(name: "Coke", price_in_cents: 100)
    drink_water = Drink.create!(name: "Water", price_in_cents: 50)

    # Create necessary associated records
    monthly_report = MonthlyReport.create!(title: "Jan 2026")

    # Paid Settlement for Alice (2 Cokes, 1 Water)
    settlement_paid = Settlement.create!(
      client: client_a,
      generated_at: Date.today,
      paid_at: Time.current,
      monthly_report: monthly_report
    )
    SettlementPosition.create!(settlement: settlement_paid, drink: drink_coke, amount: 2, price_in_cents: 100)
    SettlementPosition.create!(settlement: settlement_paid, drink: drink_water, amount: 1, price_in_cents: 50)

    # Paid Settlement for Bob (5 Cokes)
    settlement_paid_bob = Settlement.create!(
      client: client_b,
      generated_at: Date.today,
      paid_at: Time.current,
      monthly_report: monthly_report
    )
    SettlementPosition.create!(settlement: settlement_paid_bob, drink: drink_coke, amount: 5, price_in_cents: 100)

    # Unpaid Settlement for Alice (100 Cokes - should be ignored)
    settlement_unpaid = Settlement.create!(
      client: client_a,
      generated_at: Date.today,
      paid_at: nil,
      monthly_report: monthly_report
    )
    SettlementPosition.create!(settlement: settlement_unpaid, drink: drink_coke, amount: 100, price_in_cents: 100)

    # Execute
    result = Leaderboard.call

    # Verify Structure
    assert_kind_of Hash, result
    assert_includes result.keys, "Coke"
    assert_includes result.keys, "Water"

    # Verify Calculations & Filtering
    # Coke: Bob (5), Alice (2) - Unpaid (100) ignored
    coke_leaderboard = result["Coke"]
    assert_equal 2, coke_leaderboard.size

    first_place = coke_leaderboard.first
    assert_equal "Bob", first_place[:client]
    assert_equal 5, first_place[:count]

    second_place = coke_leaderboard.last
    assert_equal "Alice", second_place[:client]
    assert_equal 2, second_place[:count]

    # Water: Alice (1)
    water_leaderboard = result["Water"]
    assert_equal 1, water_leaderboard.size
    assert_equal "Alice", water_leaderboard.first[:client]
    assert_equal 1, water_leaderboard.first[:count]
  end
end
