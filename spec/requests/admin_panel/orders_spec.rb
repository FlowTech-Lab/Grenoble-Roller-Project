require 'rails_helper'

RSpec.describe 'AdminPanel::Orders', type: :request do
  include RequestAuthenticationHelper

  let(:admin_role) { create(:role, :admin) }
  let(:organizer_role) { create(:role, :organizer) }
  let(:user_role) { create(:role, level: 10) }

  let(:order) { create(:order) }

  describe 'GET /admin-panel/orders' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { sign_in admin_user }

      it 'returns success' do
        get admin_panel_orders_path
        expect(response).to have_http_status(:success)
      end

      it 'displays orders' do
        create_list(:order, 3)
        get admin_panel_orders_path
        expect(response.body).to include('Commandes')
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { sign_in organizer_user }

      it 'redirects to root with alert' do
        get admin_panel_orders_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end
    end

    context 'when user level is below 60' do
      let(:regular_user) { create(:user, role: user_role) }

      before { sign_in regular_user }

      it 'redirects to root' do
        get admin_panel_orders_path
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        get admin_panel_orders_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /admin-panel/orders/:id' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { sign_in admin_user }

      it 'returns success' do
        get admin_panel_order_path(order)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { sign_in organizer_user }

      it 'redirects to root' do
        get admin_panel_order_path(order)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
