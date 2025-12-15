require "rails_helper"

RSpec.describe MembershipMailer, type: :mailer do
  let!(:user_role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let!(:user) { create(:user, role: user_role, email: 'member@example.com') }
  let!(:membership) { create(:membership, user: user, season: '2025-2026') }
  
  describe "activated" do
    let(:mail) { MembershipMailer.activated(membership) }

    it "renders the headers" do
      expect(mail.subject).to include("Adhésion Saison #{membership.season}")
      expect(mail.subject).to include("Bienvenue")
      expect(mail.to).to eq([ user.email ])
    end

    it "renders the body" do
      decoded_body = mail.body.parts.any? ? mail.body.parts.map(&:decoded).join : mail.body.decoded
      expect(decoded_body).to include(membership.season).or include("adhésion")
    end
  end

  describe "expired" do
    let(:mail) { MembershipMailer.expired(membership) }

    it "renders the headers" do
      expect(mail.subject).to include("Adhésion Saison #{membership.season}")
      expect(mail.subject).to include("Expirée")
      expect(mail.to).to eq([ user.email ])
    end

    it "renders the body" do
      decoded_body = mail.body.parts.any? ? mail.body.parts.map(&:decoded).join : mail.body.decoded
      expect(decoded_body).to include(membership.season).or include("expir")
    end
  end

  describe "renewal_reminder" do
    let(:mail) { MembershipMailer.renewal_reminder(membership) }

    it "renders the headers" do
      expect(mail.subject).to include("Renouvellement")
      expect(mail.subject).to include("30 jours")
      expect(mail.to).to eq([ user.email ])
    end

    it "renders the body" do
      decoded_body = mail.body.parts.any? ? mail.body.parts.map(&:decoded).join : mail.body.decoded
      expect(decoded_body).to include("renouvel").or include("30")
    end
  end

  describe "payment_failed" do
    let(:mail) { MembershipMailer.payment_failed(membership) }

    it "renders the headers" do
      expect(mail.subject).to include("Paiement")
      expect(mail.subject).to include("Échec")
      expect(mail.to).to eq([ user.email ])
    end

    it "renders the body" do
      decoded_body = mail.body.parts.any? ? mail.body.parts.map(&:decoded).join : mail.body.decoded
      expect(decoded_body).to include("paiement").or include("échec")
    end
  end
end
