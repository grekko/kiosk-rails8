require "test_helper"

class ClientsControllerTest < ActionDispatch::IntegrationTest
  include QueryCountHelpers

  test "index runs the same number of queries for more settlements per client" do
    clients = [ create_client, create_client ]
    clients.each { |client| add_settlements(client, 1) }
    few = count_queries { get clients_path }

    clients.each { |client| add_settlements(client, 3) }
    many = count_queries { get clients_path }

    assert_response :success
    assert_equal few, many
  end

  test "index lists clients" do
    client = create_client

    get clients_path

    assert_response :success
    assert_select "#clients", text: /#{client.name}/
  end

  test "index marks a suspended client" do
    client = create_client
    client.suspend!

    get clients_path

    assert_select "#clients tr.text-muted", text: /#{client.name}.*\(Suspended\)/m
  end

  test "new renders the form" do
    get new_client_path

    assert_response :success
  end

  test "edit renders the form" do
    client = create_client

    get edit_client_path(client)

    assert_response :success
    assert_select "input[name=?][value=?]", "client[name]", client.name
  end

  test "create saves a client and redirects to the list" do
    assert_difference -> { Client.count }, 1 do
      post clients_path, params: { client: { name: "Alice", email: "alice-#{SecureRandom.hex(4)}@example.com" } }
    end

    assert_redirected_to clients_path
    client = Client.last
    assert_equal "Alice", client.name
    assert_not_nil client.access_uuid
  end

  test "create without an email saves a client without one" do
    assert_difference -> { Client.count }, 1 do
      post clients_path, params: { client: { name: "Alice", email: "" } }
    end

    assert_nil Client.last.email
  end

  test "create without a name does not save" do
    assert_no_difference -> { Client.count } do
      post clients_path, params: { client: { name: "", email: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "create with an email another client has does not save" do
    other = create_client(email: "taken-#{SecureRandom.hex(4)}@example.com")

    assert_no_difference -> { Client.count } do
      post clients_path, params: { client: { name: "Alice", email: other.email } }
    end

    assert_response :unprocessable_entity
  end

  test "update changes the client" do
    client = create_client

    patch client_path(client), params: { client: { name: "Bob", email: "bob-#{SecureRandom.hex(4)}@example.com" } }

    assert_redirected_to clients_path
    assert_equal "Bob", client.reload.name
  end

  test "update with a blank name re-renders the form with an error" do
    client = create_client

    patch client_path(client), params: { client: { name: "", email: "" } }

    assert_response :unprocessable_entity
    assert_select "form", text: /can't be blank/
    assert_equal client.name, client.reload.name
  end

  test "update with a blank email clears the email" do
    client = create_client(email: "alice-#{SecureRandom.hex(4)}@example.com")

    patch client_path(client), params: { client: { name: client.name, email: "" } }

    assert_redirected_to clients_path
    assert_nil client.reload.email
  end

  test "update with an email another client has does not save" do
    client = create_client
    other = create_client(email: "taken-#{SecureRandom.hex(4)}@example.com")

    patch client_path(client), params: { client: { email: other.email } }

    assert_response :unprocessable_entity
    assert_nil client.reload.email
  end

  test "suspend marks the client suspended" do
    client = create_client

    patch suspend_client_path(client)

    assert_redirected_to clients_path
    assert client.reload.suspended?
  end

  test "reinstate makes a suspended client active again" do
    client = create_client
    client.suspend!

    patch reinstate_client_path(client)

    assert_redirected_to clients_path
    assert_not client.reload.suspended?
  end

  private

  # One completed (outstanding) and one paid Settlement each time, both with a position.
  def add_settlements(client, count)
    drink = Drink.create!(name: "Beer-#{SecureRandom.hex(4)}", price_in_cents: 150)
    count.times do
      [ false, true ].each do |paid|
        settlement = Settlement.create!(client:, monthly_report: MonthlyReport.create!(title: "January"), generated_at: Date.current)
        settlement.positions.create!(drink:, amount: 2)
        settlement.complete!
        settlement.mark_paid! if paid
      end
    end
  end

  def create_client(email: nil)
    Client.create!(name: "Alice-#{SecureRandom.hex(4)}", email:)
  end
end
