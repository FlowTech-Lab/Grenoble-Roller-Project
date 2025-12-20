# Job pour envoyer un rapport des participants et matériel demandé
# pour chaque initiation du jour à 7h00 (uniquement en production)
class InitiationParticipantsReportJob < ApplicationJob
  queue_as :default

  # Envoie un rapport pour toutes les initiations qui ont lieu aujourd'hui
  # Exécuté chaque jour à 7h00, uniquement en production
  def perform
    # Ne s'exécute qu'en production (ou si FORCE_INITIATION_REPORT=true pour tests)
    return unless Rails.env.production? || ENV['FORCE_INITIATION_REPORT'] == 'true'

    # Trouver toutes les initiations du jour (aujourd'hui entre 00:00 et 23:59:59)
    # qui n'ont pas encore reçu de rapport aujourd'hui (prévention doublons)
    today_start = Time.zone.now.beginning_of_day
    today_end = today_start.end_of_day

    initiations = Event::Initiation
                   .published
                   .where(start_at: today_start..today_end)
                   .where(participants_report_sent_at: nil)
                   .includes(:attendances, :creator_user) # Éviter N+1 queries

    # Si aucune initiation aujourd'hui, ne rien faire
    return if initiations.empty?

    Rails.logger.info("[InitiationParticipantsReportJob] #{initiations.count} initiation(s) trouvée(s) pour aujourd'hui")

    # Envoyer un email pour chaque initiation
    initiations.find_each do |initiation|
      begin
        EventMailer.initiation_participants_report(initiation).deliver_later
        # Marquer comme envoyé pour éviter les doublons (utiliser update_column pour éviter les callbacks)
        initiation.update_column(:participants_report_sent_at, Time.zone.now)
        Rails.logger.info("[InitiationParticipantsReportJob] Email de rapport enqueued pour initiation ##{initiation.id} (#{initiation.title})")
      rescue StandardError => e
        Rails.logger.error("[InitiationParticipantsReportJob] Erreur lors de l'envoi du rapport pour initiation ##{initiation.id}: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        Sentry.capture_exception(e, extra: { initiation_id: initiation.id, initiation_title: initiation.title }) if defined?(Sentry)
      end
    end
  end
end
