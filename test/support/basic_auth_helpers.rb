module BasicAuthHelpers
  USERNAME = "kiosk".freeze
  PASSWORD = "test-password".freeze
  HEADERS = {
    "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(USERNAME, PASSWORD)
  }.freeze
end

# The controller reads the login from the Rails credentials, which are not
# available in tests — answer with the fixed test login instead.
ApplicationController.define_singleton_method(:basic_auth_credentials) do
  [ BasicAuthHelpers::USERNAME, BasicAuthHelpers::PASSWORD ]
end
