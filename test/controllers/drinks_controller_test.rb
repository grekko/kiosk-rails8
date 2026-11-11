require "test_helper"

class DrinksControllerTest < ActionDispatch::IntegrationTest
  test "index lists drinks" do
    drink = create_drink

    get drinks_path

    assert_response :success
    assert_select "#drinks", text: /#{drink.name}/
  end

  test "new renders the form" do
    get new_drink_path

    assert_response :success
  end

  test "edit renders the form" do
    drink = create_drink

    get edit_drink_path(drink)

    assert_response :success
    assert_select "input[name=?][value=?]", "drink[name]", drink.name
  end

  test "create saves a drink and redirects to the list" do
    assert_difference -> { Drink.count }, 1 do
      post drinks_path, params: { drink: { name: "Pils", price_in_cents: "150" } }
    end

    assert_redirected_to drinks_path
    assert_equal 150, Drink.last.price_in_cents
  end

  test "create without a name does not save" do
    assert_no_difference -> { Drink.count } do
      post drinks_path, params: { drink: { name: "", price_in_cents: "150" } }
    end

    assert_response :unprocessable_entity
  end

  test "create with a price that is no number does not save" do
    assert_no_difference -> { Drink.count } do
      post drinks_path, params: { drink: { name: "Pils", price_in_cents: "abc" } }
    end

    assert_response :unprocessable_entity
  end

  test "update changes the drink" do
    drink = create_drink

    patch drink_path(drink), params: { drink: { name: "Helles", price_in_cents: "180" } }

    assert_redirected_to drinks_path
    drink.reload
    assert_equal "Helles", drink.name
    assert_equal 180, drink.price_in_cents
  end

  test "update without a price does not save" do
    drink = create_drink

    patch drink_path(drink), params: { drink: { price_in_cents: "" } }

    assert_response :unprocessable_entity
    assert_equal 150, drink.reload.price_in_cents
  end

  private

  def create_drink
    Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 150)
  end
end
