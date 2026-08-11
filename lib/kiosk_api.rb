# Ruby client for the Kiosk JSON API — see KioskApi::Client and docs/api.md.
module KioskApi
  class Error < StandardError; end

  # Raised for any non-2xx response. `code` is the API's machine-readable error
  # key (e.g. "validation_failed"), `body` the parsed response.
  class RequestError < Error
    attr_reader :status, :code, :body

    def initialize(status, body)
      @status = status
      @body = body
      @code = body["error"] if body.is_a?(Hash)

      super("#{status} #{code || "request_failed"}: #{body.is_a?(Hash) ? body["message"] : body}")
    end
  end
end
