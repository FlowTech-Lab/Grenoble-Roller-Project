# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscordWebhookClient do
  let(:webhook_url) { DiscordNotificationHelpers::DISCORD_WEBHOOK_URL }
  let(:payload) { { embeds: [ { title: "Test", description: "Hello" } ] } }

  def stub_http_response(response)
    http = instance_double(Net::HTTP)
    allow(Net::HTTP).to receive(:start).and_return(http)
    allow(http).to receive(:request).and_return(response)
    http
  end

  describe ".post!" do
    it "POSTs JSON payload to the webhook URL" do
      response = instance_double(Net::HTTPSuccess, code: "204", body: "")
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      http = stub_http_response(response)
      captured_request = nil
      allow(http).to receive(:request) do |request|
        captured_request = request
        response
      end

      result = described_class.post!(webhook_url, payload)

      expect(result).to eq(response)
      expect(captured_request["Content-Type"]).to eq("application/json")
      expect(JSON.parse(captured_request.body)).to eq(payload.deep_stringify_keys)
    end

    it "raises DeliveryError on non-success response" do
      response = instance_double(Net::HTTPBadRequest, code: "400", body: "Bad Request")
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
      allow(response).to receive(:[]).with("Retry-After").and_return(nil)
      stub_http_response(response)

      expect {
        described_class.post!(webhook_url, payload)
      }.to raise_error(DiscordWebhookClient::DeliveryError) do |error|
        expect(error.http_code).to eq(400)
        expect(error.rate_limited?).to be(false)
      end
    end

    context "when Discord returns 429 rate limit" do
      it "raises DeliveryError with retry_after for job retry" do
        response = instance_double(Net::HTTPTooManyRequests, code: "429", body: '{"retry_after": 1.5}')
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(response).to receive(:[]).with("Retry-After").and_return("1.5")
        stub_http_response(response)

        expect {
          described_class.post!(webhook_url, payload)
        }.to raise_error(DiscordWebhookClient::DeliveryError) do |error|
          expect(error.http_code).to eq(429)
          expect(error.rate_limited?).to be(true)
          expect(error.retry_after).to eq(1.5)
        end
      end
    end
  end

  describe ".validate_webhook_url!" do
    it "rejects disallowed hosts" do
      expect {
        described_class.validate_webhook_url!("https://evil.example.com/hook")
      }.to raise_error(DiscordWebhookClient::DeliveryError, /host not allowed/i)
    end
  end
end
