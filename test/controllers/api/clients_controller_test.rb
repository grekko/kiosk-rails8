require "test_helper"

class Api::ClientsControllerTest < ActionDispatch::IntegrationTest
  include ApiHelpers

  test "index lists clients with id, name and email" do
    client = Client.create!(name: "Alice", email: "alice@example.com")

    with_api_token do
      get api_clients_path, headers: api_headers
    end

    assert_response :success
    payload = response.parsed_body["clients"].find { |entry| entry["id"] == client.id }
    assert_equal({ "id" => client.id, "name" => "Alice", "email" => "alice@example.com", "suspended" => false }, payload)
  end

  test "index can be scoped to active clients" do
    active = Client.create!(name: "Active")
    suspended = Client.create!(name: "Suspended", suspended_at: Time.current)

    with_api_token do
      get api_clients_path(active: true), headers: api_headers
    end

    assert_response :success
    ids = response.parsed_body["clients"].map { |entry| entry["id"] }
    assert_includes ids, active.id
    assert_not_includes ids, suspended.id
  end
end
