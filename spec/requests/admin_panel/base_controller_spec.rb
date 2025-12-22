require 'rails_helper'

RSpec.describe 'AdminPanel::BaseController', type: :request do
  include RequestAuthenticationHelper

  let(:initiation_role) { Role.find_or_create_by!(code: 'INITIATION') { |r| r.name = 'Initiation'; r.level = 30 } }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }
  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:user_role) { Role.find_or_create_by!(code: 'USER') { |r| r.name = 'Utilisateur'; r.level = 10 } }

  describe 'Authentication and authorization' do
    context 'when accessing initiations (level >= 30 required)' do
      context 'with initiation user (level 30)' do
        let(:user) { create(:user, :initiation) }

        before { sign_in user }

        it 'allows access to initiations' do
          get admin_panel_initiations_path
          expect(response).to have_http_status(:success)
        end
      end

      context 'with organizer user (level 40)' do
        let(:user) { create(:user, :organizer) }

        before { sign_in user }

        it 'allows access to initiations' do
          get admin_panel_initiations_path
          expect(response).to have_http_status(:success)
        end
      end

      context 'with regular user (level 10)' do
        let(:user) { create(:user, role: user_role) }

        before { sign_in user }

        it 'denies access to initiations' do
          get admin_panel_initiations_path
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to include('Accès non autorisé')
        end
      end
    end

    context 'when accessing dashboard (level >= 60 required)' do
      context 'with admin user (level 60)' do
        let(:user) { create(:user, :admin) }

        before { sign_in user }

        it 'allows access to dashboard' do
          get admin_panel_root_path
          expect(response).to have_http_status(:success)
        end
      end

      context 'with organizer user (level 40)' do
        let(:user) { create(:user, :organizer) }

        before { sign_in user }

        it 'denies access to dashboard' do
          get admin_panel_root_path
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to include('Accès admin requis')
        end
      end
    end

    context 'when accessing orders (level >= 60 required)' do
      context 'with admin user (level 60)' do
        let(:user) { create(:user, :admin) }

        before { sign_in user }

        it 'allows access to orders' do
          get admin_panel_orders_path
          expect(response).to have_http_status(:success)
        end
      end

      context 'with organizer user (level 40)' do
        let(:user) { create(:user, :organizer) }

        before { sign_in user }

        it 'denies access to orders' do
          get admin_panel_orders_path
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to include('Accès admin requis')
        end
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login for initiations' do
        get admin_panel_initiations_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to login for dashboard' do
        get admin_panel_root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
