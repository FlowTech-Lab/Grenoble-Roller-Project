require 'rails_helper'

RSpec.describe 'AdminPanel::Initiations', type: :request do
  include RequestAuthenticationHelper

  let(:initiation_role) { create(:role, :initiation) }
  let(:organizer_role) { create(:role, :organizer) }
  let(:admin_role) { create(:role, :admin) }
  let(:superadmin_role) { create(:role, :superadmin) }
  let(:user_role) { create(:role, level: 10) }

  let(:initiation) { create(:event_initiation) }

  describe 'GET /admin-panel/initiations' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { sign_in admin_user }

      it 'returns success' do
        get admin_panel_initiations_path
        expect(response).to have_http_status(:success)
      end

      it 'displays initiations' do
        create_list(:event_initiation, 3)
        get admin_panel_initiations_path
        expect(response.body).to include('Initiations')
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { sign_in organizer_user }

      it 'returns success' do
        get admin_panel_initiations_path
        expect(response).to have_http_status(:success)
      end

      it 'can view initiations' do
        create_list(:event_initiation, 2)
        get admin_panel_initiations_path
        expect(response.body).to include('Initiations')
      end
    end

    context 'when user is initiation (level 30)' do
      let(:initiation_user) { create(:user, :initiation) }

      before { sign_in initiation_user }

      it 'returns success' do
        get admin_panel_initiations_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user level is below 30' do
      let(:regular_user) { create(:user, role: user_role) }

      before { sign_in regular_user }

      it 'redirects to root with alert' do
        get admin_panel_initiations_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès non autorisé')
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        get admin_panel_initiations_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /admin-panel/initiations/:id' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { sign_in admin_user }

      it 'returns success' do
        get admin_panel_initiation_path(initiation)
        expect(response).to have_http_status(:success)
      end

      it 'displays initiation details' do
        get admin_panel_initiation_path(initiation)
        expect(response.body).to include(initiation.title)
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { sign_in organizer_user }

      it 'returns success' do
        get admin_panel_initiation_path(initiation)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user level is below 30' do
      let(:regular_user) { create(:user, role: user_role) }

      before { sign_in regular_user }

      it 'redirects to root' do
        get admin_panel_initiation_path(initiation)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET /admin-panel/initiations/:id/presences' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { sign_in admin_user }

      it 'returns success' do
        get presences_admin_panel_initiation_path(initiation)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { sign_in organizer_user }

      it 'redirects with not authorized' do
        get presences_admin_panel_initiation_path(initiation)
        expect(response).to redirect_to(admin_panel_root_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'PATCH /admin-panel/initiations/:id/update_presences' do
    let(:attendance) { create(:attendance, event: initiation, status: 'registered') }

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { sign_in admin_user }

      it 'updates presences' do
        patch update_presences_admin_panel_initiation_path(initiation), params: {
          attendance_ids: [attendance.id],
          presences: { attendance.id.to_s => 'present' }
        }
        expect(response).to redirect_to(presences_admin_panel_initiation_path(initiation))
        expect(attendance.reload.status).to eq('present')
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { sign_in organizer_user }

      it 'redirects with not authorized' do
        patch update_presences_admin_panel_initiation_path(initiation), params: {
          attendance_ids: [attendance.id],
          presences: { attendance.id.to_s => 'present' }
        }
        expect(response).to redirect_to(admin_panel_root_path)
      end
    end
  end
end
