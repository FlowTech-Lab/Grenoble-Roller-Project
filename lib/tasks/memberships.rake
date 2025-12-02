namespace :memberships do
  desc "Update expired memberships (run daily)"
  task update_expired: :environment do
    expired_count = 0

    Membership
      .where(status: :active)
      .where("end_date < ?", Date.current)
      .find_each do |membership|
        membership.update!(status: :expired)
        expired_count += 1

        # Envoyer un email d'expiration (si MembershipMailer existe)
        begin
          MembershipMailer.expired(membership).deliver_now if defined?(MembershipMailer)
        rescue StandardError => e
          Rails.logger.error("[Memberships] Failed to send expired email for membership ##{membership.id}: #{e.message}")
        end
      end

    puts "✅ #{expired_count} adhésion(s) expirée(s) mise(s) à jour."
  end

  desc "Send renewal reminders (30 days before expiry)"
  task send_renewal_reminders: :environment do
    reminder_date = 30.days.from_now.to_date
    sent_count = 0

    Membership
      .where(status: :active)
      .where(end_date: reminder_date)
      .find_each do |membership|
        begin
          MembershipMailer.renewal_reminder(membership).deliver_now if defined?(MembershipMailer)
          sent_count += 1
        rescue StandardError => e
          Rails.logger.error("[Memberships] Failed to send renewal reminder for membership ##{membership.id}: #{e.message}")
        end
      end

    puts "✅ #{sent_count} rappel(s) de renouvellement envoyé(s)."
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

    puts "✅ #{pending_count} adhésion(s) mineur(s) nécessitant une autorisation parentale."
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

    puts "✅ #{pending_count} adhésion(s) nécessitant un certificat médical."
  end
end
