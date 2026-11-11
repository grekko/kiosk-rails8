require "test_helper"

class SettlementPricesControllerTest < ActionDispatch::IntegrationTest
  test "index lists active prices only" do
    active = create_price(price_in_cents: 120)
    inactive = create_price(price_in_cents: 130)
    inactive.deactivate

    get settlement_prices_path

    assert_response :success
    assert_select "#settlements", text: /#{active.drink.name}/
    assert_select "#settlements", text: /#{inactive.drink.name}/, count: 0
  end

  test "new renders the form" do
    get new_settlement_price_path

    assert_response :success
  end

  test "edit renders the form" do
    price = create_price

    get edit_settlement_price_path(price)

    assert_response :success
  end

  test "create saves the price and redirects to the list" do
    drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 150)

    assert_difference -> { SettlementPrice.count }, 1 do
      post settlement_prices_path, params: { settlement_price: { drink_id: drink.id, price_in_cents: 120, valid_from: "2026-01-01" } }
    end

    assert_redirected_to settlement_prices_path
    price = drink.settlement_prices.sole
    assert_equal 120, price.price_in_cents
    assert_equal Date.new(2026, 1, 1), price.valid_from.to_date
  end

  test "create without a price does not save" do
    drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 150)

    assert_no_difference -> { SettlementPrice.count } do
      post settlement_prices_path, params: { settlement_price: { drink_id: drink.id, price_in_cents: "", valid_from: "2026-01-01" } }
    end

    assert_response :unprocessable_entity
  end

  test "update changes the price" do
    price = create_price(price_in_cents: 120)

    patch settlement_price_path(price), params: { settlement_price: { price_in_cents: 140 } }

    assert_redirected_to settlement_prices_path
    assert_equal 140, price.reload.price_in_cents
  end

  test "update without a price does not save" do
    price = create_price(price_in_cents: 120)

    patch settlement_price_path(price), params: { settlement_price: { price_in_cents: "" } }

    assert_response :unprocessable_entity
    assert_equal 120, price.reload.price_in_cents
  end

  test "deactivate sets deactivated_at" do
    price = create_price

    patch deactivate_settlement_price_path(price)

    assert_redirected_to settlement_prices_path
    assert_not_nil price.reload.deactivated_at
  end

  private

  def create_price(price_in_cents: 120)
    drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 150)
    SettlementPrice.create!(drink:, price_in_cents:, valid_from: Date.new(2026, 1, 1))
  end
end
