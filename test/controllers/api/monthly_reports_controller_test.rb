require "test_helper"

class Api::MonthlyReportsControllerTest < ActionDispatch::IntegrationTest
  include ApiHelpers

  setup do
    @draft = MonthlyReport.create!(title: "January")
    @completed = MonthlyReport.create!(title: "February", completed_at: Time.current)
  end

  test "index lists drafts and completed reports with their state" do
    with_api_token { get api_monthly_reports_path, headers: api_headers }

    assert_response :success
    reports = response.parsed_body["monthly_reports"].index_by { |entry| entry["id"] }
    assert_equal "draft", reports.fetch(@draft.id)["state"]
    assert_nil reports.fetch(@draft.id)["completed_at"]
    assert_equal "completed", reports.fetch(@completed.id)["state"]
    assert_equal @completed.completed_at.iso8601, reports.fetch(@completed.id)["completed_at"]
  end

  test "index exposes the attached image, nil when there is none" do
    @draft.image.attach(io: StringIO.new("png-bytes"), filename: "january.png", content_type: "image/png")

    with_api_token { get api_monthly_reports_path, headers: api_headers }

    assert_response :success
    reports = response.parsed_body["monthly_reports"].index_by { |entry| entry["id"] }
    assert_equal "january.png", reports.fetch(@draft.id)["image_filename"]
    assert_match %r{\Ahttps?://}, reports.fetch(@draft.id)["image_url"]
    assert_nil reports.fetch(@completed.id)["image_url"]
    assert_nil reports.fetch(@completed.id)["image_filename"]
  end

  test "index filters by state" do
    with_api_token { get api_monthly_reports_path(state: "draft"), headers: api_headers }

    assert_response :success
    ids = response.parsed_body["monthly_reports"].map { |entry| entry["id"] }
    assert_includes ids, @draft.id
    assert_not_includes ids, @completed.id

    with_api_token { get api_monthly_reports_path(state: "completed"), headers: api_headers }

    assert_response :success
    ids = response.parsed_body["monthly_reports"].map { |entry| entry["id"] }
    assert_includes ids, @completed.id
    assert_not_includes ids, @draft.id
  end

  test "index returns nothing for an unknown state" do
    with_api_token { get api_monthly_reports_path(state: "nonsense"), headers: api_headers }

    assert_response :success
    assert_empty response.parsed_body["monthly_reports"]
  end

  test "complete marks the report as completed" do
    with_api_token { post complete_api_monthly_report_path(@draft), headers: api_headers }

    assert_response :success
    assert_equal "completed", response.parsed_body["monthly_report"]["state"]
    assert_not_nil response.parsed_body["monthly_report"]["completed_at"]
    assert @draft.reload.completed?
  end

  test "reopen moves the report back to draft" do
    with_api_token { post reopen_api_monthly_report_path(@completed), headers: api_headers }

    assert_response :success
    assert_equal "draft", response.parsed_body["monthly_report"]["state"]
    assert_nil response.parsed_body["monthly_report"]["completed_at"]
    assert_not @completed.reload.completed?
  end

  test "completing an unknown report returns not found" do
    with_api_token { post complete_api_monthly_report_path(id: 0), headers: api_headers }

    assert_response :not_found
    assert_equal "not_found", response.parsed_body["error"]
  end

  test "complete requires the api token" do
    with_api_token { post complete_api_monthly_report_path(@draft) }

    assert_response :unauthorized
    assert_not @draft.reload.completed?
  end
end
