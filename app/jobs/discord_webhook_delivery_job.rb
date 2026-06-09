# frozen_string_literal: true

class DiscordWebhookDeliveryJob < ApplicationJob
  queue_as :default

  def perform(notification_channel_id, payload, notification_delivery_id)
    channel = NotificationChannel.find_by(id: notification_channel_id)
    delivery = NotificationDelivery.find_by(id: notification_delivery_id)
    return unless channel && delivery

    webhook_url = channel.webhook_url
    if webhook_url.blank?
      mark_failed!(delivery, http_code: nil, error_message: "Webhook URL not configured")
      return
    end

    DiscordWebhookClient.post!(webhook_url, payload)
    delivery.update!(
      status: "delivered",
      http_code: 204,
      error_message: nil,
      delivered_at: Time.current
    )
  rescue DiscordWebhookClient::DeliveryError => e
    mark_failed!(delivery, http_code: e.http_code, error_message: e.message)
    raise
  rescue StandardError => e
    mark_failed!(delivery, http_code: nil, error_message: e.message)
    raise
  end

  private

  def mark_failed!(delivery, http_code:, error_message:)
    delivery&.update!(
      status: "failed",
      http_code: http_code,
      error_message: error_message
    )
  end
end
