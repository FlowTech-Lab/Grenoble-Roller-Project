# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Carts', type: :request do
  let(:category) { create(:product_category) }
  let(:product) { create(:product, category: category) }
  let(:variant) { create(:product_variant, product: product, stock_qty: 10, price_cents: 2000) }

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
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 2 }
      get cart_path
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include(product.name)
      expect(assigns(:cart_items)).to be_present
    end

    it 'calculates total correctly' do
      variant2 = create(:product_variant, product: product, stock_qty: 10, price_cents: 3000)
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 2 }
      post add_item_cart_path, params: { variant_id: variant2.id, quantity: 1 }
      
      get cart_path
      
      expect(response).to have_http_status(:success)
      # Total attendu : (2000 * 2) + (3000 * 1) = 7000 cents = 70.00 EUR
      expect(assigns(:total_cents)).to eq(7000)
    end

    it 'displays cart items with correct quantities' do
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 3 }
      get cart_path
      
      expect(response).to have_http_status(:success)
      cart_item = assigns(:cart_items).find { |ci| ci[:variant_id] == variant.id }
      expect(cart_item[:quantity]).to eq(3)
      expect(cart_item[:subtotal_cents]).to eq(6000) # 2000 * 3
    end
  end
end

