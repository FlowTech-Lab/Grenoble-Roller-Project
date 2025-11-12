# Job pour envoyer des rappels 24h avant les événements
class EventReminderJob < ApplicationJob
  queue_as :default

  # Envoie des rappels pour tous les événements qui ont lieu dans 24h
  def perform
    # Trouver les événements publiés qui ont lieu dans 24h (±1h de fenêtre)
    events = Event.published
                  .upcoming
                  .where(start_at: 23.hours.from_now..25.hours.from_now)

    events.find_each do |event|
      # Envoyer un rappel à tous les participants actifs
      event.attendances.active.includes(:user, :event).find_each do |attendance|
        # Vérifier que l'utilisateur existe et a un email
        next unless attendance.user&.email.present?

        # Envoyer l'email de rappel
        EventMailer.event_reminder(attendance).deliver_later
      end
    end
  end
end

