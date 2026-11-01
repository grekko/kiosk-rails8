require "test_helper"

class SettlementMailerTest < ActionMailer::TestCase
  setup do
    @client = Client.create!(name: "Alice-#{SecureRandom.hex(4)}", email: "alice@example.com")
    @report = MonthlyReport.create!(title: "Januar 2026")
    @settlement = Settlement.create!(client: @client, monthly_report: @report, generated_at: Date.current)
  end

  test "completed_mail goes to the client with the report title in the subject" do
    mail = SettlementMailer.with(settlement: @settlement).completed_mail

    assert_equal [ "alice@example.com" ], mail.to
    assert_includes mail.subject, "Januar 2026"
    assert_equal "outbound", mail.message_stream
  end

  test "opened_notification goes to the kiosk with the report title and client name in the subject" do
    mail = SettlementMailer.with(settlement: @settlement).opened_notification

    assert_equal [ "kiosk@grekko.de" ], mail.to
    assert_includes mail.subject, "Januar 2026"
    assert_includes mail.subject, @client.name
    assert_equal "outbound", mail.message_stream
  end
end
