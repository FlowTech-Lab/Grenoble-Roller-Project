# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AdminPanel::EventOrganizers', type: :request do
  include RequestAuthenticationHelper

  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }

  describe 'GET /admin-panel/event-organizers' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before do
        login_user(admin_user)
      end

      it 'returns success' do
        get admin_panel_event_organizers_path
        expect(response).to have_http_status(:success)
      end

      it 'displays event organizers' do
        create_list(:event_organizer, 3)
        get admin_panel_event_organizers_path
        expect(response.body).to include('Entités organisatrices')
      end

      it 'filters by active scope' do
        active = create(:event_organizer, is_active: true)
        inactive = create(:event_organizer, is_active: false)

        get admin_panel_event_organizers_path, params: { scope: 'active' }

        expect(response).to have_http_status(:success)
        expect(@controller.instance_variable_get(:@event_organizers)).to include(active)
        expect(@controller.instance_variable_get(:@event_organizers)).not_to include(inactive)
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before do
        login_user(organizer_user)
      end

      it 'redirects to root with alert' do
        get admin_panel_event_organizers_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        get admin_panel_event_organizers_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /admin-panel/event-organizers/:id' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }
      let(:event_organizer) { create(:event_organizer) }

      before do
        login_user(admin_user)
      end

      it 'returns success' do
        get admin_panel_event_organizer_path(event_organizer)
        expect(response).to have_http_status(:success)
      end

      it 'displays event organizer details' do
        get admin_panel_event_organizer_path(event_organizer)
        expect(response.body).to include(event_organizer.name)
      end
    end
  end

  describe 'GET /admin-panel/event-organizers/new' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before do
        login_user(admin_user)
      end

      it 'returns success' do
        get new_admin_panel_event_organizer_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /admin-panel/event-organizers' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before do
        login_user(admin_user)
      end

      it 'creates a new event organizer' do
        params = {
          event_organizer: {
            name: 'Grenoble Roller',
            url: 'https://example.com',
            is_active: true
          }
        }

        expect {
          post admin_panel_event_organizers_path, params: params
        }.to change(EventOrganizer, :count).by(1)
      end

      it 'redirects to event organizer show' do
        params = {
          event_organizer: {
            name: 'Grenoble Roller',
            url: 'https://example.com',
            is_active: true
          }
        }

        post admin_panel_event_organizers_path, params: params
        expect(response).to redirect_to(admin_panel_event_organizer_path(EventOrganizer.last))
      end
    end
  end

  describe 'GET /admin-panel/event-organizers/:id/edit' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }
      let(:event_organizer) { create(:event_organizer) }

      before do
        login_user(admin_user)
      end

      it 'returns success' do
        get edit_admin_panel_event_organizer_path(event_organizer)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'PATCH /admin-panel/event-organizers/:id' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }
      let(:event_organizer) { create(:event_organizer) }

      before do
        login_user(admin_user)
      end

      it 'updates the event organizer' do
        patch admin_panel_event_organizer_path(event_organizer), params: {
          event_organizer: { name: 'Nom modifié' }
        }

        expect(event_organizer.reload.name).to eq('Nom modifié')
      end
    end
  end

  describe 'DELETE /admin-panel/event-organizers/:id' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }
      let!(:event_organizer) { create(:event_organizer) }

      before do
        login_user(admin_user)
      end

      it 'deletes the event organizer' do
        expect {
          delete admin_panel_event_organizer_path(event_organizer)
        }.to change(EventOrganizer, :count).by(-1)
      end

      it 'redirects to event organizers index' do
        delete admin_panel_event_organizer_path(event_organizer)
        expect(response).to redirect_to(admin_panel_event_organizers_path)
      end
    end
  end
end
