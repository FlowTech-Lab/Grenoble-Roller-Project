require 'rails_helper'
require 'active_job/test_helper'

RSpec.describe EventReminderJob, type: :job do
  include ActiveJob::TestHelper

  # Configurer ActiveJob pour les tests
  around do |example|
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = :inline
  end

  describe '#perform' do
    # Nettoyer les emails et les données avant chaque test pour éviter la pollution
    before do
      # Nettoyer dans l'ordre pour éviter les contraintes de clé étrangère
      Attendance.delete_all
      Event.delete_all
      ActionMailer::Base.deliveries.clear
    end
    
    let!(:user_role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
    let!(:organizer_role) { ensure_role(code: 'ORGANIZER', name: 'Organisateur', level: 40) }
    let!(:user) { create_user(email: 'test@example.com', role: user_role) }
    let!(:organizer) { create_user(role: organizer_role) }
    # Événement demain matin (10h)
    let!(:event_tomorrow_morning) { create_event(status: 'published', creator_user: organizer, start_at: Time.zone.now.beginning_of_day + 1.day + 10.hours, title: 'Event Tomorrow Morning') }
    # Événement demain après-midi (15h)
    let!(:event_tomorrow_afternoon) { create_event(status: 'published', creator_user: organizer, start_at: Time.zone.now.beginning_of_day + 1.day + 15.hours, title: 'Event Tomorrow Afternoon') }
    # Événement demain soir (20h)
    let!(:event_tomorrow_evening) { create_event(status: 'published', creator_user: organizer, start_at: Time.zone.now.beginning_of_day + 1.day + 20.hours, title: 'Event Tomorrow Evening') }
    # Événement aujourd'hui (aujourd'hui à midi, pas demain)
    let!(:event_today) { create_event(status: 'published', creator_user: organizer, start_at: Time.zone.now.beginning_of_day + 12.hours, title: 'Event Today') }
    # Événement après-demain (pas demain)
    let!(:event_day_after_tomorrow) { create_event(status: 'published', creator_user: organizer, start_at: Time.zone.now.beginning_of_day + 2.days + 10.hours, title: 'Event Day After Tomorrow') }
    # Événement brouillon demain
    let!(:draft_event) { create_event(status: 'draft', creator_user: organizer, start_at: Time.zone.now.beginning_of_day + 1.day + 10.hours, title: 'Draft Event') }

    context 'when event is tomorrow' do
      let!(:attendance) { create_attendance(user: user, event: event_tomorrow_morning, status: 'registered', wants_reminder: true) }

      it 'sends reminder email to active attendees with wants_reminder = true' do
        # Vérifier que l'événement est bien créé et trouvé par le job
        expect(event_tomorrow_morning).to be_persisted
        expect(event_tomorrow_morning.status).to eq('published')
        expect(event_tomorrow_morning.start_at).to be > Time.zone.now.beginning_of_day + 1.day
        expect(event_tomorrow_morning.start_at).to be < (Time.zone.now.beginning_of_day + 1.day).end_of_day
        
        # Vérifier que l'attendance est bien créée
        expect(attendance).to be_persisted
        expect(attendance.status).to eq('registered')
        expect(attendance.wants_reminder).to be true
        
        # Vérifier que le job trouve l'événement
        tomorrow_start = Time.zone.now.beginning_of_day + 1.day
        tomorrow_end = tomorrow_start.end_of_day
        events_found = Event.published.upcoming.where(start_at: tomorrow_start..tomorrow_end)
        expect(events_found).to include(event_tomorrow_morning)
        
        # Vérifier que le scope active trouve l'attendance
        active_attendances = event_tomorrow_morning.attendances.active.where(wants_reminder: true)
        expect(active_attendances).to include(attendance)
        
        # Le job trouve tous les événements de demain, donc on vérifie seulement que l'email est envoyé
        initial_count = ActionMailer::Base.deliveries.count
        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.to change { ActionMailer::Base.deliveries.count }.by_at_least(1)

        # Vérifier que l'email pour cet événement est présent
        mail = ActionMailer::Base.deliveries.find { |m| m.subject.include?(event_tomorrow_morning.title) }
        expect(mail).to be_present
        expect(mail.to).to eq([ user.email ])
        expect(mail.subject).to include('Rappel')
      end

      it 'sends reminder for events at different times tomorrow' do
        attendance_afternoon = create_attendance(user: user, event: event_tomorrow_afternoon, status: 'registered', wants_reminder: true)
        attendance_evening = create_attendance(user: user, event: event_tomorrow_evening, status: 'registered', wants_reminder: true)
        
        # Vérifier que les attendances sont créées
        expect(attendance_afternoon).to be_persisted
        expect(attendance_evening).to be_persisted

        # Le job trouve tous les événements de demain, donc on vérifie seulement que les 3 emails sont envoyés
        # (1 pour event_tomorrow_morning qui a déjà une attendance, + 2 pour les nouveaux)
        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.to change { ActionMailer::Base.deliveries.count }.by_at_least(3)
        
        # Vérifier que les 3 emails pour cet utilisateur sont présents
        emails = ActionMailer::Base.deliveries.select { |m| m.to.include?(user.email) && m.subject.include?('Rappel') }
        expect(emails.count).to be >= 3
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
      let!(:attendance_today) { create_attendance(user: user, event: event_today, status: 'registered', wants_reminder: true) }
      let!(:attendance_day_after) { create_attendance(user: user, event: event_day_after_tomorrow, status: 'registered', wants_reminder: true) }

      it 'does not send reminder for events today' do
        # Vérifier que l'événement est bien aujourd'hui et pas demain
        tomorrow_start = Time.zone.now.beginning_of_day + 1.day
        tomorrow_end = tomorrow_start.end_of_day
        expect(event_today.start_at).to be < tomorrow_start
        
        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.not_to change { ActionMailer::Base.deliveries.count }
      end

      it 'does not send reminder for events day after tomorrow' do
        # Vérifier que l'événement est bien après-demain et pas demain
        tomorrow_start = Time.zone.now.beginning_of_day + 1.day
        tomorrow_end = tomorrow_start.end_of_day
        expect(event_day_after_tomorrow.start_at).to be > tomorrow_end
        
        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'when event is draft' do
      let!(:attendance_draft) { create_attendance(user: user, event: draft_event, status: 'registered', wants_reminder: true) }

      it 'does not send reminder for draft events' do
        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'with multiple attendees' do
      let!(:user2) { create_user(email: 'test2@example.com', role: user_role) }
      let!(:user3) { create_user(email: 'test3@example.com', role: user_role) }
      let!(:attendance1) { create_attendance(user: user, event: event_tomorrow_morning, status: 'registered', wants_reminder: true) }
      let!(:attendance2) { create_attendance(user: user2, event: event_tomorrow_morning, status: 'registered', wants_reminder: true) }
      let!(:attendance3) { create_attendance(user: user3, event: event_tomorrow_morning, status: 'registered', wants_reminder: false) }

      it 'sends reminder only to attendees with wants_reminder = true' do
        # Le job trouve tous les événements de demain, donc on vérifie seulement que les 2 emails sont envoyés
        expect do
          perform_enqueued_jobs do
            EventReminderJob.perform_now
          end
        end.to change { ActionMailer::Base.deliveries.count }.by_at_least(2)

        # Vérifier que les emails pour user et user2 sont présents, mais pas pour user3
        emails = ActionMailer::Base.deliveries.select { |m| m.subject.include?(event_tomorrow_morning.title) }
        expect(emails.map(&:to).flatten).to include(user.email, user2.email)
        expect(emails.map(&:to).flatten).not_to include(user3.email)
      end
    end
  end
end
