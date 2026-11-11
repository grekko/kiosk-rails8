require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  test "index lists orders" do
    order = Order.create!(ordered_at: Time.zone.local(2026, 1, 15, 10))

    get orders_path

    assert_response :success
    assert_select "#orders a[href=?]", edit_order_path(order)
  end

  test "new renders the form" do
    get new_order_path

    assert_response :success
  end

  test "edit renders the order with its positions" do
    order = Order.create!(ordered_at: Time.current)
    drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 150)
    order.positions.create!(drink:, amount: 20, price_in_cents: 2400, deposit_in_cents: 300)

    get edit_order_path(order)

    assert_response :success
    assert_select "#positions", text: /#{drink.name}/
    assert_select "form[action=?]", order_positions_path(order)
  end

  test "edit shows the attached invoice" do
    order = Order.create!(ordered_at: Time.current)
    order.invoice.attach(io: StringIO.new("%PDF-1.4"), filename: "invoice.pdf", content_type: "application/pdf")

    get edit_order_path(order)

    assert_response :success
    assert_select "embed[type=?]", "application/pdf"
  end

  test "create saves an order and redirects to its edit page" do
    assert_difference -> { Order.count }, 1 do
      post orders_path, params: { order: { ordered_at: "2026-01-15T10:00" } }
    end

    order = Order.last
    assert_redirected_to edit_order_path(order)
    assert_equal Date.new(2026, 1, 15), order.ordered_at.to_date
  end

  test "create attaches the invoice" do
    invoice = Rack::Test::UploadedFile.new(StringIO.new("%PDF-1.4"), "application/pdf", original_filename: "invoice.pdf")

    post orders_path, params: { order: { ordered_at: "2026-01-15T10:00", invoice: } }

    assert Order.last.invoice.attached?
  end

  test "create without a date does not save" do
    assert_no_difference -> { Order.count } do
      post orders_path, params: { order: { ordered_at: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "update changes the order date" do
    order = Order.create!(ordered_at: Time.current)

    patch order_path(order), params: { order: { ordered_at: "2026-02-01T09:00" } }

    assert_redirected_to orders_path
    assert_equal Date.new(2026, 2, 1), order.reload.ordered_at.to_date
  end

  test "update without a date does not save" do
    order = Order.create!(ordered_at: Time.current)

    patch order_path(order), params: { order: { ordered_at: "" } }

    assert_response :unprocessable_entity
    assert_not_nil order.reload.ordered_at
  end
end
