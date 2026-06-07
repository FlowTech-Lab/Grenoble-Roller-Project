# frozen_string_literal: true

require "rails_helper"

RSpec.describe HelloassoService do
  describe ".environment" do
    let(:helloasso_creds) { { environment: "sandbox" } }

    before do
      allow(Rails.application).to receive(:credentials).and_return(
        double(helloasso: helloasso_creds)
      )
      allow(Rails.env).to receive(:staging?).and_return(false)
      allow(Rails.env).to receive(:production?).and_return(production_mode)
    end

    context "when Rails is production, credentials say sandbox, and deploy is not marked production" do
      let(:production_mode) { true }

      before do
        ENV.delete("APP_ENV")
        ENV.delete("DEPLOY_ENV")
        ENV.delete("HELLOASSO_USE_PRODUCTION")
        ENV.delete("HELLOASSO_USE_SANDBOX")
        allow(ActionMailer::Base).to receive(:default_url_options).and_return({ host: "example.com" })
      end

      after do
        ENV.delete("APP_ENV")
        ENV.delete("DEPLOY_ENV")
        ENV.delete("HELLOASSO_USE_PRODUCTION")
        ENV.delete("HELLOASSO_USE_SANDBOX")
      end

      it "uses HelloAsso sandbox API (shared credentials)" do
        expect(described_class.environment).to eq("sandbox")
      end
    end

    context "when Rails is production, credentials say sandbox, and DEPLOY_ENV is production" do
      let(:production_mode) { true }

      before do
        ENV["DEPLOY_ENV"] = "production"
        ENV["APP_ENV"] = "production"
        allow(ActionMailer::Base).to receive(:default_url_options).and_return({ host: "example.com" })
      end

      after do
        ENV.delete("DEPLOY_ENV")
        ENV.delete("APP_ENV")
      end

      it "uses HelloAsso production API" do
        expect(described_class.environment).to eq("production")
      end
    end

    context "when HELLOASSO_USE_PRODUCTION is set" do
      let(:production_mode) { true }

      before do
        ENV["HELLOASSO_USE_PRODUCTION"] = "true"
        allow(ActionMailer::Base).to receive(:default_url_options).and_return({ host: "example.com" })
      end

      after do
        ENV.delete("HELLOASSO_USE_PRODUCTION")
      end

      it "uses HelloAsso production API" do
        expect(described_class.environment).to eq("production")
      end
    end

    context "when Rails is production, credentials omit helloasso.environment, and deploy is not marked production" do
      let(:production_mode) { true }
      let(:helloasso_creds) { {} }

      before do
        ENV.delete("APP_ENV")
        ENV.delete("DEPLOY_ENV")
        allow(ActionMailer::Base).to receive(:default_url_options).and_return({ host: "example.com" })
      end

      after do
        ENV.delete("APP_ENV")
        ENV.delete("DEPLOY_ENV")
      end

      it "defaults to HelloAsso sandbox API" do
        expect(described_class.environment).to eq("sandbox")
      end
    end

    context "when Rails is production, credentials say environment production, and deploy vars are unset" do
      let(:production_mode) { true }
      let(:helloasso_creds) { { environment: "production" } }

      before do
        ENV.delete("APP_ENV")
        ENV.delete("DEPLOY_ENV")
        allow(ActionMailer::Base).to receive(:default_url_options).and_return({ host: "example.com" })
      end

      after do
        ENV.delete("APP_ENV")
        ENV.delete("DEPLOY_ENV")
      end

      it "uses HelloAsso production API (explicit credentials)" do
        expect(described_class.environment).to eq("production")
      end
    end
  end

  describe ".build_unified_checkout_intent_payload" do
    let(:helloasso_creds) { { organization_slug: "grenoble-roller", environment: "sandbox" } }
    let(:checkout) { build(:checkout, :with_mixed_lines, donation_cents: 500, total_cents: 5500) }
    let(:urls) do
      {
        back_url: "https://example.com/back",
        error_url: "https://example.com/error",
        return_url: "https://example.com/return"
      }
    end

    before do
      allow(Rails.application).to receive(:credentials).and_return(double(helloasso: helloasso_creds))
    end

    it "includes product line items in metadata" do
      payload = described_class.build_unified_checkout_intent_payload(checkout, **urls)
      product_items = payload[:metadata][:items].select { |i| i[:lineType] == "product_variant" }

      expect(product_items).not_to be_empty
      expect(product_items.first[:metadata]).to include(sku: "SKU-TSHIRT")
    end

    it "includes membership line items in metadata" do
      payload = described_class.build_unified_checkout_intent_payload(checkout, **urls)
      membership_items = payload[:metadata][:items].select { |i| i[:lineType] == "membership" }

      expect(membership_items).not_to be_empty
      expect(payload[:metadata][:membershipIds]).to include(202)
    end

    it "includes event_registration line items in metadata" do
      payload = described_class.build_unified_checkout_intent_payload(checkout, **urls)
      event_items = payload[:metadata][:items].select { |i| i[:lineType] == "event_registration" }

      expect(event_items).not_to be_empty
      expect(payload[:metadata][:attendanceIds]).to include(303)
    end

    it "adds a Donation line when donation_cents is positive" do
      payload = described_class.build_unified_checkout_intent_payload(checkout, **urls)
      donation_items = payload[:metadata][:items].select { |i| i[:type] == "Donation" }

      expect(donation_items.size).to eq(1)
      expect(donation_items.first[:amount]).to eq(500)
    end

    it "sets totalAmount to subtotal_cents plus donation_cents" do
      payload = described_class.build_unified_checkout_intent_payload(checkout, **urls)

      expect(payload[:totalAmount]).to eq(checkout.subtotal_cents + checkout.donation_cents)
      expect(payload[:initialAmount]).to eq(payload[:totalAmount])
    end

    it "sets containsDonation to true when donation is positive" do
      payload = described_class.build_unified_checkout_intent_payload(checkout, **urls)

      expect(payload[:containsDonation]).to be(true)
    end

    it "sets containsDonation to false when donation is zero" do
      checkout_no_donation = build(:checkout, :with_mixed_lines, donation_cents: 0)
      payload = described_class.build_unified_checkout_intent_payload(checkout_no_donation, **urls)

      expect(payload[:containsDonation]).to be(false)
    end
  end
end

