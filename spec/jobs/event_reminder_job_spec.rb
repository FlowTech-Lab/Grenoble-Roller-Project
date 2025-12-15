require 'rails_helper'
require 'active_job/test_helper'

RSpec.describe EventReminderJob, type: :job do
  include ActiveJob::TestHelper

  describe '#perform' do
    let!(:user_role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
    let!(:organizer_role) { ensure_role(code: 'ORGANIZER', name: 'Organisateur', level: 40) }
    let!(:user) { create(:user, email: 'test@example.com', role: user_role) }
    let!(:organizer) { create(:user, role: organizer_role) }
    # Événement demain matin (10h)
    let!(:event_tomorrow_morning) { create(:event, :published, creator_user: organizer, start_at: Time.zone.now.beginning_of_day + 1.day + 10.hours, title: 'Event Tomorrow Morning') }
    # Événement demain après-midi (15h)
    let!(:event_tomorrow_afternoon) { create(:event, :published, creator_user: organizer, start_at: Time.zone.now.beginning_of_day + 1.day + 15.hours, title: 'Event Tomorrow Afternoon') }
    # Événement demain soir (20h)
    let!(:event_tomorrow_evening) { create(:event, :published, creator_user: organizer, start_at: Time.zone.now.beginning_of_day + 1.day + 20.hours, title: 'Event Tomorrow Evening') }
    # Événement aujourd'hui
    let!(:event_today) { create(:event, :published, creator_user: organizer, start_at: 2.hours.from_now, title: 'Event Today') }
    # Événement après-demain
    let!(:event_day_after_tomorrow) { create(:event, :published, creator_user: organizer, start_at: Time.zone.now.beginning_of_day + 2.days + 10.hours, title: 'Event Day After Tomorrow') }
    # Événement brouillon demain
    let!(:draft_event) { create(:event, :draft, creator_user: organizer, start_at: Time.zone.now.beginning_of_day + 1.day + 10.hours, title: 'Draft Event') }

    context 'when event is tomorrow' do
      let!(:attendance) { create(:attendance, user: user, event: event_tomorrow_morning, status: 'registered', wants_reminder: true) }

      it 'sends reminder email to active attendees with wants_reminder = true' do
        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.to change { ActionMailer::Base.deliveries.count }.by(1)

        mail = ActionMailer::Base.deliveries.last
        expect(mail.to).to eq([ user.email ])
        expect(mail.subject).to include('Rappel')
        expect(mail.subject).to include(event_tomorrow_morning.title)
      end

      it 'sends reminder for events at different times tomorrow' do
        create(:attendance, user: user, event: event_tomorrow_afternoon, status: 'registered', wants_reminder: true)
        create(:attendance, user: user, event: event_tomorrow_evening, status: 'registered', wants_reminder: true)

        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.to change { ActionMailer::Base.deliveries.count }.by(3)
      end

      it 'does not send reminder for canceled attendance' do
        attendance.update(status: 'canceled')

        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.not_to change { ActionMailer::Base.deliveries.count }
      end

      it 'does not send reminder if wants_reminder is false' do
        attendance.update(wants_reminder: false)

        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'when event is not tomorrow' do
      let!(:attendance_today) { create(:attendance, user: user, event: event_today, status: 'registered', wants_reminder: true) }
      let!(:attendance_day_after) { create(:attendance, user: user, event: event_day_after_tomorrow, status: 'registered', wants_reminder: true) }

      it 'does not send reminder for events today' do
        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.not_to change { ActionMailer::Base.deliveries.count }
      end

      it 'does not send reminder for events day after tomorrow' do
        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'when event is draft' do
      let!(:attendance_draft) { create(:attendance, user: user, event: draft_event, status: 'registered', wants_reminder: true) }

      it 'does not send reminder for draft events' do
        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'with multiple attendees' do
      let!(:user2) { create(:user, email: 'test2@example.com', role: user_role) }
      let!(:user3) { create(:user, email: 'test3@example.com', role: user_role) }
      let!(:attendance1) { create(:attendance, user: user, event: event_tomorrow_morning, status: 'registered', wants_reminder: true) }
      let!(:attendance2) { create(:attendance, user: user2, event: event_tomorrow_morning, status: 'registered', wants_reminder: true) }
      let!(:attendance3) { create(:attendance, user: user3, event: event_tomorrow_morning, status: 'registered', wants_reminder: false) }

      it 'sends reminder only to attendees with wants_reminder = true' do
        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.to change { ActionMailer::Base.deliveries.count }.by(2)

        emails = ActionMailer::Base.deliveries.last(2)
        expect(emails.map(&:to).flatten).to contain_exactly(user.email, user2.email)
        expect(emails.map(&:to).flatten).not_to include(user3.email)
      end
    end
  end
end
