# frozen_string_literal: true

module AdminPanel
  module NotifiesDiscord
    extend ActiveSupport::Concern

    private

    def notify_discord(event_key, source, actor: current_user)
      NotificationDispatchService.dispatch(event_key, source: source, actor: actor)
    end
  end
end
