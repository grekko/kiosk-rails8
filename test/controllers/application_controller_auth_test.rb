require "test_helper"

class ApplicationControllerAuthTest < ActionDispatch::IntegrationTest
  USERNAME = "kiosk".freeze
  PASSWORD = "test-password".freeze
  BASIC_AUTH_HEADER = {
    "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(USERNAME, PASSWORD)
  }.freeze

  test "development and test need no login" do
    assert_not ApplicationController.basic_auth_required?

    get root_path
    assert_response :success
  end

  class WithLoginTest < ActionDispatch::IntegrationTest
    # Turn the login on as in production, with a fixed test login instead of
    # the Rails credentials.
    setup do
      @required = ApplicationController.method(:basic_auth_required?)
      @credentials = ApplicationController.method(:basic_auth_credentials)
      ApplicationController.define_singleton_method(:basic_auth_required?) { true }
      ApplicationController.define_singleton_method(:basic_auth_credentials) { [ USERNAME, PASSWORD ] }
    end

    teardown do
      ApplicationController.define_singleton_method(:basic_auth_required?, @required)
      ApplicationController.define_singleton_method(:basic_auth_credentials, @credentials)
    end

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
      ApplicationController.define_singleton_method(:basic_auth_credentials) { nil }

      get root_path, headers: BASIC_AUTH_HEADER
      assert_response :unauthorized
    end

    test "tampered cookie value is rejected" do
      cookies[ApplicationController::AUTH_COOKIE_NAME] = "kiosk"

      get root_path
      assert_response :unauthorized
    end
  end
end
