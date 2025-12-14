# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Products', type: :request do
  let(:category) { create(:product_category) }
  let(:product) { create(:product, category: category, slug: 'roller-quad') }

  describe 'GET /products/:id' do
    it 'allows public access without authentication' do
      get product_path(product.slug)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(product.name)
    end

    it 'finds product by slug' do
      get product_path(product.slug)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(product.name)
    end

    it 'finds product by numeric id' do
      get product_path(product.id)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(product.name)
    end

    it 'returns 404 if product not found' do
      expect {
        get product_path('non-existent-product-12345')
      }.to raise_error(ActiveRecord::RecordNotFound, /Product not found/)
    end

    it 'loads active variants' do
      active_variant = create(:product_variant, product: product, is_active: true)
      inactive_variant = create(:product_variant, product: product, is_active: false)
      
      get product_path(product.slug)
      expect(response).to have_http_status(:success)
      expect(assigns(:variants)).to include(active_variant)
      expect(assigns(:variants)).not_to include(inactive_variant)
    end

    it 'loads variants with option values' do
      variant = create(:product_variant, product: product, is_active: true)
      get product_path(product.slug)
      expect(response).to have_http_status(:success)
      # Vérifier que les associations sont chargées (pas de N+1)
      expect(assigns(:variants).first.association(:variant_option_values).loaded?).to be true
    end
  end
end

