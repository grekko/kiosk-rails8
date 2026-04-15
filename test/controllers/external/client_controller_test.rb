require "test_helper"

class External::ClientControllerTest < ActionDispatch::IntegrationTest
  test "shows exact and rounded payment options for positive outstanding amount" do
    client = Client.create!(name: "Alice")
    report = MonthlyReport.create!(title: "January")
    settlement = Settlement.create!(
      client: client,
      monthly_report: report,
      generated_at: Date.current,
      aasm_state: "completed"
    )
    drink = Drink.create!(name: "Pils", price_in_cents: 120)
    SettlementPosition.create!(
      settlement: settlement,
      drink: drink,
      amount: 1,
      price_in_cents: 120
    )

    get external_client_path(client.access_uuid)

    assert_response :success
    assert_includes @response.body, "1,20 EUR"
    assert_includes @response.body, "2,00 EUR"

    exact_url = ApplicationController.helpers.paypal_payment_url(120)
    rounded_url = ApplicationController.helpers.paypal_payment_url(200)

    assert_includes @response.body, exact_url
    assert_includes @response.body, rounded_url
  end

  test "does not show payment options when outstanding amount is zero" do
    client = Client.create!(name: "Bob")

    get external_client_path(client.access_uuid)

    assert_response :success
    assert_select "a", text: "PayPal-Link", count: 0
  end
end
