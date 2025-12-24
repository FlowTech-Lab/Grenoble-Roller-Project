# Job pour envoyer les rappels de renouvellement d'adhésion
# Exécuté tous les jours à 9h via Solid Queue recurring jobs
class SendRenewalRemindersJob < ApplicationJob
  queue_as :default

  def perform
    reminder_date = 30.days.from_now.to_date
    sent_count = 0

    # Filtrer uniquement les adhésions qui n'ont pas encore reçu le rappel de renouvellement
    Membership
      .where(status: :active)
      .where(end_date: reminder_date)
      .where(renewal_reminder_sent_at: nil)
      .find_each do |membership|
        begin
          # Utiliser deliver_later pour traitement asynchrone avec retry automatique
          MembershipMailer.renewal_reminder(membership).deliver_later if defined?(MembershipMailer)
          # Mettre à jour le flag pour éviter les doublons (utiliser update_column pour éviter les callbacks)
          membership.update_column(:renewal_reminder_sent_at, Time.zone.now)
          sent_count += 1
        rescue StandardError => e
          Rails.logger.error("[SendRenewalRemindersJob] Failed to process membership ##{membership.id}: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
          Sentry.capture_exception(e, extra: { membership_id: membership.id }) if defined?(Sentry)
        end
      end

    Rails.logger.info("[SendRenewalRemindersJob] ✅ #{sent_count} rappel(s) de renouvellement envoyé(s).")
  end
end
