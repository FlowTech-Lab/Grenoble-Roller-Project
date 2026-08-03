# frozen_string_literal: true

# Persist outbound email metadata for /admin-panel/mail-logs.
# Solid Queue finished jobs are purged hourly; this table keeps history.
Rails.application.config.after_initialize do
  next if defined?(Rails::Console) && ENV["SKIP_EMAIL_LOG_SUBSCRIBER"] == "1"

  ActiveSupport::Notifications.subscribe("enqueue.active_job") do |event|
    job = event.payload[:job]
    next unless job.class.name == "ActionMailer::MailDeliveryJob"

    OutboundEmailLog.record_enqueue!(job)
  rescue StandardError => e
    Rails.logger.error("OutboundEmailLog enqueue failed: #{e.class} - #{e.message}")
  end

  ActiveSupport::Notifications.subscribe("perform.active_job") do |event|
    job = event.payload[:job]
    next unless job.class.name == "ActionMailer::MailDeliveryJob"

    if event.payload[:exception].present?
      OutboundEmailLog.mark_failed!(
        active_job_id: job.job_id,
        solid_queue_job_id: job.provider_job_id,
        error_message: event.payload[:exception].message
      )
    else
      OutboundEmailLog.mark_sent!(
        active_job_id: job.job_id,
        solid_queue_job_id: job.provider_job_id
      )
    end
  rescue StandardError => e
    Rails.logger.error("OutboundEmailLog perform failed: #{e.class} - #{e.message}")
  end

  ActiveSupport::Notifications.subscribe("retry_stopped.active_job") do |event|
    job = event.payload[:job]
    next unless job.class.name == "ActionMailer::MailDeliveryJob"

    OutboundEmailLog.mark_failed!(
      active_job_id: job.job_id,
      solid_queue_job_id: job.provider_job_id,
      error_message: event.payload[:error].to_s
    )
  rescue StandardError => e
    Rails.logger.error("OutboundEmailLog retry_stopped failed: #{e.class} - #{e.message}")
  end
end
