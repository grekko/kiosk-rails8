require "test_helper"

class MonthlyReportsControllerTest < ActionDispatch::IntegrationTest
  AUTH = {
    "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("kiosk", "sup3r-s3cr37")
  }.freeze

  setup do
    @report = MonthlyReport.create!(title: "Report-#{SecureRandom.hex(4)}")
  end

  test "index lists drafts and completed reports" do
    completed = MonthlyReport.create!(title: "Completed-#{SecureRandom.hex(4)}", completed_at: Time.current)

    get monthly_reports_path, headers: AUTH

    assert_response :success
    assert_select "#monthly_reports td a", text: @report.title
    assert_select "#monthly_reports td a", text: completed.title
  end

  test "index filters by state" do
    completed = MonthlyReport.create!(title: "Completed-#{SecureRandom.hex(4)}", completed_at: Time.current)

    get monthly_reports_path(state: "completed"), headers: AUTH

    assert_response :success
    assert_select "#monthly_reports td a", text: completed.title
    assert_select "#monthly_reports td a", text: @report.title, count: 0
  end

  test "edit offers the completion toggle" do
    get edit_monthly_report_path(@report), headers: AUTH

    assert_response :success
    assert_select "form[action=?]", complete_monthly_report_path(@report)

    @report.complete!
    get edit_monthly_report_path(@report), headers: AUTH

    assert_response :success
    assert_select "form[action=?]", reopen_monthly_report_path(@report)
  end

  test "complete marks the report as completed" do
    patch complete_monthly_report_path(@report), headers: AUTH

    assert_redirected_to monthly_reports_path
    assert @report.reload.completed?
  end

  test "reopen moves the report back to draft" do
    @report.complete!

    patch reopen_monthly_report_path(@report), headers: AUTH

    assert_redirected_to monthly_reports_path
    assert_not @report.reload.completed?
  end
end
