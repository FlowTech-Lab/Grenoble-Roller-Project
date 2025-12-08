# frozen_string_literal: true

# Service pour détecter les anomalies de sécurité liées aux confirmations email
class EmailSecurityService
  class << self
    # Détecter email scanner (auto-click < 10sec après envoi)
    def detect_email_scanner(user, ip, time_since_sent)
      return unless enabled?

      alert_data = {
        type: "email_scanner_detected",
        user_id: user.id,
        user_email: user.email,
        ip: ip,
        time_since_sent: time_since_sent.to_i,
        timestamp: Time.current,
        severity: "medium"
      }

      log_security_alert(alert_data)
      send_sentry_alert(alert_data) if sentry_enabled?
    end

    # Détecter attaque force brute sur tokens
    def detect_brute_force(ip, failure_count)
      return unless enabled?

      alert_data = {
        type: "confirmation_brute_force",
        ip: ip,
        failure_count: failure_count,
        timestamp: Time.current,
        severity: "high"
      }

      log_security_alert(alert_data)
      send_sentry_alert(alert_data) if sentry_enabled?
    end

    private

    def enabled?
      Rails.env.production? || Rails.env.staging?
    end

    def sentry_enabled?
      defined?(Sentry) && Sentry.configuration.dsn.present?
    end

    def log_security_alert(alert_data)
      Rails.logger.error(
        "🔒 SECURITY ALERT: #{alert_data[:type]} - " \
        "IP: #{alert_data[:ip]}, " \
        "Severity: #{alert_data[:severity]}, " \
        "Details: #{alert_data.except(:ip, :severity).to_json}"
      )
    end

    def send_sentry_alert(alert_data)
      return unless sentry_enabled?

      Sentry.capture_message(
        "Security Alert: #{alert_data[:type]}",
        level: alert_data[:severity] == "high" ? :error : :warning,
        extra: alert_data,
        tags: {
          security_alert: true,
          alert_type: alert_data[:type],
          severity: alert_data[:severity]
        }
      )
    end
  end
end
