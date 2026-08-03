# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailLog::Parser do
  subject(:result) { described_class.call(payload) }

  let(:payload) do
    {
      "job_class" => "ActionMailer::MailDeliveryJob",
      "arguments" => [ "UserMailer", "welcome_email", "deliver_now", { "args" => [] } ]
    }
  end

  it "extracts mailer and method from ActiveJob payload" do
    expect(result).to eq(
      mailer: "UserMailer",
      method: "welcome_email",
      args: [ "deliver_now", { "args" => [] } ]
    )
  end

  context "with symbol keys" do
    let(:payload) do
      { arguments: [ "EventMailer", "event_reminder", "deliver_now" ] }
    end

    it "parses successfully" do
      expect(result[:mailer]).to eq("EventMailer")
      expect(result[:method]).to eq("event_reminder")
    end
  end

  context "with JSON string payload" do
    let(:payload) { payload_hash.to_json }
    let(:payload_hash) do
      { "arguments" => [ "DeviseMailer", "confirmation_instructions", "deliver_now" ] }
    end

    it "parses successfully" do
      expect(result[:mailer]).to eq("DeviseMailer")
    end
  end
end
