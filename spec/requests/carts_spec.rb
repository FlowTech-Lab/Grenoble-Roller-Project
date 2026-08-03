# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Carts", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:category) { create(:product_category) }
  let(:product) { create(:product, category: category) }
  let(:variant) do
    v = create(:product_variant, product: product, stock_qty: 10, price_cents: 2000, is_active: true)
    inv = v.inventory || Inventory.create!(product_variant: v, stock_qty: 10, reserved_qty: 0)
    inv.update!(stock_qty: 10, reserved_qty: 0)
    v.reload
  end

  describe "GET /cart" do
    it "requires authentication" do
      get cart_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "lists DB cart lines" do
      login_user(user)
      create(:cart_line, user: user, reference: variant, amount_cents: 2000, quantity: 2)

      get cart_path

      expect(response).to have_http_status(:success)
      expect(assigns(:cart_items)).to be_present
      cart_item = assigns(:cart_items).find { |ci| ci[:variant].id == variant.id }
      expect(cart_item[:quantity]).to eq(2)
    end

    it "calculates total from CartLineService" do
      login_user(user)
      create(:cart_line, user: user, reference: variant, amount_cents: 2000, quantity: 2)

      get cart_path

      expect(assigns(:total_cents)).to eq(4000)
    end

    it "realigns stale membership lines on page load" do
      travel_to Date.new(2026, 6, 5) do
        membership = create(
          :membership,
          :pending,
          :with_health_questionnaire,
          :wrong_next_season,
          user: user,
          amount_cents: 5655
        )
        line = create(
          :cart_line,
          :membership,
          user: user,
          reference: membership,
          label: "Cotisation — Saison 2026-2027",
          amount_cents: 5655,
          metadata: { "season" => "2026-2027" }
        )
        login_user(user)

        get cart_path

        expect(response).to have_http_status(:success)
        expect(membership.reload.season).to eq("2025-2026")
        expect(line.reload.label).to include("2025-2026")
        expect(assigns(:membership_cart_lines).map(&:reference)).to include(membership)
      end
    end
  end

  describe "POST /cart/add_item" do
    before { login_user(user) }

    it "creates a CartLine instead of session entry" do
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 2 }

      expect(CartLine.where(user: user, reference: variant).exists?).to be(true)
      expect(session[:cart]).to be_blank
    end

    it "respects inventory available_qty" do
      variant.inventory.update!(stock_qty: 10, reserved_qty: 8)

      post add_item_cart_path, params: { variant_id: variant.id, quantity: 5 }

      line = CartLine.find_by(user: user, reference: variant)
      expect(line.quantity).to eq(2)
    end

    it "redirects unauthenticated users to sign in" do
      logout_user
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 1 }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "PATCH /cart/update_item" do
    before do
      login_user(user)
      create(:cart_line, user: user, reference: variant, quantity: 2)
    end

    it "updates CartLine quantity" do
      patch update_item_cart_path, params: { variant_id: variant.id, quantity: 4 }

      line = CartLine.find_by(user: user, reference: variant)
      expect(line.quantity).to eq(4)
    end

    it "caps quantity to available stock" do
      variant.inventory.update!(stock_qty: 10, reserved_qty: 7)

      patch update_item_cart_path, params: { variant_id: variant.id, quantity: 5 }

      expect(response).to redirect_to(cart_path)
      expect(flash[:alert]).to include("Quantité ajustée au stock disponible (3)")
    end
  end

  describe "DELETE /cart/remove_item" do
    before { login_user(user) }

    it "removes CartLine by cart_line_id or variant_id" do
      line = create(:cart_line, user: user, reference: variant)

      delete remove_item_cart_path, params: { cart_line_id: line.id }
      expect(CartLine.exists?(line.id)).to be(false)

      create(:cart_line, user: user, reference: variant)
      delete remove_item_cart_path, params: { variant_id: variant.id }
      expect(CartLine.where(user: user, reference: variant)).to be_empty
    end
  end
end
