# frozen_string_literal: true

class NotificationChannelSampleService
  class DeliveryError < StandardError
    attr_reader :event_key, :cause

    def initialize(event_key, cause)
      super("#{event_key}: #{cause.message}")
      @event_key = event_key
      @cause = cause
    end
  end

  DEFAULT_DELAY_SECONDS = 1.0

  def initialize(channel:, actor: nil)
    @channel = channel
    @actor = actor || NotificationSampleSourceService.sample_actor
  end

  def send_event!(event_key)
    raise ArgumentError, "event_key required" if event_key.blank?

    definition = NotificationEventRegistry.find(event_key)
    raise NotificationSampleSourceService::MissingSampleDataError, "Événement inconnu: #{event_key}" unless definition

    source = NotificationSampleSourceService.source_for(event_key, channel: @channel)
    payload = NotificationEventRegistry.build_payload(event_key, source: source, actor: actor_for(event_key))
    raise NotificationSampleSourceService::MissingSampleDataError, "Payload vide pour #{event_key}" if payload.blank?

    post_sample_payload!(sample_payload(payload, event_key, definition.label))
  end

  def post_sample_payload!(payload, attempts: 0)
    DiscordWebhookClient.post!(@channel.webhook_url, payload)
  rescue DiscordWebhookClient::DeliveryError => e
    if e.rate_limited? && attempts < 3
      sleep(e.retry_after.presence || 1.5)
      post_sample_payload!(payload, attempts: attempts + 1)
    else
      raise e
    end
  end

  def send_all!(delay: DEFAULT_DELAY_SECONDS)
    results = []

    NotificationEventRegistry.all.each do |definition|
      next if definition.key == "test.ping"

      begin
        send_event!(definition.key)
        results << { key: definition.key, label: definition.label, status: :ok }
      rescue StandardError => e
        results << { key: definition.key, label: definition.label, status: :error, message: e.message }
      end

      sleep(delay) if delay.positive?
    end

    results
  end

  private

  def actor_for(event_key)
    return nil if event_key == "maintenance.toggled"

    @actor
  end

  def sample_payload(payload, event_key, label)
    payload = payload.deep_dup
    embed = payload[:embeds]&.first
    return payload unless embed

    embed[:title] = "[QA] #{embed[:title]}"
    embed[:footer] = { text: "Échantillon QA — #{label} (#{event_key})" }
    payload
  end
end
