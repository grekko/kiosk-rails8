require "test_helper"

class SettlementPositionsControllerTest < ActionDispatch::IntegrationTest
  AUTH = BasicAuthHelpers::HEADERS

  test "create prices the position from the settlement price valid on the settlement date" do
    settlement = create_settlement(generated_at: Date.new(2026, 1, 31))
    drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 150)
    SettlementPrice.create!(drink:, price_in_cents: 120, valid_from: Date.new(2026, 1, 1))
    SettlementPrice.create!(drink:, price_in_cents: 999, valid_from: Date.new(2026, 2, 1))

    assert_difference -> { settlement.positions.count }, 1 do
      post settlement_positions_path(settlement), params: { settlement_position: { drink_id: drink.id, amount: 3 } }, headers: AUTH
    end

    assert_redirected_to edit_settlement_path(settlement)
    assert_equal 3 * 120, settlement.positions.sole.price_in_cents
  end

  test "create falls back to the drink's default price without a settlement price" do
    settlement = create_settlement
    drink = Drink.create!(name: "Mate-#{SecureRandom.hex(4)}", price_in_cents: 220)

    post settlement_positions_path(settlement), params: { settlement_position: { drink_id: drink.id, amount: 2 } }, headers: AUTH

    assert_redirected_to edit_settlement_path(settlement)
    assert_equal 2 * 220, settlement.positions.sole.price_in_cents
  end

  test "create ignores a price sent by the client" do
    settlement = create_settlement
    drink = Drink.create!(name: "Mate-#{SecureRandom.hex(4)}", price_in_cents: 220)

    post settlement_positions_path(settlement), params: { settlement_position: { drink_id: drink.id, amount: 1, price_in_cents: 1 } }, headers: AUTH

    assert_equal 220, settlement.positions.sole.price_in_cents
  end

  test "create without an amount does not save" do
    settlement = create_settlement
    drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 150)

    assert_no_difference -> { SettlementPosition.count } do
      post settlement_positions_path(settlement), params: { settlement_position: { drink_id: drink.id, amount: "" } }, headers: AUTH
    end

    assert_response :unprocessable_entity
  end

  test "edit renders the position form" do
    settlement = create_settlement
    position = create_position(settlement)

    get edit_settlement_position_path(settlement, position), headers: AUTH

    assert_response :success
  end

  test "update re-prices the position for the new amount" do
    settlement = create_settlement
    position = create_position(settlement, amount: 1, price_in_cents: 150)

    patch settlement_position_path(settlement, position), params: { settlement_position: { amount: 4 } }, headers: AUTH

    assert_redirected_to edit_settlement_path(settlement)
    assert_equal 4 * 150, position.reload.price_in_cents
  end

  test "update without an amount does not save" do
    settlement = create_settlement
    position = create_position(settlement, amount: 2)

    patch settlement_position_path(settlement, position), params: { settlement_position: { amount: "" } }, headers: AUTH

    assert_response :unprocessable_entity
    assert_equal 2, position.reload.amount
  end

  test "destroy removes the position" do
    settlement = create_settlement
    position = create_position(settlement)

    assert_difference -> { SettlementPosition.count }, -1 do
      delete settlement_position_path(settlement, position), headers: AUTH
    end

    assert_redirected_to edit_settlement_path(settlement)
  end

  test "create refuses to add a position to a completed settlement" do
    settlement = create_settlement
    settlement.complete!
    drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 150)

    assert_no_difference -> { settlement.positions.count } do
      post settlement_positions_path(settlement), params: { settlement_position: { drink_id: drink.id, amount: 1 } }, headers: AUTH
    end

    assert_refused
  end

  test "update refuses to change a position of a completed settlement" do
    settlement = create_settlement
    position = create_position(settlement, amount: 2)
    settlement.complete!

    patch settlement_position_path(settlement, position), params: { settlement_position: { amount: 5 } }, headers: AUTH

    assert_refused
    assert_equal 2, position.reload.amount
  end

  test "destroy refuses to remove a position of a completed settlement" do
    settlement = create_settlement
    position = create_position(settlement)
    settlement.complete!

    assert_no_difference -> { SettlementPosition.count } do
      delete settlement_position_path(settlement, position), headers: AUTH
    end

    assert_refused
  end

  private

  def assert_refused
    assert_response :unprocessable_entity
    assert_includes response.body, SettlementPosition::LOCKED_MESSAGE
  end

  def create_settlement(generated_at: Date.new(2026, 1, 31))
    Settlement.create!(client: Client.create!(name: "Alice-#{SecureRandom.hex(4)}"), monthly_report: MonthlyReport.create!(title: "Januar 2026"), generated_at:)
  end

  def create_position(settlement, amount: 1, price_in_cents: 150)
    drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents:)
    SettlementPosition.create!(settlement:, drink:, amount:)
  end
end
