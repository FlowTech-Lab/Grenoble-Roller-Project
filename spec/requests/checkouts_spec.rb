# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Checkouts", type: :request do
  include RequestAuthenticationHelper

  let(:role) { ensure_role(code: "USER", name: "Utilisateur", level: 10) }
  let!(:user) do
    u = build(:user, role: role)
    u.skip_confirmation!
    u.save!
    u
  end
  let!(:category) { create(:product_category) }
  let!(:product) { create(:product, category: category) }
  let!(:variant) do
    v = create(:product_variant, product: product, stock_qty: 10, is_active: true)
    v.inventory.update!(stock_qty: 10, reserved_qty: 0)
    v.reload
  end

  around do |example|
    with_unified_cart_enabled { example.run }
  end

  def add_product_to_cart!
    CartLineService.add_product!(user: user, variant: variant, quantity: 1)
  end

  describe "GET /checkout" do
    it "requires authentication" do
      get new_checkout_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "lists all cart lines with checkboxes default checked" do
      add_product_to_cart!
      login_user(user)

      get new_checkout_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="cart_line_ids[]"')
      expect(response.body).to include("checked")
    end

    it "renders mobile sticky pay selection footer" do
      add_product_to_cart!
      login_user(user)

      get new_checkout_path

      expect(response.body).to include("checkout-sticky-footer")
      expect(response.body).to include("Payer la sélection")
      expect(response.body).to include("avec HelloAsso")
    end

    it "renders donation section when cart has only memberships" do
      membership = create(:membership, :pending, :with_health_questionnaire, user: user)
      CartLineService.add_membership!(user, membership: membership)
      login_user(user)

      get new_checkout_path
      expect(response.body).to include("don à Grenoble Roller")
    end

    it "renders donation section when cart has only events" do
      creator = create_user
      event = create_event(
        creator_user: creator,
        status: "published",
        payment_required: true,
        price_cents: 500,
        max_participants: 20,
        start_at: 1.week.from_now
      )
      attendance = create(:attendance, user: user, event: event, status: :pending, payment_expires_at: 15.minutes.from_now)
      CartLineService.add_event_registration!(user: user, attendance: attendance, event: event)
      login_user(user)

      get new_checkout_path
      expect(response.body).to include("don à Grenoble Roller")
    end

    it "disables checkbox for expired event lines" do
      creator = create_user
      event = create_event(
        creator_user: creator,
        status: "published",
        payment_required: true,
        price_cents: 500,
        max_participants: 20,
        start_at: 1.week.from_now
      )
      attendance = create(:attendance, user: user, event: event, status: :pending, payment_expires_at: 15.minutes.from_now)
      line = create(:cart_line, :event_registration, user: user, reference: attendance, expires_at: 1.minute.ago)
      login_user(user)

      get new_checkout_path
      expect(response.body).to include("disabled")
      expect(response.body).to include("Expiré")
    end
  end

  describe "POST /checkout" do
    before { login_user(user) }

    it "redirects to HelloAsso with selected lines only" do
      line = add_product_to_cart!
      allow(HelloassoService).to receive(:create_unified_checkout_intent).and_return(
        success: true,
        status: 200,
        body: { "id" => "intent_1", "redirectUrl" => "https://helloasso.com/pay" }
      )

      post checkouts_path, params: { cart_line_ids: [ line.id ], accept_terms: "1", donation_cents: 0 }
      expect(response).to redirect_to("https://helloasso.com/pay")
    end

    it "rejects checkout with zero selected lines" do
      post checkouts_path, params: { cart_line_ids: [], accept_terms: "1" }
      expect(response).to redirect_to(new_checkout_path)
      expect(flash[:alert]).to include("Sélectionnez")
    end

    it "rejects expired lines in selection" do
      creator = create_user
      event = create_event(
        creator_user: creator,
        status: "published",
        payment_required: true,
        price_cents: 500,
        max_participants: 20,
        start_at: 1.week.from_now
      )
      attendance = create(:attendance, user: user, event: event, status: :pending, payment_expires_at: 15.minutes.from_now)
      line = create(:cart_line, :event_registration, user: user, reference: attendance, expires_at: 1.minute.ago)

      post checkouts_path, params: { cart_line_ids: [ line.id ], accept_terms: "1" }
      expect(response).to redirect_to(new_checkout_path)
      expect(flash[:alert]).to include("expiré")
    end

    it "accepts partial selection and preserves other cart lines" do
      line1 = add_product_to_cart!
      variant2 = create(:product_variant, product: product, stock_qty: 5, is_active: true)
      line2 = CartLineService.add_product!(user: user, variant: variant2, quantity: 1)

      allow(HelloassoService).to receive(:create_unified_checkout_intent).and_return(
        success: true,
        status: 200,
        body: { "id" => "intent_2", "redirectUrl" => "https://helloasso.com/pay" }
      )

      post checkouts_path, params: { cart_line_ids: [ line1.id ], accept_terms: "1" }

      expect(CartLine.exists?(line2.id)).to be(true)
    end

    it "includes donation in payment amount" do
      line = add_product_to_cart!
      expect(HelloassoService).to receive(:create_unified_checkout_intent) do |checkout, **_urls|
        expect(checkout.donation_cents).to eq(500)
        expect(checkout.total_cents).to eq(checkout.subtotal_cents + 500)
        { success: true, status: 200, body: { "id" => "intent_3", "redirectUrl" => "https://helloasso.com/pay" } }
      end

      post checkouts_path, params: { cart_line_ids: [ line.id ], accept_terms: "1", donation_cents: 500 }
      expect(response).to redirect_to("https://helloasso.com/pay")
    end

    it "blocks unconfirmed email user" do
      line = add_product_to_cart!
      logout_user
      unconfirmed = create(:user, :unconfirmed, role: role)
      unconfirmed_line = CartLineService.add_product!(user: unconfirmed, variant: variant, quantity: 1)
      login_user(unconfirmed)

      post checkouts_path, params: { cart_line_ids: [ unconfirmed_line.id ], accept_terms: "1" }
      expect(response).to redirect_to(root_path)
    end

    it "requires accept_terms checkbox" do
      line = add_product_to_cart!
      post checkouts_path, params: { cart_line_ids: [ line.id ] }
      expect(response).to redirect_to(new_checkout_path)
      expect(flash[:alert]).to include("conditions générales")
    end
  end

  describe "GET /checkout/:id" do
    it "shows processing state after HelloAsso return" do
      checkout = create(:checkout, :processing, user: user)
      login_user(user)

      get checkout_path(checkout)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Paiement en cours")
    end
  end

  describe "GET /checkout/:id/status" do
    it "returns JSON status for polling" do
      checkout = create(:checkout, :processing, user: user)
      login_user(user)

      get checkout_status_path(checkout), headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["status"]).to eq("processing")
    end
  end

  describe "POST /checkout/:id/check_payment" do
    it "triggers HelloassoService.fetch_and_update_payment" do
      payment = create(:payment, provider: "helloasso", status: "pending")
      checkout = create(:checkout, :processing, user: user, payment: payment)
      login_user(user)

      expect(HelloassoService).to receive(:fetch_and_update_payment).with(payment).and_return(payment)

      post checkout_check_payment_path(checkout)
      expect(response).to redirect_to(checkout_path(checkout))
    end
  end
end
