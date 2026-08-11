module ApiHelpers
  API_TOKEN = "test-api-token".freeze

  def api_headers
    { "HTTP_AUTHORIZATION" => "Bearer #{API_TOKEN}" }
  end

  # The controller reads the token from the Rails credentials, which are not
  # available in tests — swap the lookup for the duration of the block.
  def with_api_token(token = API_TOKEN)
    original = Api::BaseController.method(:api_token)
    Api::BaseController.define_singleton_method(:api_token) { token }

    yield
  ensure
    Api::BaseController.define_singleton_method(:api_token, original)
  end
end
