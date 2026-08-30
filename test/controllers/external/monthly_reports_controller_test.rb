require "test_helper"

class External::MonthlyReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client = Client.create!(name: "Alice-#{SecureRandom.hex(4)}")
    @report = MonthlyReport.create!(title: "January")
  end

  test "is reachable without the basic auth the rest of the app requires" do
    get external_client_monthly_report_path(@client.access_uuid, @report)

    assert_response :success
  end

  test "an unknown access uuid is not found" do
    get external_client_monthly_report_path(SecureRandom.uuid, @report)

    assert_response :not_found
  end

  test "renders a report that has no attachment yet" do
    get external_client_monthly_report_path(@client.access_uuid, @report)

    assert_response :success
    assert_select "h1", @report.title
  end

  test "a suspended client can still open their report" do
    @client.suspend!

    get external_client_monthly_report_path(@client.access_uuid, @report)

    assert_response :success
  end
end
