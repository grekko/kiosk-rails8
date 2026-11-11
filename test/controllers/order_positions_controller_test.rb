require "test_helper"

class OrderPositionsControllerTest < ActionDispatch::IntegrationTest
  AUTH = BasicAuthHelpers::HEADERS

  setup do
    @order = Order.create!(ordered_at: Time.current)
    @drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 150)
  end

  test "create adds a position and redirects to the order" do
    assert_difference -> { @order.positions.count }, 1 do
      post order_positions_path(@order), params: { order_position: valid_params }, headers: AUTH
    end

    assert_redirected_to edit_order_path(@order)
    position = @order.positions.last
    assert_equal @drink, position.drink
    assert_equal 20, position.amount
    assert_equal 2400, position.price_in_cents
    assert_equal 300, position.deposit_in_cents
  end

  test "create without a price does not save and shows the order with the error" do
    assert_no_difference -> { OrderPosition.count } do
      post order_positions_path(@order), params: { order_position: valid_params.merge(price_in_cents: "") }, headers: AUTH
    end

    assert_response :unprocessable_entity
    assert_select "form[action=?]", order_positions_path(@order) do
      assert_select ".error", text: /can't be blank/
    end
  end

  test "edit renders the form" do
    position = create_position

    get edit_order_position_path(@order, position), headers: AUTH

    assert_response :success
    assert_select "form[action=?]", order_position_path(@order, position)
  end

  test "edit refuses a position of another order" do
    position = create_position
    other = Order.create!(ordered_at: Time.current)

    get edit_order_position_path(other, position), headers: AUTH

    assert_response :not_found
  end

  test "update changes the position and redirects to the order" do
    position = create_position

    patch order_position_path(@order, position), params: { order_position: { amount: "10", price_in_cents: "1200" } }, headers: AUTH

    assert_redirected_to edit_order_path(@order)
    position.reload
    assert_equal 10, position.amount
    assert_equal 1200, position.price_in_cents
  end

  test "update with a deposit that is no number does not save" do
    position = create_position

    patch order_position_path(@order, position), params: { order_position: { deposit_in_cents: "abc" } }, headers: AUTH

    assert_response :unprocessable_entity
    assert_equal 300, position.reload.deposit_in_cents
  end

  private

  def valid_params
    { drink_id: @drink.id, amount: "20", price_in_cents: "2400", deposit_in_cents: "300" }
  end

  def create_position
    @order.positions.create!(drink: @drink, **valid_params.except(:drink_id))
  end
end
