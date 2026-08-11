require "test_helper"

class Api::AuthenticationTest < ActionDispatch::IntegrationTest
  include ApiHelpers

  test "request without a token is rejected" do
    with_api_token do
      get api_clients_path
    end

    assert_response :unauthorized
    assert_equal "unauthorized", response.parsed_body["error"]
  end

  test "request with a wrong token is rejected" do
    with_api_token do
      get api_clients_path, headers: { "HTTP_AUTHORIZATION" => "Bearer nope" }
    end

    assert_response :unauthorized
  end

  test "request with the configured token is accepted" do
    with_api_token do
      get api_clients_path, headers: api_headers
    end

    assert_response :success
  end

  test "`Token` scheme is accepted as well" do
    with_api_token do
      get api_clients_path, headers: { "HTTP_AUTHORIZATION" => %(Token token="#{ApiHelpers::API_TOKEN}") }
    end

    assert_response :success
  end

  test "requests are refused when no token is configured" do
    with_api_token(nil) do
      get api_clients_path, headers: api_headers
    end

    assert_response :service_unavailable
    assert_equal "api_not_configured", response.parsed_body["error"]
  end
end
