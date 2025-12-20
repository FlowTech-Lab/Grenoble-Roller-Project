namespace :memberships do
  desc "Update expired memberships (run daily)"
  task update_expired: :environment do
    expired_count = 0

    # Filtrer uniquement les adhésions qui n'ont pas encore reçu l'email d'expiration
    Membership
      .where(status: :active)
      .where("end_date < ?", Date.current)
      .where(expired_email_sent_at: nil)
      .find_each do |membership|
        # Mettre à jour le statut et le flag (utiliser update_column pour éviter les callbacks)
        membership.update_column(:status, :expired)
        membership.update_column(:expired_email_sent_at, Time.zone.now)
        expired_count += 1

        # Envoyer un email d'expiration (si MembershipMailer existe)
        # Utiliser deliver_later pour traitement asynchrone avec retry automatique
        begin
          MembershipMailer.expired(membership).deliver_later if defined?(MembershipMailer)
        rescue StandardError => e
          Rails.logger.error("[Memberships] Failed to queue expired email for membership ##{membership.id}: #{e.message}")
          Sentry.capture_exception(e, extra: { membership_id: membership.id, task: "update_expired" }) if defined?(Sentry) && Sentry.configuration.dsn.present?
        end
      end

    Rails.logger.info("✅ #{expired_count} adhésion(s) expirée(s) mise(s) à jour.")
  end

  desc "Send renewal reminders (30 days before expiry)"
  task send_renewal_reminders: :environment do
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
          Rails.logger.error("[Memberships] Failed to queue renewal reminder for membership ##{membership.id}: #{e.message}")
          Sentry.capture_exception(e, extra: { membership_id: membership.id, task: "send_renewal_reminders" }) if defined?(Sentry) && Sentry.configuration.dsn.present?
        end
      end

    Rails.logger.info("✅ #{sent_count} rappel(s) de renouvellement envoyé(s).")
  end

  desc "Check minor authorizations (run weekly)"
  task check_minor_authorizations: :environment do
    pending_count = 0

    Membership
      .where(is_minor: true)
      .where(parent_authorization: false)
      .where(status: [ :pending, :active ])
      .find_each do |membership|
        # Log pour suivi admin
        Rails.logger.warn(
          "[Memberships] Membership ##{membership.id} (User ##{membership.user_id}) " \
          "requires parent authorization but it's missing."
        )
        pending_count += 1
      end

    Rails.logger.info("✅ #{pending_count} adhésion(s) mineur(s) nécessitant une autorisation parentale.")
  end

  desc "Check medical certificates (run weekly)"
  task check_medical_certificates: :environment do
    pending_count = 0

    Membership
      .where(health_questionnaire_status: "medical_required")
      .where(medical_certificate_provided: false)
      .where(status: [ :pending, :active ])
      .find_each do |membership|
        # Log pour suivi admin
        Rails.logger.warn(
          "[Memberships] Membership ##{membership.id} (User ##{membership.user_id}) " \
          "requires medical certificate but it's missing."
        )
        pending_count += 1
      end

    Rails.logger.info("✅ #{pending_count} adhésion(s) nécessitant un certificat médical.")
  end
end
