require "test_helper"

class Api::SettlementsControllerTest < ActionDispatch::IntegrationTest
  include ApiHelpers

  setup do
    @client = Client.create!(name: "Alice-#{SecureRandom.hex(4)}", email: "alice-#{SecureRandom.hex(4)}@example.com")
    @report = MonthlyReport.create!(title: "January")
    @drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 120)
  end

  test "create returns the settlement including its positions" do
    with_api_token do
      post api_settlements_path,
           params: {
             settlement: {
               client_id: @client.id,
               monthly_report_id: @report.id,
               generated_at: "2026-01-31",
               positions: [ { drink_id: @drink.id, amount: 3 } ]
             }
           },
           headers: api_headers,
           as: :json
    end

    assert_response :created
    settlement = response.parsed_body["settlement"]
    assert_equal "draft", settlement["state"]
    assert_equal @client.id, settlement["client_id"]
    assert_equal "2026-01-31", settlement["generated_at"]
    assert_equal 360, settlement["price_in_cents"]
    assert_equal [ 3 ], settlement["positions"].map { |position| position["amount"] }
  end

  test "create without positions works" do
    with_api_token do
      post api_settlements_path,
           params: { settlement: { client_id: @client.id, monthly_report_id: @report.id, generated_at: "2026-01-31" } },
           headers: api_headers,
           as: :json
    end

    assert_response :created
    assert_equal 0, response.parsed_body["settlement"]["price_in_cents"]
  end

  test "create with an unknown client returns a validation error" do
    with_api_token do
      post api_settlements_path,
           params: { settlement: { client_id: 0, monthly_report_id: @report.id, generated_at: "2026-01-31" } },
           headers: api_headers,
           as: :json
    end

    assert_response :unprocessable_entity
    assert_equal "validation_failed", response.parsed_body["error"]
    assert_includes response.parsed_body["details"].keys, "client"
  end

  test "create rolls back the settlement when a position is invalid" do
    assert_no_difference -> { Settlement.count } do
      with_api_token do
        post api_settlements_path,
             params: {
               settlement: {
                 client_id: @client.id,
                 monthly_report_id: @report.id,
                 generated_at: "2026-01-31",
                 positions: [ { drink_id: 0, amount: 1 } ]
               }
             },
             headers: api_headers,
             as: :json
      end
    end

    assert_response :unprocessable_entity
  end

  test "create without the settlement key returns a 400" do
    with_api_token do
      post api_settlements_path, params: { client_id: @client.id }, headers: api_headers, as: :json
    end

    assert_response :bad_request
    assert_equal "parameter_missing", response.parsed_body["error"]
  end

  test "update changes the settlement" do
    settlement = create_settlement

    with_api_token do
      patch api_settlement_path(settlement), params: { settlement: { generated_at: "2026-02-28" } },
                                             headers: api_headers, as: :json
    end

    assert_response :success
    assert_equal "2026-02-28", response.parsed_body["settlement"]["generated_at"]
    assert_equal Date.new(2026, 2, 28), settlement.reload.generated_at
  end

  test "show returns a single settlement and unknown ids return a 404" do
    settlement = create_settlement

    with_api_token do
      get api_settlement_path(settlement), headers: api_headers
      assert_response :success
      assert_equal settlement.id, response.parsed_body["settlement"]["id"]

      get api_settlement_path(id: 0), headers: api_headers
    end

    assert_response :not_found
    assert_equal "not_found", response.parsed_body["error"]
  end

  test "index can be filtered by client and state" do
    settlement = create_settlement
    other = Settlement.create!(client: Client.create!(name: "Bob-#{SecureRandom.hex(4)}"),
                               monthly_report: @report, generated_at: Date.current)

    with_api_token do
      get api_settlements_path(client_id: @client.id), headers: api_headers
      assert_response :success
      ids = response.parsed_body["settlements"].map { |entry| entry["id"] }
      assert_equal [ settlement.id ], ids

      get api_settlements_path(state: "completed"), headers: api_headers
    end

    assert_response :success
    ids = response.parsed_body["settlements"].map { |entry| entry["id"] }
    assert_not_includes ids, settlement.id
    assert_not_includes ids, other.id
  end

  test "complete transitions the settlement and refuses a second attempt" do
    settlement = create_settlement

    with_api_token do
      post complete_api_settlement_path(settlement), headers: api_headers
      assert_response :success
      assert_equal "completed", response.parsed_body["settlement"]["state"]

      post complete_api_settlement_path(settlement), headers: api_headers
    end

    assert_response :unprocessable_entity
    assert_equal "invalid_transition", response.parsed_body["error"]
    assert settlement.reload.completed?
  end

  test "send_email delivers the settlement mail once" do
    settlement = create_settlement

    assert_enqueued_emails 1 do
      with_api_token do
        post send_email_api_settlement_path(settlement), headers: api_headers
      end
    end

    assert_response :success
    assert_not_nil response.parsed_body["settlement"]["email_sent_at"]
    assert_not_nil settlement.reload.email_sent_at

    assert_no_enqueued_emails do
      with_api_token do
        post send_email_api_settlement_path(settlement), headers: api_headers
      end
    end

    assert_response :unprocessable_entity
    assert_equal "validation_failed", response.parsed_body["error"]
  end

  test "send_email fails for a client without an email address" do
    client = Client.create!(name: "No Mail-#{SecureRandom.hex(4)}")
    settlement = Settlement.create!(client: client, monthly_report: @report, generated_at: Date.current)

    assert_no_enqueued_emails do
      with_api_token do
        post send_email_api_settlement_path(settlement), headers: api_headers
      end
    end

    assert_response :unprocessable_entity
    assert_includes response.parsed_body["message"], "Client must have an email address"
  end

  private

  def create_settlement
    Settlement.create!(client: @client, monthly_report: @report, generated_at: Date.current)
  end
end
