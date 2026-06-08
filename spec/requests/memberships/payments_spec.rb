# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Memberships::Payments", type: :request do
  include RequestAuthenticationHelper
  include TestDataHelper
  include ActiveSupport::Testing::TimeHelpers

  let!(:role) { ensure_role(code: "USER", name: "Utilisateur", level: 10) }
  let!(:user) { create_user(role: role) }

  context "when UNIFIED_CART_ENABLED is true" do
    around do |example|
      with_unified_cart_enabled { example.run }
    end

    describe "POST /memberships/:membership_id/payments" do
      let!(:membership) { create(:membership, :pending, :with_health_questionnaire, user: user) }

      it "redirects to cart with deprecation notice" do
        login_user(user)
        allow(HelloassoService).to receive(:create_membership_checkout_intent)

        post membership_payments_path(membership)

        expect(response).to redirect_to(cart_path)
        expect(flash[:notice]).to include("Adhésion ajoutée au panier")
        expect(HelloassoService).not_to have_received(:create_membership_checkout_intent)
        expect(CartLineService.membership_in_cart?(user, membership)).to be(true)
      end

      it "corrects wrong season before adding to cart" do
        travel_to Date.new(2026, 6, 5) do
          membership.update!(
            season: "2026-2027",
            start_date: Date.new(2026, 9, 1),
            end_date: Date.new(2027, 8, 31)
          )
          login_user(user)
          allow(HelloassoService).to receive(:create_membership_checkout_intent)

          post membership_payments_path(membership)

          expect(response).to redirect_to(cart_path)
          expect(flash[:notice]).to include("Adhésion ajoutée au panier")
          expect(membership.reload.season).to eq("2025-2026")
          line = user.cart_lines.membership.find_by(reference: membership)
          expect(line.label).to include("2025-2026")
        end
      end

      it "updates cart line when membership was already in cart on wrong season" do
        travel_to Date.new(2026, 6, 5) do
          membership.update!(
            season: "2026-2027",
            start_date: Date.new(2026, 9, 1),
            end_date: Date.new(2027, 8, 31)
          )
          create(
            :cart_line,
            :membership,
            user: user,
            reference: membership,
            label: "Cotisation — Saison 2026-2027",
            metadata: { "season" => "2026-2027" }
          )
          login_user(user)
          allow(HelloassoService).to receive(:create_membership_checkout_intent)

          post membership_payments_path(membership)

          expect(response).to redirect_to(cart_path)
          expect(flash[:notice]).to include("Adhésion corrigée pour la saison 2025-2026")
          expect(membership.reload.season).to eq("2025-2026")
        end
      end

      it "shows already-in-cart message when season is already aligned" do
        travel_to Date.new(2026, 6, 5) do
          membership.update!(
            season: "2025-2026",
            start_date: Date.new(2025, 9, 1),
            end_date: Date.new(2026, 8, 31)
          )
          CartLineService.add_membership!(user, membership: membership)
          login_user(user)
          allow(HelloassoService).to receive(:create_membership_checkout_intent)

          post membership_payments_path(membership)

          expect(response).to redirect_to(cart_path)
          expect(flash[:notice]).to eq("Cette adhésion est déjà dans votre panier.")
        end
      end
    end

    describe "POST /memberships/payments/create_multiple" do
      let!(:child1) do
        create(:membership, :child, :pending, :with_health_questionnaire,
               user: user, child_first_name: "Alice", child_last_name: "Test")
      end
      let!(:child2) do
        create(:membership, :child, :pending, :with_health_questionnaire,
               user: user, child_first_name: "Bob", child_last_name: "Test")
      end

      it "redirects to cart" do
        login_user(user)
        allow(HelloassoService).to receive(:create_multiple_memberships_checkout_intent)

        post create_multiple_payments_memberships_path, params: { membership_ids: [ child1.id, child2.id ] }

        expect(response).to redirect_to(cart_path)
        expect(flash[:notice]).to include("Adhésions ajoutées au panier")
        expect(HelloassoService).not_to have_received(:create_multiple_memberships_checkout_intent)
        expect(user.cart_lines.membership.count).to eq(2)
      end
    end
  end
end
