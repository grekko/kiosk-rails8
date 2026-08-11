require "test_helper"
require "socket"

class KioskApi::ClientTest < ActiveSupport::TestCase
  test "requires a token" do
    error = assert_raises(KioskApi::Error) { KioskApi::Client.new(url: "http://example.com", token: nil) }

    assert_match "Set API_TOKEN", error.message
  end

  test "get sends the bearer token and returns the unwrapped payload" do
    body = { clients: [ { id: 1, name: "Alice" } ] }.to_json

    request = serve(body: body) do |url|
      assert_equal [ { "id" => 1, "name" => "Alice" } ], client(url).clients(active: true)
    end

    assert_equal "GET /api/clients?active=true HTTP/1.1", request[:line]
    assert_equal "Bearer test-token", request[:headers]["authorization"]
  end

  test "create_settlement posts the nested settlement payload" do
    body = { settlement: { id: 42 } }.to_json

    request = serve(status: 201, body: body) do |url|
      settlement = client(url).create_settlement(
        client_id: 1, monthly_report_id: 4, generated_at: "2026-01-31",
        positions: [ { drink_id: 7, amount: 3 } ]
      )

      assert_equal 42, settlement["id"]
    end

    assert_equal "POST /api/settlements HTTP/1.1", request[:line]
    assert_equal "application/json", request[:headers]["content-type"]
    assert_equal(
      { "settlement" => {
        "client_id" => 1, "monthly_report_id" => 4, "generated_at" => "2026-01-31",
        "positions" => [ { "drink_id" => 7, "amount" => 3 } ]
      } },
      JSON.parse(request[:body])
    )
  end

  test "member actions hit the nested routes" do
    request = serve(body: { settlement: { id: 42 } }.to_json) do |url|
      client(url).send_settlement_email(42)
    end

    assert_equal "POST /api/settlements/42/send_email HTTP/1.1", request[:line]
  end

  test "monthly report actions hit the nested routes" do
    request = serve(body: { monthly_report: { id: 4, state: "completed" } }.to_json) do |url|
      assert_equal "completed", client(url).complete_monthly_report(4)["state"]
    end

    assert_equal "POST /api/monthly_reports/4/complete HTTP/1.1", request[:line]

    request = serve(body: { monthly_reports: [] }.to_json) do |url|
      client(url).monthly_reports(state: "draft")
    end

    assert_equal "GET /api/monthly_reports?state=draft HTTP/1.1", request[:line]
  end

  test "delete_position tolerates an empty response body" do
    request = serve(status: 204, body: "") do |url|
      assert client(url).delete_position(42, 91)
    end

    assert_equal "DELETE /api/settlements/42/positions/91 HTTP/1.1", request[:line]
  end

  test "an error response is raised with status and error code" do
    body = { error: "validation_failed", message: "Client must have an email address" }.to_json

    error = nil
    serve(status: 422, body: body) do |url|
      error = assert_raises(KioskApi::RequestError) { client(url).send_settlement_email(42) }
    end

    assert_equal 422, error.status
    assert_equal "validation_failed", error.code
    assert_match "Client must have an email address", error.message
  end

  private

  def client(url)
    KioskApi::Client.new(url: url, token: "test-token")
  end

  # Serves exactly one request from a throwaway localhost server and returns
  # what the client sent, so the request shape can be asserted on.
  def serve(status: 200, body: "{}")
    server = TCPServer.new("127.0.0.1", 0)
    request = {}

    handler = Thread.new do
      socket = server.accept
      request[:line] = socket.gets.to_s.strip
      request[:headers] = read_headers(socket)
      length = request[:headers]["content-length"].to_i
      request[:body] = length.positive? ? socket.read(length) : nil

      socket.print("HTTP/1.1 #{status}\r\nContent-Type: application/json\r\n" \
                   "Content-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}")
      socket.close
    end

    yield "http://127.0.0.1:#{server.addr[1]}"
    handler.join(2)
    request
  ensure
    handler&.kill
    server&.close
  end

  def read_headers(socket)
    headers = {}

    while (line = socket.gets) && line != "\r\n"
      key, value = line.split(":", 2)
      headers[key.to_s.downcase] = value.to_s.strip
    end

    headers
  end
end
