require 'rails_helper'

RSpec.describe 'Orders', type: :request do
  let(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let(:user) { create(:user, role: role) }
  let(:category) { create(:product_category) }
  let(:product) { create(:product, category: category) }
  let(:variant) { create(:product_variant, product: product, stock_qty: 10) }

  describe 'GET /orders/new' do
    it 'requires authentication' do
      get new_order_path
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'with cart items' do
      before do
        login_user(user)
        # Simuler un panier avec des items
        post add_item_cart_path, params: { variant_id: variant.id, quantity: 1 }
      end

      it 'allows authenticated confirmed user to access checkout' do
        get new_order_path
        expect(response).to have_http_status(:ok)
      end

      it 'allows unconfirmed users to view checkout (but blocks on create)' do
        logout_user
        unconfirmed_user = create(:user, :unconfirmed, role: role)
        login_user(unconfirmed_user)

        # Ajouter au panier pour l'utilisateur non confirmé
        post add_item_cart_path, params: { variant_id: variant.id, quantity: 1 }

        # GET /orders/new n'a pas de blocage email (seulement POST /orders)
        get new_order_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'POST /orders' do
    before do
      login_user(user)
      # Simuler un panier avec des items
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 1 }
    end

    it 'requires authentication' do
      logout_user
      post orders_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'allows confirmed user to create an order' do
      expect {
        post orders_path
      }.to change(Order, :count).by(1)

      expect(response).to have_http_status(:redirect)
      expect(Order.last.user).to eq(user)
      expect(flash[:notice]).to include('succès')
    end

    it 'blocks unconfirmed users from creating an order' do
      logout_user
      unconfirmed_user = create(:user, :unconfirmed, role: role)
      login_user(unconfirmed_user)

      # Ajouter au panier pour l'utilisateur non confirmé
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 1 }

      expect {
        post orders_path
      }.not_to change(Order, :count)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include('confirmer votre adresse email')
    end
  end
end
