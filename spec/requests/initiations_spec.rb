require 'rails_helper'

RSpec.describe 'Initiations', type: :request do
  include RequestAuthenticationHelper
  
  let(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }

  describe 'GET /initiations' do
    it 'renders the initiations index with upcoming initiations' do
      create(:event_initiation, :published, title: 'Initiation Débutant')

      get initiations_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Initiation Débutant')
    end
  end

  describe 'GET /initiations/:id' do
    it 'allows anyone to view a published initiation' do
      initiation = create(:event_initiation, :published, title: 'Cours Initiation')

      get initiation_path(initiation)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Cours Initiation')
    end

    it 'redirects visitors trying to view a draft initiation' do
      initiation = create(:event_initiation, status: 'draft')

      get initiation_path(initiation)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe 'GET /initiations/:id.ics' do
    let(:user) { create(:user, role: role) }
    let(:initiation) { create(:event_initiation, :published, :upcoming, title: 'Initiation Roller') }

    it 'requires authentication' do
      get initiation_path(initiation, format: :ics)

      # Pour les requêtes .ics, Devise retourne 401 Unauthorized
      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to include('You need to sign in')
    end

    it 'exports initiation as iCal file for published initiation when authenticated' do
      login_user(user)

      get initiation_path(initiation, format: :ics)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('text/calendar')
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.headers['Content-Disposition']).to include('initiation-roller.ics')
      expect(response.body).to include('BEGIN:VCALENDAR')
      expect(response.body).to include('BEGIN:VEVENT')
      expect(response.body).to include('SUMMARY:Initiation Roller')
      expect(response.body).to include('END:VEVENT')
      expect(response.body).to include('END:VCALENDAR')
    end

    it 'redirects to root for draft initiation when authenticated but not creator' do
      login_user(user)
      draft_initiation = create(:event_initiation, :draft, :upcoming)

      get initiation_path(draft_initiation, format: :ics)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end

    it 'allows creator to export draft initiation' do
      organizer = create(:user, :organizer)
      draft_initiation = create(:event_initiation, :draft, :upcoming, creator_user: organizer)
      login_user(organizer)

      get initiation_path(draft_initiation, format: :ics)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('text/calendar')
    end
  end

  describe 'POST /initiations/:initiation_id/attendances' do
    let(:initiation) { create(:event_initiation, :published) }

    it 'requires authentication' do
      post initiation_attendances_path(initiation)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'registers the current user' do
      user = create(:user, role: role)
      login_user(user)

      expect do
        post initiation_attendances_path(initiation)
      end.to change { Attendance.count }.by(1)

      expect(response).to redirect_to(initiation_path(initiation))
      expect(flash[:notice]).to be_present
      expect(initiation.attendances.exists?(user: user)).to be(true)
    end
  end
end

