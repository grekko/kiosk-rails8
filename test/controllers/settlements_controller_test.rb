require "test_helper"

class SettlementsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper
  include QueryCountHelpers
  include SolidQueueHelpers

  test "index runs the same number of queries for more settlements" do
    create_sendable_settlement
    few = count_queries { get settlements_path }

    3.times { create_sendable_settlement }
    many = count_queries { get settlements_path }

    assert_response :success
    assert_equal few, many
  end

  test "index lists settlements" do
    settlement = create_settlement

    get settlements_path

    assert_response :success
    assert_select "#settlements", text: /#{settlement.client.name}/
  end

  test "filtered lists only the settlements of one client" do
    settlement = create_settlement
    other = create_settlement

    get filtered_settlements_path(client_id: settlement.client_id)

    assert_response :success
    assert_select "#settlements", text: /#{settlement.client.name}/
    assert_select "#settlements", text: /#{other.client.name}/, count: 0
  end

  test "new renders the form" do
    get new_settlement_path

    assert_response :success
  end

  test "new preselects the client and monthly report from the params" do
    Client.create!(name: "Bob-#{SecureRandom.hex(4)}")
    client = Client.create!(name: "Alice-#{SecureRandom.hex(4)}")
    MonthlyReport.create!(title: "Dezember 2025")
    report = MonthlyReport.create!(title: "Januar 2026")

    get new_settlement_path(client_id: client.id, monthly_report_id: report.id)

    assert_response :success
    assert_select "#settlement_client_id option[selected][value=?]", client.id.to_s
    assert_select "#settlement_monthly_report_id option[selected][value=?]", report.id.to_s
  end

  test "edit renders a draft settlement with its positions and total" do
    settlement = create_settlement
    drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 150)
    SettlementPosition.create!(settlement:, drink:, amount: 2)

    get edit_settlement_path(settlement)

    assert_response :success
    assert_select "#positions", text: /#{drink.name}/
  end

  test "create saves a draft settlement and redirects to its edit page" do
    client = Client.create!(name: "Alice-#{SecureRandom.hex(4)}")
    report = MonthlyReport.create!(title: "Januar 2026")

    assert_difference -> { Settlement.count }, 1 do
      post settlements_path, params: { settlement: { client_id: client.id, monthly_report_id: report.id, generated_at: "2026-01-31" } }
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
      post settlements_path, params: { settlement: { client_id: client.id, monthly_report_id: report.id, generated_at: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "update changes the settlement date" do
    settlement = create_settlement

    patch settlement_path(settlement), params: { settlement: { generated_at: "2026-02-28" } }

    assert_redirected_to edit_settlement_path(settlement)
    assert_equal Date.new(2026, 2, 28), settlement.reload.generated_at.to_date
  end

  test "update without generated_at does not save" do
    settlement = create_settlement
    generated_at = settlement.generated_at

    patch settlement_path(settlement), params: { settlement: { generated_at: "" } }

    assert_response :unprocessable_entity
    assert_equal generated_at, settlement.reload.generated_at
  end

  test "update refuses to change a completed settlement" do
    settlement = create_settlement
    settlement.complete!

    patch settlement_path(settlement), params: { settlement: { generated_at: "2026-02-28" } }

    assert_response :unprocessable_entity
    assert_includes response.body, "can no longer be changed once the settlement is completed"
    assert_equal Date.new(2026, 1, 31), settlement.reload.generated_at.to_date
  end

  test "complete moves a draft settlement to completed" do
    settlement = create_settlement

    patch complete_settlement_path(settlement)

    assert_redirected_to settlements_path
    assert settlement.reload.completed?
    assert_not_nil settlement.completed_at
  end

  test "complete refuses an already completed settlement" do
    settlement = create_settlement
    settlement.complete!

    patch complete_settlement_path(settlement)

    assert_redirected_to root_path
    assert_match "cannot transition from 'completed'", flash[:alert]
    assert settlement.reload.completed?
  end

  test "edit offers Back to draft for a completed settlement" do
    settlement = create_settlement
    settlement.complete!

    get edit_settlement_path(settlement)

    assert_select "form[action=?] button", reopen_settlement_path(settlement), text: "Back to draft"
  end

  test "edit hides Back to draft once the email was sent" do
    settlement = create_settlement
    settlement.complete!
    settlement.update!(email_sent_at: Time.current)

    get edit_settlement_path(settlement)

    assert_select "form[action=?]", reopen_settlement_path(settlement), count: 0
  end

  test "reopen moves a completed settlement back to draft" do
    settlement = create_settlement
    settlement.complete!

    patch reopen_settlement_path(settlement)

    assert_redirected_to edit_settlement_path(settlement)
    assert_equal "Settlement moved back to draft.", flash[:notice]
    assert settlement.reload.draft?
    assert_nil settlement.completed_at
  end

  test "reopen refuses an emailed settlement" do
    settlement = create_settlement
    settlement.complete!
    settlement.update!(email_sent_at: Time.current)

    patch reopen_settlement_path(settlement)

    assert_redirected_to edit_settlement_path(settlement)
    assert_equal "A paid or emailed settlement can't be moved back to draft.", flash[:alert]
    assert settlement.reload.completed?
  end

  test "schedule_email enqueues the settlement email when the client has an email" do
    settlement = create_settlement(client: Client.create!(name: "Alice-#{SecureRandom.hex(4)}", email: "alice@example.com"))
    settlement.complete!

    assert_enqueued_emails 1 do
      patch schedule_email_settlement_path(settlement)
    end

    assert_redirected_to settlements_path
    assert_not_nil settlement.reload.email_sent_at
  end

  test "schedule_email sends nothing when the client has no email" do
    settlement = create_settlement
    settlement.complete!

    assert_no_enqueued_emails do
      patch schedule_email_settlement_path(settlement)
    end

    assert_redirected_to settlements_path
    assert_equal "Client must have an email address", flash[:alert]
    assert_nil settlement.reload.email_sent_at
  end

  test "schedule_email refuses a draft" do
    settlement = create_settlement(client: Client.create!(name: "Alice-#{SecureRandom.hex(4)}", email: "alice@example.com"))

    assert_no_enqueued_emails do
      patch schedule_email_settlement_path(settlement)
    end

    assert_redirected_to settlements_path
    assert_includes flash[:alert], "Only a completed or paid settlement can be emailed"
    assert_nil settlement.reload.email_sent_at
  end

  test "destroy deletes a draft settlement" do
    settlement = create_settlement

    assert_difference -> { Settlement.count }, -1 do
      delete settlement_path(settlement)
    end

    assert_redirected_to settlements_path
  end

  test "destroy keeps a completed settlement" do
    settlement = create_settlement
    settlement.complete!

    assert_no_difference -> { Settlement.count } do
      delete settlement_path(settlement)
    end

    assert_redirected_to settlements_path
  end

  test "index marks a settlement whose email failed and offers a retry instead of a send" do
    load_solid_queue_tables
    failed = create_sendable_settlement
    fail_settlement_email(failed, IOError.new("bad address"))
    fine = create_sendable_settlement
    other_mail = create_sendable_settlement
    with_solid_queue { SettlementMailer.with(settlement: other_mail).opened_notification.deliver_later }
    fail_last_job

    get settlements_path

    assert_response :success
    assert_select ".email-failed", count: 1, text: /Email failed \(IOError\)/
    assert_select "form[action=?]", retry_email_settlement_path(failed)
    assert_select "form[action=?]", schedule_email_settlement_path(failed), count: 0
    assert_select "form[action=?]", schedule_email_settlement_path(fine)
    assert_select "form[action=?]", retry_email_settlement_path(fine), count: 0
  end

  test "index needs one queue query for any number of failed emails" do
    load_solid_queue_tables
    fail_settlement_email(create_sendable_settlement)
    few = count_queries { get settlements_path }

    3.times { fail_settlement_email(create_sendable_settlement) }
    many = count_queries { get settlements_path }

    assert_select ".email-failed", count: 4
    assert_equal few, many
  end

  test "retry_email runs the failed job again without a second job or a new claim" do
    load_solid_queue_tables
    settlement = create_sendable_settlement
    job = fail_settlement_email(settlement)
    sent_at = settlement.reload.email_sent_at

    assert_no_difference -> { SolidQueue::Job.count } do
      patch retry_email_settlement_path(settlement)
    end

    assert_redirected_to settlements_path
    assert_equal "Email queued again.", flash[:notice]
    assert_not SolidQueue::FailedExecution.exists?(job_id: job.id)
    assert SolidQueue::ReadyExecution.exists?(job_id: job.id)
    assert_equal sent_at, settlement.reload.email_sent_at

    patch retry_email_settlement_path(settlement)

    assert_redirected_to settlements_path
    assert_equal "There is no failed email to retry.", flash[:alert]
    assert SolidQueue::ReadyExecution.exists?(job_id: job.id)
  end

  test "retry_email without solid_queue tables says there is nothing to retry" do
    settlement = create_sendable_settlement

    patch retry_email_settlement_path(settlement)

    assert_redirected_to settlements_path
    assert_equal "There is no failed email to retry.", flash[:alert]
  end

  private

  # Completed, with positions and a Client email, so its row also checks whether it can be emailed.
  def create_sendable_settlement
    name = "Alice-#{SecureRandom.hex(4)}"
    settlement = create_settlement(client: Client.create!(name:, email: "#{name}@example.com"))
    settlement.positions.create!(drink: Drink.create!(name: "Beer-#{SecureRandom.hex(4)}", price_in_cents: 150), amount: 2)
    settlement.complete!
    settlement
  end

  def create_settlement(client: Client.create!(name: "Alice-#{SecureRandom.hex(4)}"))
    Settlement.create!(client:, monthly_report: MonthlyReport.create!(title: "Januar 2026"), generated_at: Date.new(2026, 1, 31))
  end
end
