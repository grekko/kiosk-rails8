require "json"
require "net/http"
require "uri"

# Ruby client for the Kiosk JSON API (see docs/api.md).
#
#   client = KioskApi::Client.new
#   client.clients(active: true)
#   settlement = client.create_settlement(client_id: 1, monthly_report_id: 4,
#                                         generated_at: "2026-01-31",
#                                         positions: [ { drink_id: 7, amount: 3 } ])
#   client.complete_settlement(settlement["id"])
#   client.send_settlement_email(settlement["id"])
#
# The token comes from ENV["API_TOKEN"], the host from ENV["KIOSK_API_URL"]
# (defaults to production).
module KioskApi
  class Client
    DEFAULT_URL = "https://kiosk.grekko.de".freeze

    def initialize(url: ENV["KIOSK_API_URL"], token: ENV["API_TOKEN"])
      @token = token.to_s
      raise Error, "No API token. Set API_TOKEN (see docs/api.md)." if @token.empty?

      url = DEFAULT_URL if url.to_s.empty?
      @base_uri = URI.parse("#{url.chomp("/")}/api/")
    end

    def clients(active: nil)
      get("clients", active: active).fetch("clients")
    end

    def drinks
      get("drinks").fetch("drinks")
    end

    def monthly_reports
      get("monthly_reports").fetch("monthly_reports")
    end

    def settlements(client_id: nil, monthly_report_id: nil, state: nil)
      get("settlements", client_id: client_id, monthly_report_id: monthly_report_id, state: state)
        .fetch("settlements")
    end

    def settlement(id)
      get("settlements/#{id}").fetch("settlement")
    end

    # positions: [ { drink_id:, amount: }, … ]
    def create_settlement(client_id:, monthly_report_id:, generated_at:, positions: [])
      body = {
        client_id: client_id,
        monthly_report_id: monthly_report_id,
        generated_at: generated_at,
        positions: positions
      }

      post("settlements", settlement: body).fetch("settlement")
    end

    # Updatable: client_id, monthly_report_id, generated_at, paid_at
    def update_settlement(id, **attributes)
      patch("settlements/#{id}", settlement: attributes).fetch("settlement")
    end

    def complete_settlement(id)
      post("settlements/#{id}/complete").fetch("settlement")
    end

    def send_settlement_email(id)
      post("settlements/#{id}/send_email").fetch("settlement")
    end

    def add_position(settlement_id, drink_id:, amount:)
      post("settlements/#{settlement_id}/positions", position: { drink_id: drink_id, amount: amount })
        .fetch("position")
    end

    def update_position(settlement_id, position_id, **attributes)
      patch("settlements/#{settlement_id}/positions/#{position_id}", position: attributes).fetch("position")
    end

    def delete_position(settlement_id, position_id)
      delete("settlements/#{settlement_id}/positions/#{position_id}")
      true
    end

    private

    def get(path, query = {})
      request(Net::HTTP::Get, path, query: query)
    end

    def post(path, body = nil)
      request(Net::HTTP::Post, path, body: body)
    end

    def patch(path, body)
      request(Net::HTTP::Patch, path, body: body)
    end

    def delete(path)
      request(Net::HTTP::Delete, path)
    end

    def request(type, path, query: {}, body: nil)
      uri = URI.join(@base_uri, path)
      params = query.compact
      uri.query = URI.encode_www_form(params) if params.any?

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(build_request(type, uri, body))
      end

      parsed = response.body.to_s.empty? ? nil : JSON.parse(response.body)
      raise RequestError.new(response.code.to_i, parsed || response.body) unless response.is_a?(Net::HTTPSuccess)

      parsed
    end

    def build_request(type, uri, body)
      request = type.new(uri)
      request["Authorization"] = "Bearer #{@token}"
      request["Accept"] = "application/json"

      if body
        request["Content-Type"] = "application/json"
        request.body = JSON.generate(body)
      end

      request
    end
  end
end
