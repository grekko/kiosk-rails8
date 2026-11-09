require "test_helper"

class Api::SettlementPositionsControllerTest < ActionDispatch::IntegrationTest
  include ApiHelpers

  setup do
    @client = Client.create!(name: "Alice-#{SecureRandom.hex(4)}")
    @report = MonthlyReport.create!(title: "January")
    @drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 120)
    @settlement = Settlement.create!(client: @client, monthly_report: @report, generated_at: Date.current)
  end

  test "create prices the position from the drink price" do
    with_api_token do
      post api_settlement_positions_path(@settlement),
           params: { position: { drink_id: @drink.id, amount: 2 } },
           headers: api_headers, as: :json
    end

    assert_response :created
    position = response.parsed_body["position"]
    assert_equal 240, position["price_in_cents"]
    assert_equal @drink.name, position["drink_name"]
    assert_equal 240, @settlement.reload.price_in_cents
  end

  test "update changes the amount" do
    position = @settlement.positions.create!(drink: @drink, amount: 1)

    with_api_token do
      patch api_settlement_position_path(@settlement, position),
            params: { position: { amount: 5 } },
            headers: api_headers, as: :json
    end

    assert_response :success
    assert_equal 5, position.reload.amount
    assert_equal 600, position.price_in_cents
    assert_equal 600, @settlement.reload.price_in_cents
  end

  test "destroy removes the position" do
    position = @settlement.positions.create!(drink: @drink, amount: 1)

    with_api_token do
      delete api_settlement_position_path(@settlement, position), headers: api_headers
    end

    assert_response :no_content
    assert_equal 0, @settlement.positions.count
  end

  test "positions of another settlement are not reachable" do
    other = Settlement.create!(client: @client, monthly_report: @report, generated_at: Date.current)
    position = other.positions.create!(drink: @drink, amount: 1)

    with_api_token do
      delete api_settlement_position_path(@settlement, position), headers: api_headers
    end

    assert_response :not_found
    assert position.reload.persisted?
  end

  test "create, update and destroy are refused on a completed settlement" do
    position = @settlement.positions.create!(drink: @drink, amount: 1)
    @settlement.complete!

    with_api_token do
      post api_settlement_positions_path(@settlement), params: { position: { drink_id: @drink.id, amount: 2 } },
                                                      headers: api_headers, as: :json
      assert_refused

      patch api_settlement_position_path(@settlement, position), params: { position: { amount: 5 } },
                                                                 headers: api_headers, as: :json
      assert_refused

      delete api_settlement_position_path(@settlement, position), headers: api_headers
      assert_refused
    end

    assert_equal [ 1 ], @settlement.positions.reload.map(&:amount)
  end

  private

  def assert_refused
    assert_response :unprocessable_entity
    assert_equal "validation_failed", response.parsed_body["error"]
    assert_equal SettlementPosition::LOCKED_MESSAGE, response.parsed_body["message"]
  end
end
