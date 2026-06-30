# frozen_string_literal: true

require "rails_helper"

RSpec.describe HelloassoService, ".fetch_and_update_payment discord notifications" do
  let(:helloasso_creds) do
    {
      organization_slug: "grenoble-roller",
      environment: "sandbox",
      client_id: "cid",
      client_secret: "secret"
    }
  end

  before do
    allow(Rails.application).to receive(:credentials).and_return(double(helloasso: helloasso_creds))
    allow(described_class).to receive(:access_token).and_return("token")
    allow_discord_notifications!
    allow(NotificationDispatchService).to receive(:activated_memberships).and_return(Membership.none)
    allow(NotificationDispatchService).to receive(:fulfilled_attendances).and_return(Attendance.none)
  end

  context "when payment transitions to succeeded" do
    it "dispatches payment notifications exactly once" do
      payment = create(:payment, provider: "helloasso", status: "pending", provider_payment_id: "intent_discord")
      order = create(:order, payment: payment, status: "pending", total_cents: 3400)
      channel = create(:notification_channel)
      create(:notification_subscription, notification_channel: channel, event_key: "order.paid", enabled: true)

      allow(described_class).to receive(:fetch_checkout_intent).and_return({ "order" => { "id" => "ha_order_discord" } })
      allow(described_class).to receive(:fetch_helloasso_order).and_return({ "state" => "Confirmed" })

      expect(NotificationDispatchService).to receive(:dispatch_payment_succeeded!).once.and_call_original

      described_class.fetch_and_update_payment(payment)
      expect(order.reload.status).to eq("paid")

      expect(NotificationDispatchService).not_to receive(:dispatch_payment_succeeded!)
      described_class.fetch_and_update_payment(payment.reload)
    end

    it "does not dispatch when payment stays pending" do
      payment = create(:payment, provider: "helloasso", status: "pending", provider_payment_id: "intent_still_pending")
      create(:order, payment: payment, status: "pending")

      allow(described_class).to receive(:fetch_checkout_intent).and_return({})

      expect(NotificationDispatchService).not_to receive(:dispatch_payment_succeeded!)
      described_class.fetch_and_update_payment(payment)
    end
  end
end
