# frozen_string_literal: true

class NotificationChannelSampleAllJob < ApplicationJob
  queue_as :default

  def perform(notification_channel_id, actor_id = nil)
    channel = NotificationChannel.find_by(id: notification_channel_id)
    return unless channel&.webhook_configured?

    actor = User.find_by(id: actor_id) if actor_id.present?
    service = NotificationChannelSampleService.new(channel: channel, actor: actor)
    results = service.send_all!

    ok_count = results.count { |r| r[:status] == :ok }
    error_count = results.count { |r| r[:status] == :error }

    Rails.logger.info(
      "[NotificationChannelSampleAllJob] channel=#{channel.id} ok=#{ok_count} errors=#{error_count}"
    )

    if error_count.positive?
      failed = results.select { |r| r[:status] == :error }.map { |r| r[:key] }.join(", ")
      Rails.logger.warn("[NotificationChannelSampleAllJob] failures: #{failed}")
    end
  end
end
