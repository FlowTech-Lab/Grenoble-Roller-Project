# frozen_string_literal: true

# Releases expired cart lines (event registration holds) and frees seats.
# Scheduled every 2 minutes via config/recurring.yml.
class ExpireCartLinesJob < ApplicationJob
  queue_as :default

  limits_concurrency to: 1, key: -> { :expire_cart_lines }

  def perform
    CartLineService.expire_stale!
    Rails.logger.info("[ExpireCartLinesJob] Expired cart lines processed.")
  end
end
