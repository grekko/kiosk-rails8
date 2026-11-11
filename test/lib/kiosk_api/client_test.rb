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

    request = serve(body: { settlement: { id: 42, state: "draft" } }.to_json) do |url|
      assert_equal "draft", client(url).reopen_settlement(42)["state"]
    end

    assert_equal "POST /api/settlements/42/reopen HTTP/1.1", request[:line]
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

  test "defaults to production when no url is set" do
    client = KioskApi::Client.new(url: "", token: "x")

    assert_equal "https://kiosk.grekko.de/api/", client.instance_variable_get(:@base_uri).to_s
  end

  test "a trailing slash on the url does not double the path separator" do
    request = serve(body: { clients: [] }.to_json) do |url|
      client("#{url}/").clients
    end

    assert_equal "GET /api/clients HTTP/1.1", request[:line]
  end

  test "update_position patches the nested position payload" do
    request = serve(body: { position: { id: 91 } }.to_json) do |url|
      client(url).update_position(42, 91, amount: 5)
    end

    assert_equal "PATCH /api/settlements/42/positions/91 HTTP/1.1", request[:line]
    assert_equal({ "position" => { "amount" => 5 } }, JSON.parse(request[:body]))
  end

  test "settlements leaves unset filters out of the query" do
    request = serve(body: { settlements: [] }.to_json) do |url|
      client(url).settlements(client_id: 3)
    end

    assert_equal "GET /api/settlements?client_id=3 HTTP/1.1", request[:line]
  end

  test "update_settlement patches the given attributes" do
    request = serve(body: { settlement: { id: 42 } }.to_json) do |url|
      client(url).update_settlement(42, paid_at: "2026-02-01")
    end

    assert_equal "PATCH /api/settlements/42 HTTP/1.1", request[:line]
    assert_equal({ "settlement" => { "paid_at" => "2026-02-01" } }, JSON.parse(request[:body]))
  end

  test "add_position posts the nested position payload" do
    request = serve(status: 201, body: { position: { id: 91 } }.to_json) do |url|
      assert_equal 91, client(url).add_position(42, drink_id: 7, amount: 3)["id"]
    end

    assert_equal "POST /api/settlements/42/positions HTTP/1.1", request[:line]
    assert_equal({ "position" => { "drink_id" => 7, "amount" => 3 } }, JSON.parse(request[:body]))
  end

  test "monthly_report_image downloads the image without the token" do
    image_request = serve(body: "PNGDATA") do |storage|
      reports = { monthly_reports: [ { id: 4, image_url: "#{storage}/blob/x.png", image_filename: "x.png" } ] }

      serve(body: reports.to_json) do |url|
        assert_equal [ "x.png", "PNGDATA" ], client(url).monthly_report_image(4)
      end
    end

    assert_equal "GET /blob/x.png HTTP/1.1", image_request[:line]
    assert_nil image_request[:headers]["authorization"]
  end

  test "monthly_report_image follows a redirect to the storage service" do
    serve(body: "PNGDATA") do |storage|
      serve(status: 302, body: "", headers: { "Location" => "#{storage}/disk/x.png" }) do |blob|
        reports = { monthly_reports: [ { id: 4, image_url: "#{blob}/blob/x.png", image_filename: "x.png" } ] }

        serve(body: reports.to_json) do |url|
          assert_equal [ "x.png", "PNGDATA" ], client(url).monthly_report_image(4)
        end
      end
    end
  end

  test "monthly_report_image is nil when nothing is attached" do
    serve(body: { monthly_reports: [ { id: 4, image_url: nil } ] }.to_json) do |url|
      assert_nil client(url).monthly_report_image(4)
    end
  end

  test "monthly_report_image raises for an unknown report" do
    serve(body: { monthly_reports: [] }.to_json) do |url|
      error = assert_raises(KioskApi::Error) { client(url).monthly_report_image(4) }

      assert_match "No monthly report with id 4", error.message
    end
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
  def serve(status: 200, body: "{}", headers: {})
    server = TCPServer.new("127.0.0.1", 0)
    request = {}

    handler = Thread.new do
      socket = server.accept
      request[:line] = socket.gets.to_s.strip
      request[:headers] = read_headers(socket)
      length = request[:headers]["content-length"].to_i
      request[:body] = length.positive? ? socket.read(length) : nil

      extra = headers.map { |key, value| "#{key}: #{value}\r\n" }.join
      socket.print("HTTP/1.1 #{status}\r\nContent-Type: application/json\r\n#{extra}" \
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
