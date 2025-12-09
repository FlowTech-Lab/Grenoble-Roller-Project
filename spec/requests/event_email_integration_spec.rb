require 'rails_helper'
require 'active_job/test_helper'

RSpec.describe 'Event Email Integration', type: :request do
  include ActiveJob::TestHelper

  let!(:role) { ensure_role(code: 'MEMBER', name: 'Membre', level: 20) }
  let!(:user) { create_user(role: role, email: 'member@example.com', first_name: 'Jean', confirmed_at: Time.current) }
  let!(:event) { create_event(:published, :upcoming, title: 'Sortie Roller', creator_user: create_user) }

  describe 'POST /events/:id/attend' do
    before do
      login_user(user)
    end

    it 'sends confirmation email when user attends event' do
      expect {
        post attend_event_path(event), params: { wants_reminder: '1' }
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
        .with('EventMailer', 'attendance_confirmed', 'deliver_now', args: [ instance_of(Attendance) ])
        .and change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'creates attendance and sends email' do
      expect {
        post attend_event_path(event)
      }.to change { Attendance.count }.by(1)
        .and change { ActionMailer::Base.deliveries.count }.by(1)

      email = ActionMailer::Base.deliveries.last
      expect(email.to).to eq([ user.email ])
      expect(email.subject).to include(event.title)
      expect(email.subject).to include('Inscription confirmée')
    end
  end

  describe 'DELETE /events/:id/cancel_attendance' do
    let!(:attendance) { create_attendance(user: user, event: event, status: 'registered') }

    before do
      login_user(user)
    end

    it 'sends cancellation email when user cancels attendance' do
      expect {
        delete cancel_attendance_event_path(event)
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      email = ActionMailer::Base.deliveries.last
      expect(email.to).to eq([ user.email ])
      expect(email.subject).to include(event.title)
      expect(email.subject).to include('Désinscription confirmée')
    end
  end
end
