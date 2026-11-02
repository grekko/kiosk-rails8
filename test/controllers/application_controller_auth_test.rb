require "test_helper"

class ApplicationControllerAuthTest < ActionDispatch::IntegrationTest
  BASIC_AUTH_HEADER = BasicAuthHelpers::HEADERS

  test "request without credentials is challenged" do
    get root_path
    assert_response :unauthorized
  end

  test "valid basic auth sets a signed kiosk_auth cookie" do
    get root_path, headers: BASIC_AUTH_HEADER
    assert_response :success

    jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
    signed_value = jar.signed[ApplicationController::AUTH_COOKIE_NAME]
    assert_equal ApplicationController::AUTH_COOKIE_VALUE, signed_value
  end

  test "subsequent request with only the cookie bypasses basic auth" do
    get root_path, headers: BASIC_AUTH_HEADER
    assert_response :success

    get root_path
    assert_response :success
  end

  test "without a configured login every basic auth attempt is rejected" do
    original = ApplicationController.method(:basic_auth_credentials)
    ApplicationController.define_singleton_method(:basic_auth_credentials) { nil }

    get root_path, headers: BASIC_AUTH_HEADER
    assert_response :unauthorized
  ensure
    ApplicationController.define_singleton_method(:basic_auth_credentials, original)
  end

  test "tampered cookie value is rejected" do
    cookies[ApplicationController::AUTH_COOKIE_NAME] = "kiosk"

    get root_path
    assert_response :unauthorized
  end
end
