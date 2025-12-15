require 'rails_helper'
require 'active_job/test_helper'

RSpec.describe 'Event Email Integration', type: :request do
  include ActiveJob::TestHelper
  include TestDataHelper

  # Configurer ActiveJob pour les tests
  around do |example|
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = :inline
  end

  let!(:role) { ensure_role(code: 'MEMBER', name: 'Membre', level: 20) }
  let!(:user) { create_user(role: role, email: 'member@example.com', first_name: 'Jean', confirmed_at: Time.current) }
  let!(:event) do
    e = build_event(status: 'published', start_at: 1.week.from_now, title: 'Sortie Roller', creator_user: create_user)
    e.save!
    e
  end

  describe 'POST /events/:event_id/attendances' do
    before do
      login_user(user)
    end

    it 'sends confirmation email when user attends event' do
      perform_enqueued_jobs do
        expect {
          post event_attendances_path(event), params: { wants_reminder: '1' }
        }.to change { Attendance.count }.by(1)
          .and change { ActionMailer::Base.deliveries.count }.by(1)
      end

      email = ActionMailer::Base.deliveries.last
      expect(email.to).to eq([ user.email ])
      expect(email.subject).to include(event.title)
      expect(email.subject).to include('Inscription confirmée')
    end

    it 'creates attendance and sends email' do
      perform_enqueued_jobs do
        expect {
          post event_attendances_path(event)
        }.to change { Attendance.count }.by(1)
          .and change { ActionMailer::Base.deliveries.count }.by(1)
      end

      email = ActionMailer::Base.deliveries.last
      expect(email.to).to eq([ user.email ])
      expect(email.subject).to include(event.title)
      expect(email.subject).to include('Inscription confirmée')
    end
  end

  describe 'DELETE /events/:event_id/attendances' do
    let!(:attendance) { create_attendance(user: user, event: event, status: 'registered') }

    before do
      login_user(user)
    end

    it 'sends cancellation email when user cancels attendance' do
      perform_enqueued_jobs do
        expect {
          delete event_attendances_path(event)
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      email = ActionMailer::Base.deliveries.last
      expect(email.to).to eq([ user.email ])
      expect(email.subject).to include(event.title)
      expect(email.subject).to include('Désinscription confirmée')
    end
  end
end
