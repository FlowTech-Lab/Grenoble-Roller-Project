require "rails_helper"

RSpec.describe MembershipMailer, type: :mailer do
  describe "activated" do
    let(:mail) { MembershipMailer.activated }

    it "renders the headers" do
      expect(mail.subject).to eq("Activated")
      expect(mail.to).to eq([ "to@example.org" ])
      expect(mail.from).to eq([ "from@example.com" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

  describe "expired" do
    let(:mail) { MembershipMailer.expired }

    it "renders the headers" do
      expect(mail.subject).to eq("Expired")
      expect(mail.to).to eq([ "to@example.org" ])
      expect(mail.from).to eq([ "from@example.com" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

  describe "renewal_reminder" do
    let(:mail) { MembershipMailer.renewal_reminder }

    it "renders the headers" do
      expect(mail.subject).to eq("Renewal reminder")
      expect(mail.to).to eq([ "to@example.org" ])
      expect(mail.from).to eq([ "from@example.com" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

  describe "payment_failed" do
    let(:mail) { MembershipMailer.payment_failed }

    it "renders the headers" do
      expect(mail.subject).to eq("Payment failed")
      expect(mail.to).to eq([ "to@example.org" ])
      expect(mail.from).to eq([ "from@example.com" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end
end
