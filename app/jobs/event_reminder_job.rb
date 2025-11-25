# Job pour envoyer des rappels la veille à 19h pour les événements du lendemain
class EventReminderJob < ApplicationJob
  queue_as :default

  # Envoie des rappels pour tous les événements qui ont lieu le lendemain
  # Exécuté chaque jour à 19h, envoie des rappels pour les événements du jour suivant
  def perform
    # Définir le début et la fin de demain (00:00:00 à 23:59:59)
    tomorrow_start = Time.zone.now.beginning_of_day + 1.day
    tomorrow_end = tomorrow_start.end_of_day

    # Trouver les événements publiés qui ont lieu demain (dans toute la journée)
    events = Event.published
                  .upcoming
                  .where(start_at: tomorrow_start..tomorrow_end)

    events.find_each do |event|
      # Envoyer un rappel uniquement aux participants actifs qui ont activé le rappel
      event.attendances.active
           .where(wants_reminder: true)
           .includes(:user, :event)
           .find_each do |attendance|
        # Vérifier que l'utilisateur existe et a un email
        next unless attendance.user&.email.present?

        # Envoyer l'email de rappel
        EventMailer.event_reminder(attendance).deliver_later
      end
    end
  end
end
