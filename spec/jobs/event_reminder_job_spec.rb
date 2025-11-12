require 'rails_helper'
require 'active_job/test_helper'

RSpec.describe EventReminderJob, type: :job do
  include ActiveJob::TestHelper

  describe '#perform' do
    let!(:user) { create(:user, email: 'test@example.com') }
    let!(:event_tomorrow) { create(:event, :published, start_at: 24.hours.from_now, title: 'Event Tomorrow') }
    let!(:event_today) { create(:event, :published, start_at: 2.hours.from_now, title: 'Event Today') }
    let!(:event_next_week) { create(:event, :published, start_at: 1.week.from_now, title: 'Event Next Week') }
    let!(:draft_event) { create(:event, :draft, start_at: 24.hours.from_now, title: 'Draft Event') }

    context 'when event is in 24h window' do
      let!(:attendance) { create(:attendance, user: user, event: event_tomorrow, status: 'registered') }

      it 'sends reminder email to active attendees' do
        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.to change { ActionMailer::Base.deliveries.count }.by(1)

        mail = ActionMailer::Base.deliveries.last
        expect(mail.to).to eq([user.email])
        expect(mail.subject).to include('Rappel')
        expect(mail.subject).to include(event_tomorrow.title)
      end

      it 'does not send reminder for canceled attendance' do
        attendance.update(status: 'canceled')

        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'when event is not in 24h window' do
      let!(:attendance_today) { create(:attendance, user: user, event: event_today, status: 'registered') }
      let!(:attendance_next_week) { create(:attendance, user: user, event: event_next_week, status: 'registered') }

      it 'does not send reminder for events today' do
        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.not_to change { ActionMailer::Base.deliveries.count }
      end

      it 'does not send reminder for events next week' do
        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'when event is draft' do
      let!(:attendance_draft) { create(:attendance, user: user, event: draft_event, status: 'registered') }

      it 'does not send reminder for draft events' do
        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'with multiple attendees' do
      let!(:user2) { create(:user, email: 'test2@example.com') }
      let!(:user3) { create(:user, email: 'test3@example.com') }
      let!(:attendance1) { create(:attendance, user: user, event: event_tomorrow, status: 'registered') }
      let!(:attendance2) { create(:attendance, user: user2, event: event_tomorrow, status: 'registered') }
      let!(:attendance3) { create(:attendance, user: user3, event: event_tomorrow, status: 'registered') }

      it 'sends reminder to all active attendees' do
        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.to change { ActionMailer::Base.deliveries.count }.by(3)

        emails = ActionMailer::Base.deliveries.last(3)
        expect(emails.map(&:to).flatten).to contain_exactly(user.email, user2.email, user3.email)
      end
    end
  end
end

