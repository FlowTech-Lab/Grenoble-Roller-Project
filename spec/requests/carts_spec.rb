# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Carts', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:category) { create(:product_category) }
  let(:product) { create(:product, category: category) }
  let(:variant) do
    v = create(:product_variant, product: product, stock_qty: 10, price_cents: 2000, is_active: true)
    # S'assurer que l'inventaire existe et a du stock
    inv = v.inventory || Inventory.create!(product_variant: v, stock_qty: 10, reserved_qty: 0)
    inv.update!(stock_qty: 10, reserved_qty: 0)
    v.reload
    v
  end

  context 'when UNIFIED_CART_ENABLED is false' do
    around do |example|
      previous = ENV['UNIFIED_CART_ENABLED']
      ENV['UNIFIED_CART_ENABLED'] = 'false'
      example.run
    ensure
      ENV['UNIFIED_CART_ENABLED'] = previous
    end

  describe 'GET /cart' do
    it 'allows public access without authentication' do
      get cart_path
      expect(response).to have_http_status(:success)
    end

    it 'displays empty cart correctly' do
      get cart_path
      expect(response).to have_http_status(:success)
      # Vérifier que le panier est vide (total = 0)
      expect(assigns(:total_cents)).to eq(0)
      expect(assigns(:cart_items)).to be_empty
    end

    it 'displays cart items when cart has items' do
      # S'assurer que le variant a un inventaire avec du stock
      variant.inventory || Inventory.create!(product_variant: variant, stock_qty: 10, reserved_qty: 0)
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 2 }
      # Vérifier que le panier n'est pas vide
      expect(session[:cart]).to be_present

      get cart_path

      expect(response).to have_http_status(:success)
      expect(assigns(:cart_items)).to be_present
      # Vérifier que le produit est dans les cart_items
      cart_item = assigns(:cart_items).find { |ci| ci[:variant].id == variant.id }
      expect(cart_item).to be_present
      expect(cart_item[:variant].product.name).to eq(product.name)
    end

    it 'calculates total correctly' do
      variant2 = create(:product_variant, product: product, stock_qty: 10, price_cents: 3000, is_active: true)
      # S'assurer que les variants ont des inventaires
      variant.inventory || Inventory.create!(product_variant: variant, stock_qty: 10, reserved_qty: 0)
      variant2.inventory || Inventory.create!(product_variant: variant2, stock_qty: 10, reserved_qty: 0)

      post add_item_cart_path, params: { variant_id: variant.id, quantity: 2 }
      post add_item_cart_path, params: { variant_id: variant2.id, quantity: 1 }

      get cart_path

      expect(response).to have_http_status(:success)
      # Total attendu : (2000 * 2) + (3000 * 1) = 7000 cents = 70.00 EUR
      expect(assigns(:total_cents)).to eq(7000)
    end

    it 'displays cart items with correct quantities' do
      # S'assurer que le variant a un inventaire avec du stock
      variant.inventory || Inventory.create!(product_variant: variant, stock_qty: 10, reserved_qty: 0)
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 3 }
      # Vérifier que le panier n'est pas vide
      expect(session[:cart]).to be_present

      get cart_path

      expect(response).to have_http_status(:success)
      cart_item = assigns(:cart_items).find { |ci| ci[:variant].id == variant.id }
      expect(cart_item).to be_present
      expect(cart_item[:quantity]).to eq(3)
      expect(cart_item[:subtotal_cents]).to eq(6000) # 2000 * 3
    end
  end

  describe 'POST /cart/add_item - Stock management with Inventories' do
    let(:category) { create(:product_category) }
    let(:product) { create(:product, category: category) }
    let(:variant) do
      v = create(:product_variant, product: product, stock_qty: 10, is_active: true)
      # S'assurer que l'inventaire existe et a les bonnes valeurs
      inv = v.inventory || Inventory.create!(product_variant: v, stock_qty: 10, reserved_qty: 0)
      inv.update!(stock_qty: 10, reserved_qty: 0)
      v.reload
      v
    end
    let(:inventory) { variant.inventory }

    before do
      inventory # Créer l'inventaire
    end

    it 'uses available_qty (stock_qty - reserved_qty) to check stock' do
      # Réserver 5 unités
      inventory.update!(reserved_qty: 5)
      # available_qty = 10 - 5 = 5

      # Essayer d'ajouter 6 unités (plus que disponible)
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 6 }

      expect(response).to redirect_to(shop_path)
      expect(flash[:alert]).to include('Stock insuffisant')
    end

    it 'allows adding items up to available_qty' do
      # Réserver 5 unités
      inventory.update!(reserved_qty: 5)
      # available_qty = 10 - 5 = 5

      # Ajouter 5 unités (exactement disponible)
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 5 }

      expect(response).to redirect_to(shop_path)
      expect(flash[:notice]).to be_present
    end

    it 'caps quantity to available_qty when adding more' do
      # Réserver 7 unités
      inventory.update!(reserved_qty: 7)
      # available_qty = 10 - 7 = 3

      # Essayer d'ajouter 5 unités, mais seulement 3 disponibles
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 5 }

      expect(response).to redirect_to(shop_path)
      expect(flash[:alert]).to include('Stock insuffisant')
    end

    it 'falls back to stock_qty if inventory does not exist' do
      # Pas d'inventaire créé
      variant_without_inventory = create(:product_variant, product: product, stock_qty: 5, is_active: true)

      post add_item_cart_path, params: { variant_id: variant_without_inventory.id, quantity: 3 }

      expect(response).to redirect_to(shop_path)
      expect(flash[:notice]).to be_present
    end
  end

  describe 'PATCH /cart/update_item - Stock management with Inventories' do
    let(:category) { create(:product_category) }
    let(:product) { create(:product, category: category) }
    let(:variant) do
      v = create(:product_variant, product: product, stock_qty: 10, is_active: true)
      # S'assurer que l'inventaire existe et a les bonnes valeurs
      inv = v.inventory || Inventory.create!(product_variant: v, stock_qty: 10, reserved_qty: 0)
      inv.update!(stock_qty: 10, reserved_qty: 0)
      v.reload
      v
    end
    let(:inventory) { variant.inventory }

    before do
      inventory # Créer l'inventaire
      # Ajouter un item au panier
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 2 }
    end

    it 'uses available_qty to cap quantity' do
      # Réserver 7 unités
      inventory.update!(reserved_qty: 7)
      # available_qty = 10 - 7 = 3

      # Essayer de mettre à jour à 5 unités, mais seulement 3 disponibles
      patch update_item_cart_path, params: { variant_id: variant.id, quantity: 5 }

      expect(response).to redirect_to(cart_path)
      expect(flash[:alert]).to include('Quantité ajustée au stock disponible (3)')
    end

    it 'allows updating to available_qty' do
      # Réserver 5 unités
      inventory.update!(reserved_qty: 5)
      # available_qty = 10 - 5 = 5

      patch update_item_cart_path, params: { variant_id: variant.id, quantity: 5 }

      expect(response).to redirect_to(cart_path)
      expect(flash[:notice]).to include('Panier mis à jour')
    end
  end

  end

  context "when UNIFIED_CART_ENABLED is true" do
    let(:user) { create(:user) }
    let!(:prepared_variant) { variant }

    around do |example|
      previous = ENV["UNIFIED_CART_ENABLED"]
      ENV["UNIFIED_CART_ENABLED"] = "true"
      example.run
    ensure
      ENV["UNIFIED_CART_ENABLED"] = previous
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

  context "when UNIFIED_CART_ENABLED is false (explicit legacy shim)" do
    around do |example|
      previous = ENV["UNIFIED_CART_ENABLED"]
      ENV["UNIFIED_CART_ENABLED"] = "false"
      example.run
    ensure
      ENV["UNIFIED_CART_ENABLED"] = previous
    end

    it "keeps session cart behaviour for GET /cart" do
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 1 }
      get cart_path

      expect(response).to have_http_status(:success)
      expect(session[:cart][variant.id.to_s]).to eq(1)
    end

    it "keeps session cart behaviour for POST /cart/add_item" do
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 2 }

      expect(session[:cart][variant.id.to_s]).to eq(2)
      expect(CartLine.count).to eq(0)
    end
  end
end
