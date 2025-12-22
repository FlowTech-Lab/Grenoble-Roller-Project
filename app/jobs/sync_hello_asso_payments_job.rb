# Job pour synchroniser les paiements HelloAsso en attente
# Exécuté toutes les 5 minutes via Solid Queue recurring jobs
class SyncHelloAssoPaymentsJob < ApplicationJob
  queue_as :default

  # Empêcher l'exécution simultanée (une seule instance à la fois)
  # Important pour éviter les race conditions lors de la synchronisation
  limits_concurrency to: 1, key: -> { :sync_helloasso_payments }

  def perform
    Payment
      .where(provider: "helloasso", status: "pending")
      .where("created_at > ?", 1.day.ago)
      .find_each do |payment|
        begin
          HelloassoService.fetch_and_update_payment(payment)
        rescue StandardError => e
          Rails.logger.error(
            "[SyncHelloAssoPaymentsJob] Failed to sync payment ##{payment.id}: " \
            "#{e.class} - #{e.message}"
          )
          Rails.logger.error(e.backtrace.join("\n"))
          Sentry.capture_exception(e, extra: { payment_id: payment.id }) if defined?(Sentry)
        end
      end

    Rails.logger.info("[SyncHelloAssoPaymentsJob] ✅ HelloAsso sync completed.")
  end
end
