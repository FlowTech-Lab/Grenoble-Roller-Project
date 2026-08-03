# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

class DiscordWebhookClient
  class DeliveryError < StandardError
    attr_reader :http_code, :response_body, :retry_after

    def initialize(message, http_code: nil, response_body: nil, retry_after: nil)
      super(message)
      @http_code = http_code
      @response_body = response_body
      @retry_after = retry_after
    end

    def rate_limited?
      http_code == 429
    end
  end

  ALLOWED_HOSTS = NotificationChannel::ALLOWED_WEBHOOK_HOSTS

  class << self
    def post!(webhook_url, payload)
      uri = validate_webhook_url!(webhook_url)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = payload.to_json

      response = http_client(uri).request(request)
      handle_response!(response)
      response
    end

    def validate_webhook_url!(webhook_url)
      uri = URI.parse(webhook_url.to_s)
      raise DeliveryError, "Invalid webhook URL" unless uri.is_a?(URI::HTTP)
      raise DeliveryError, "Webhook host not allowed" unless ALLOWED_HOSTS.include?(uri.host.to_s)

      uri
    rescue URI::InvalidURIError
      raise DeliveryError, "Invalid webhook URL"
    end

    private

    def http_client(uri)
      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 5,
        read_timeout: 10
      )
    end

    def handle_response!(response)
      return if response.is_a?(Net::HTTPSuccess)

      retry_after = response["Retry-After"]&.to_f
      body = response.body.to_s.truncate(500)

      raise DeliveryError.new(
        "Discord webhook failed (#{response.code})",
        http_code: response.code.to_i,
        response_body: body,
        retry_after: retry_after
      )
    end
  end
end
