# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Memberships::Payments", type: :request do
  include RequestAuthenticationHelper
  include TestDataHelper

  let(:role) { ensure_role(code: "USER", name: "Utilisateur", level: 10) }
  let(:user) { create_user(role: role) }

  context "when UNIFIED_CART_ENABLED is true" do
    around do |example|
      with_unified_cart_enabled { example.run }
    end

    describe "POST /memberships/:membership_id/payments" do
      let(:membership) { create(:membership, :pending, :with_health_questionnaire, user: user) }

      it "redirects to cart with deprecation notice" do
        login_user(user)
        allow(HelloassoService).to receive(:create_membership_checkout_intent)

        post membership_payments_path(membership)

        expect(response).to redirect_to(cart_path)
        expect(flash[:notice]).to include("Adhésion ajoutée au panier")
        expect(HelloassoService).not_to have_received(:create_membership_checkout_intent)
        expect(CartLineService.membership_in_cart?(user, membership)).to be(true)
      end
    end

    describe "POST /memberships/payments/create_multiple" do
      let(:child1) { create(:membership, :child, :pending, :with_health_questionnaire, user: user) }
      let(:child2) { create(:membership, :child, :pending, :with_health_questionnaire, user: user) }

      it "redirects to cart" do
        login_user(user)
        allow(HelloassoService).to receive(:create_multiple_memberships_checkout_intent)

        post create_multiple_payments_memberships_path, params: { membership_ids: [ child1.id, child2.id ] }

        expect(response).to redirect_to(cart_path)
        expect(flash[:notice]).to include("Adhésions ajoutées au panier")
        expect(HelloassoService).not_to have_received(:create_multiple_memberships_checkout_intent)
        expect(CartLine.membership.count).to eq(2)
      end
    end
  end
end
