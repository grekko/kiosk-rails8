require "test_helper"

class External::SettlementTrackingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client = Client.create!(name: "Alice-#{SecureRandom.hex(4)}")
    @report = MonthlyReport.create!(title: "January")
    @settlement = Settlement.create!(client: @client, monthly_report: @report, generated_at: Date.current)
  end

  def tracking_token = @settlement.signed_id(purpose: :email_link)

  test "is reachable without the basic auth the rest of the app requires" do
    get external_settlement_tracking_path(tracking_token)

    assert_redirected_to external_client_url(@client.access_uuid)
  end

  test "records the first open and notifies once" do
    assert_enqueued_emails 1 do
      get external_settlement_tracking_path(tracking_token)
    end

    first_opened_at = @settlement.reload.email_first_opened_at
    assert_not_nil first_opened_at

    travel 1.hour do
      assert_no_enqueued_emails do
        get external_settlement_tracking_path(tracking_token)
      end
    end

    assert_equal first_opened_at, @settlement.reload.email_first_opened_at
  end

  test "rejects a token signed for another purpose" do
    get external_settlement_tracking_path(@settlement.signed_id(purpose: :something_else))

    assert_response :not_found
  end

  test "rejects a garbage token" do
    get external_settlement_tracking_path("not-a-real-token")

    assert_response :not_found
  end
end
