# Job pour mettre à jour les adhésions expirées
# Exécuté tous les jours à minuit via Solid Queue recurring jobs
class UpdateExpiredMembershipsJob < ApplicationJob
  queue_as :default

  def perform
    expired_count = 0

    # Filtrer uniquement les adhésions qui n'ont pas encore reçu l'email d'expiration
    Membership
      .where(status: :active)
      .where("end_date < ?", Date.current)
      .where(expired_email_sent_at: nil)
      .find_each do |membership|
        begin
          # Mettre à jour le statut et le flag (utiliser update_column pour éviter les callbacks)
          membership.update_column(:status, :expired)
          membership.update_column(:expired_email_sent_at, Time.zone.now)
          expired_count += 1

          # Envoyer un email d'expiration (utiliser deliver_later pour traitement asynchrone avec retry automatique)
          MembershipMailer.expired(membership).deliver_later if defined?(MembershipMailer)
        rescue StandardError => e
          Rails.logger.error("[UpdateExpiredMembershipsJob] Failed to process membership ##{membership.id}: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
          Sentry.capture_exception(e, extra: { membership_id: membership.id }) if defined?(Sentry)
        end
      end

    Rails.logger.info("[UpdateExpiredMembershipsJob] ✅ #{expired_count} adhésion(s) expirée(s) mise(s) à jour.")
  end
end
