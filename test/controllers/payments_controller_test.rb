require "test_helper"

class PaymentsControllerTest < ActionDispatch::IntegrationTest
  AUTH = {
    "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("kiosk", "sup3r-s3cr37")
  }.freeze

  test "new renders the form prefilled with the outstanding amount" do
    client = Client.create!(name: "Payer-#{SecureRandom.hex(4)}")
    completed_settlement(client, 1000)

    get new_client_payment_path(client), headers: AUTH

    assert_response :success
    assert_select "input[name=?][value=?]", "payment[amount_in_cents]", "1000"
  end

  test "create with a partial amount pays only the covered settlement" do
    client = Client.create!(name: "Payer-#{SecureRandom.hex(4)}")
    report = MonthlyReport.create!(title: "Report")
    oldest = completed_settlement(client, 1000, report:, generated_at: 2.days.ago)
    newest = completed_settlement(client, 1000, report:, generated_at: 1.day.ago)

    post client_payments_path(client), params: { payment: { amount_in_cents: 1000 } }, headers: AUTH

    assert_redirected_to clients_path
    assert oldest.reload.paid?
    assert newest.reload.completed?
    assert_equal 1000, client.payments.sole.amount_in_cents
  end

  test "create with an amount too low to cover anything redirects back with an alert" do
    client = Client.create!(name: "Payer-#{SecureRandom.hex(4)}")
    completed_settlement(client, 1000)

    post client_payments_path(client), params: { payment: { amount_in_cents: 500 } }, headers: AUTH

    assert_redirected_to new_client_payment_path(client)
    assert_equal 0, client.payments.count
  end

  private

  def completed_settlement(client, price_in_cents, report: MonthlyReport.create!(title: "Report"), generated_at: Time.current)
    settlement = Settlement.create!(client:, monthly_report: report, generated_at:)
    drink = Drink.create!(name: "Beer-#{SecureRandom.hex(4)}", price_in_cents:)
    SettlementPosition.create!(settlement:, drink:, amount: 1, price_in_cents:)
    settlement.complete!
    settlement
  end
end
