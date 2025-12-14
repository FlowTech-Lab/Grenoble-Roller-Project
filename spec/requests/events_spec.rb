require 'rails_helper'
require 'active_job/test_helper'

RSpec.describe 'Events', type: :request do
  include ActiveJob::TestHelper
  describe 'GET /events' do
    it 'renders the events index with upcoming events' do
      create(:event, :published, title: 'Roller Night')

      get events_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Roller Night')
    end
  end

  describe 'GET /events/:id' do
    it 'allows anyone to view a published event' do
      event = create(:event, :published, title: 'Open Session')

      get event_path(event)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Open Session')
    end

    it 'redirects visitors trying to view a draft event' do
      event = create(:event, status: 'draft')

      get event_path(event)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe 'POST /events' do
    let(:route) { create(:route) }
    let(:valid_params) do
      attributes_for(:event, route_id: route.id).slice(
        :title, :status, :start_at, :duration_min, :description,
        :price_cents, :currency, :location_text, :meeting_lat,
        :meeting_lng, :route_id, :cover_image_url
      )
    end

    it 'allows an organizer to create an event' do
      organizer = create(:user, :organizer)
      login_user(organizer)

      expect do
        post events_path, params: { event: valid_params }
      end.to change { Event.count }.by(1)

      expect(response).to redirect_to(event_path(Event.last))
      expect(flash[:notice]).to eq('Événement créé avec succès.')
      expect(Event.last.creator_user).to eq(organizer)
    end

    it 'prevents a regular member from creating an event' do
      member = create(:user)
      login_user(member)

      expect do
        post events_path, params: { event: valid_params }
      end.not_to change { Event.count }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe 'POST /events/:id/attend' do
    let(:event) { create(:event, :published) }

    it 'requires authentication' do
      post attend_event_path(event)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'registers the current user' do
      user = create(:user)
      login_user(user)

      perform_enqueued_jobs do
        expect do
          post event_attendances_path(event)
        end.to change { Attendance.count }.by(1)
      end

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to eq('Inscription confirmée.')
      expect(event.attendances.exists?(user: user)).to be(true)
    end

    it 'blocks unconfirmed users from attending' do
      user = create(:user, :unconfirmed)
      login_user(user)

      expect do
        post event_attendances_path(event)
      end.not_to change { Attendance.count }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include('confirmer votre adresse email')
    end

    it 'does not duplicate an existing attendance' do
      user = create(:user)
      create(:attendance, user: user, event: event)
      login_user(user)

      expect do
        post event_attendances_path(event)
      end.not_to change { Attendance.count }

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to eq("Vous êtes déjà inscrit(e) à cet événement.")
    end
  end

  describe 'DELETE /events/:event_id/attendances' do
    let(:event) { create(:event, :published) }

    it 'requires authentication' do
      delete event_attendances_path(event)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'removes the attendance for the current user' do
      user = create(:user)
      attendance = create(:attendance, user: user, event: event)
      login_user(user)

      perform_enqueued_jobs do
        expect do
          delete event_attendances_path(event)
        end.to change { Attendance.exists?(attendance.id) }.from(true).to(false)
      end

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to eq('Inscription annulée.')
    end
  end

  describe 'GET /events/:id.ics' do
    let(:user) { create(:user) }
    let(:event) { create(:event, :published, :upcoming, title: 'Sortie Roller') }

    it 'requires authentication' do
      get event_path(event, format: :ics)

      # Pour les requêtes .ics, Devise retourne 401 Unauthorized
      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to include('You need to sign in')
    end

    it 'exports event as iCal file for published event when authenticated' do
      login_user(user)

      get event_path(event, format: :ics)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('text/calendar')
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.headers['Content-Disposition']).to include('sortie-roller.ics')
      expect(response.body).to include('BEGIN:VCALENDAR')
      expect(response.body).to include('BEGIN:VEVENT')
      expect(response.body).to include('SUMMARY:Sortie Roller')
      expect(response.body).to include('END:VEVENT')
      expect(response.body).to include('END:VCALENDAR')
    end

    it 'redirects to root for draft event when authenticated but not creator' do
      login_user(user)
      draft_event = create(:event, :draft, :upcoming)

      get event_path(draft_event, format: :ics)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end

    it 'allows creator to export draft event' do
      organizer = create(:user, :organizer)
      draft_event = create(:event, :draft, :upcoming, creator_user: organizer)
      login_user(organizer)

      get event_path(draft_event, format: :ics)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('text/calendar')
    end
  end
end
