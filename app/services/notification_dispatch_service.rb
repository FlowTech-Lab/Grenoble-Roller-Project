# frozen_string_literal: true

class NotificationDispatchService
  class << self
    def dispatch(event_key, source:, actor: nil, skip_idempotency: false)
      return unless notifications_enabled?
      return if NotificationEventRegistry.find(event_key).nil?

      payload = NotificationEventRegistry.build_payload(event_key, source: source, actor: actor)
      return if payload.blank?

      source_type, source_id = source_reference(source)
      return if source_type.blank? || source_id.blank?

      matching_channels(event_key).find_each do |channel|
        enqueue_for_channel(
          channel: channel,
          event_key: event_key,
          source_type: source_type,
          source_id: source_id,
          payload: payload,
          skip_idempotency: skip_idempotency
        )
      end
    end

    def dispatch_payment_succeeded!(payment)
      return unless notifications_enabled?

      payment.orders.where(status: "paid").find_each do |order|
        dispatch("order.paid", source: order)
      end

      activated_memberships(payment).find_each do |membership|
        dispatch("membership.activated", source: membership)
      end

      fulfilled_attendances(payment).find_each do |attendance|
        dispatch("event_registration.paid", source: attendance)
      end
    end

    def notifications_enabled?
      return false unless NotificationChannel.where(enabled: true).exists?

      Rails.env.production? || ENV["ALLOW_DISCORD_NOTIFICATIONS"] == "true"
    end

    private

    def matching_channels(event_key)
      NotificationChannel
        .where(enabled: true)
        .joins(:notification_subscriptions)
        .where(notification_subscriptions: { event_key: event_key, enabled: true })
        .distinct
    end

    def enqueue_for_channel(channel:, event_key:, source_type:, source_id:, payload:, skip_idempotency:)
      delivery = nil

      unless skip_idempotency
        delivery = NotificationDelivery.find_by(
          notification_channel_id: channel.id,
          event_key: event_key,
          source_type: source_type,
          source_id: source_id
        )
        return if delivery
      end

      delivery = NotificationDelivery.create!(
        notification_channel: channel,
        event_key: event_key,
        source_type: source_type,
        source_id: source_id,
        status: "pending"
      )

      DiscordWebhookDeliveryJob.perform_later(channel.id, payload.deep_stringify_keys, delivery.id)
    rescue ActiveRecord::RecordNotUnique
      nil
    end

    def source_reference(source)
      if source.respond_to?(:model_name) && source.respond_to?(:id)
        [ source.model_name.name, source.id ]
      elsif source.is_a?(Hash)
        [ source[:source_type].to_s, source[:source_id].to_i ]
      else
        [ source.class.name, source.try(:id) || 0 ]
      end
    end

    def activated_memberships(payment)
      ids = []
      ids << payment.membership.id if payment.membership.present?
      ids.concat(payment.memberships.where(status: :active).pluck(:id))
      Membership.where(id: ids.compact.uniq, status: :active)
    end

    def fulfilled_attendances(payment)
      attendance_ids = payment.attendances.where(status: %w[registered paid]).pluck(:id)

      payment.checkouts.includes(checkout_lines: :reference).find_each do |checkout|
        checkout.checkout_lines.each do |line|
          next unless line.line_type == "event_registration"
          next unless line.reference.is_a?(Attendance)

          attendance_ids << line.reference.id if line.reference.registered? || line.reference.paid?
        end
      end

      Attendance.where(id: attendance_ids.compact.uniq)
    end
  end
end
