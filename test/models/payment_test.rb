require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  test "create_for_client with no amount pays every outstanding settlement" do
    client = client_with_settlements(1000, 1000)

    payment = Payment.create_for_client(client)

    assert payment.persisted?
    assert_equal 2000, payment.amount_in_cents
    assert client.settlements.reload.all?(&:paid?)
    assert client.settlements.all?(&:paid_at), "expected paid_at on every settlement"
  end

  test "create_for_client greedily pays whole settlements oldest-first, ignoring leftover" do
    client = Client.create!(name: "Payer-#{SecureRandom.hex(4)}")
    report = MonthlyReport.create!(title: "Report")
    oldest = completed_settlement(client, report, 1000, generated_at: 3.days.ago)
    mid    = completed_settlement(client, report, 1000, generated_at: 2.days.ago)
    newest = completed_settlement(client, report, 1000, generated_at: 1.day.ago)

    payment = Payment.create_for_client(client, 1500)

    assert_equal 1000, payment.amount_in_cents, "leftover 500 must be ignored"
    assert_equal [ oldest.id ], payment.settlements.pluck(:id)
    assert oldest.reload.paid?
    assert mid.reload.completed?
    assert newest.reload.completed?
  end

  test "create_for_client returns nil when the amount covers no settlement" do
    client = Client.create!(name: "Payer-#{SecureRandom.hex(4)}")
    report = MonthlyReport.create!(title: "Report")
    settlement = completed_settlement(client, report, 1000)

    assert_nil Payment.create_for_client(client, 500)
    assert settlement.reload.completed?
    assert_equal 0, client.payments.count
  end

  private

  def client_with_settlements(*prices)
    client = Client.create!(name: "Payer-#{SecureRandom.hex(4)}")
    report = MonthlyReport.create!(title: "Report")
    prices.each { |price| completed_settlement(client, report, price) }
    client
  end

  def completed_settlement(client, report, price_in_cents, generated_at: Time.current)
    settlement = Settlement.create!(client:, monthly_report: report, generated_at:)
    drink = Drink.create!(name: "Beer-#{SecureRandom.hex(4)}", price_in_cents:)
    SettlementPosition.create!(settlement:, drink:, amount: 1, price_in_cents:)
    settlement.complete!
    settlement
  end
end
