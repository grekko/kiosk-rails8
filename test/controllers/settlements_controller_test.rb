require "test_helper"

class SettlementsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  AUTH = BasicAuthHelpers::HEADERS

  test "index lists settlements" do
    settlement = create_settlement

    get settlements_path, headers: AUTH

    assert_response :success
    assert_select "#settlements", text: /#{settlement.client.name}/
  end

  test "filtered lists only the settlements of one client" do
    settlement = create_settlement
    other = create_settlement

    get filtered_settlements_path(client_id: settlement.client_id), headers: AUTH

    assert_response :success
    assert_select "#settlements", text: /#{settlement.client.name}/
    assert_select "#settlements", text: /#{other.client.name}/, count: 0
  end

  test "new renders the form" do
    get new_settlement_path, headers: AUTH

    assert_response :success
  end

  test "edit renders a draft settlement with its positions and total" do
    settlement = create_settlement
    drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 150)
    SettlementPosition.create!(settlement:, drink:, amount: 2)

    get edit_settlement_path(settlement), headers: AUTH

    assert_response :success
    assert_select "#positions", text: /#{drink.name}/
  end

  test "create saves a draft settlement and redirects to its edit page" do
    client = Client.create!(name: "Alice-#{SecureRandom.hex(4)}")
    report = MonthlyReport.create!(title: "Januar 2026")

    assert_difference -> { Settlement.count }, 1 do
      post settlements_path, params: { settlement: { client_id: client.id, monthly_report_id: report.id, generated_at: "2026-01-31" } }, headers: AUTH
    end

    settlement = Settlement.last
    assert_redirected_to edit_settlement_path(settlement)
    assert settlement.draft?
    assert_equal client, settlement.client
    assert_equal Date.new(2026, 1, 31), settlement.generated_at.to_date
  end

  test "create without generated_at does not save" do
    client = Client.create!(name: "Alice-#{SecureRandom.hex(4)}")
    report = MonthlyReport.create!(title: "Januar 2026")

    assert_no_difference -> { Settlement.count } do
      post settlements_path, params: { settlement: { client_id: client.id, monthly_report_id: report.id, generated_at: "" } }, headers: AUTH
    end

    assert_response :unprocessable_entity
  end

  test "update changes the settlement date" do
    settlement = create_settlement

    patch settlement_path(settlement), params: { settlement: { generated_at: "2026-02-28" } }, headers: AUTH

    assert_redirected_to edit_settlement_path(settlement)
    assert_equal Date.new(2026, 2, 28), settlement.reload.generated_at.to_date
  end

  test "update without generated_at does not save" do
    settlement = create_settlement
    generated_at = settlement.generated_at

    patch settlement_path(settlement), params: { settlement: { generated_at: "" } }, headers: AUTH

    assert_response :unprocessable_entity
    assert_equal generated_at, settlement.reload.generated_at
  end

  test "update refuses to change a completed settlement" do
    settlement = create_settlement
    settlement.complete!

    patch settlement_path(settlement), params: { settlement: { generated_at: "2026-02-28" } }, headers: AUTH

    assert_response :unprocessable_entity
    assert_includes response.body, "can no longer be changed once the settlement is completed"
    assert_equal Date.new(2026, 1, 31), settlement.reload.generated_at.to_date
  end

  test "complete moves a draft settlement to completed" do
    settlement = create_settlement

    patch complete_settlement_path(settlement), headers: AUTH

    assert_redirected_to settlements_path
    assert settlement.reload.completed?
    assert_not_nil settlement.completed_at
  end

  test "edit offers Back to draft for a completed settlement" do
    settlement = create_settlement
    settlement.complete!

    get edit_settlement_path(settlement), headers: AUTH

    assert_select "form[action=?] button", reopen_settlement_path(settlement), text: "Back to draft"
  end

  test "edit hides Back to draft once the email was sent" do
    settlement = create_settlement
    settlement.complete!
    settlement.update!(email_sent_at: Time.current)

    get edit_settlement_path(settlement), headers: AUTH

    assert_select "form[action=?]", reopen_settlement_path(settlement), count: 0
  end

  test "reopen moves a completed settlement back to draft" do
    settlement = create_settlement
    settlement.complete!

    patch reopen_settlement_path(settlement), headers: AUTH

    assert_redirected_to edit_settlement_path(settlement)
    assert_equal "Settlement moved back to draft.", flash[:notice]
    assert settlement.reload.draft?
    assert_nil settlement.completed_at
  end

  test "reopen refuses an emailed settlement" do
    settlement = create_settlement
    settlement.complete!
    settlement.update!(email_sent_at: Time.current)

    patch reopen_settlement_path(settlement), headers: AUTH

    assert_redirected_to edit_settlement_path(settlement)
    assert_equal "A paid or emailed settlement can't be moved back to draft.", flash[:alert]
    assert settlement.reload.completed?
  end

  test "schedule_email enqueues the settlement email when the client has an email" do
    settlement = create_settlement(client: Client.create!(name: "Alice-#{SecureRandom.hex(4)}", email: "alice@example.com"))
    settlement.complete!

    assert_enqueued_emails 1 do
      patch schedule_email_settlement_path(settlement), headers: AUTH
    end

    assert_redirected_to settlements_path
    assert_not_nil settlement.reload.email_sent_at
  end

  test "schedule_email sends nothing when the client has no email" do
    settlement = create_settlement
    settlement.complete!

    assert_no_enqueued_emails do
      patch schedule_email_settlement_path(settlement), headers: AUTH
    end

    assert_redirected_to settlements_path
    assert_equal "Client must have an email address", flash[:alert]
    assert_nil settlement.reload.email_sent_at
  end

  test "schedule_email refuses a draft" do
    settlement = create_settlement(client: Client.create!(name: "Alice-#{SecureRandom.hex(4)}", email: "alice@example.com"))

    assert_no_enqueued_emails do
      patch schedule_email_settlement_path(settlement), headers: AUTH
    end

    assert_redirected_to settlements_path
    assert_includes flash[:alert], "Only a completed or paid settlement can be emailed"
    assert_nil settlement.reload.email_sent_at
  end

  test "destroy deletes a draft settlement" do
    settlement = create_settlement

    assert_difference -> { Settlement.count }, -1 do
      delete settlement_path(settlement), headers: AUTH
    end

    assert_redirected_to settlements_path
  end

  test "destroy keeps a completed settlement" do
    settlement = create_settlement
    settlement.complete!

    assert_no_difference -> { Settlement.count } do
      delete settlement_path(settlement), headers: AUTH
    end

    assert_redirected_to settlements_path
  end

  private

  def create_settlement(client: Client.create!(name: "Alice-#{SecureRandom.hex(4)}"))
    Settlement.create!(client:, monthly_report: MonthlyReport.create!(title: "Januar 2026"), generated_at: Date.new(2026, 1, 31))
  end
end
