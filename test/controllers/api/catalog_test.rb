require "test_helper"

class Api::CatalogTest < ActionDispatch::IntegrationTest
  include ApiHelpers

  test "drinks index exposes the price used for settlement positions" do
    drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 120)
    drink.settlement_prices.create!(price_in_cents: 150, valid_from: 1.day.ago)

    with_api_token do
      get api_drinks_path, headers: api_headers
    end

    assert_response :success
    payload = response.parsed_body["drinks"].find { |entry| entry["id"] == drink.id }
    assert_equal 120, payload["price_in_cents"]
    assert_equal 150, payload["current_settlement_price_in_cents"]
  end

  test "monthly reports index lists the newest report first" do
    older = MonthlyReport.create!(title: "January")
    newer = MonthlyReport.create!(title: "February")

    with_api_token do
      get api_monthly_reports_path, headers: api_headers
    end

    assert_response :success
    ids = response.parsed_body["monthly_reports"].map { |entry| entry["id"] }
    assert_equal [ newer.id, older.id ], ids & [ newer.id, older.id ]
  end
end
