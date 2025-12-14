# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Products', type: :request do
  let(:category) { create(:product_category) }
  let(:product) { create(:product, category: category, slug: 'roller-quad') }
  
  # Créer un variant pour tous les tests pour éviter les erreurs dans la vue
  before do
    create(:product_variant, product: product, is_active: true) unless product.product_variants.any?
  end

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
      # Créer un variant pour éviter les erreurs dans la vue
      create(:product_variant, product: product, is_active: true)
      get product_path(product.id)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(product.name)
    end

    it 'returns 404 if product not found' do
      # Rails intercepte RecordNotFound et retourne 404
      get product_path('non-existent-product-12345')
      expect(response).to have_http_status(:not_found)
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
      # Vérifier que les variants sont chargés
      expect(assigns(:variants)).to include(variant)
      # Vérifier que les associations sont chargées (pas de N+1)
      first_variant = assigns(:variants).first
      expect(first_variant.association(:variant_option_values).loaded?).to be true
    end
  end
end

