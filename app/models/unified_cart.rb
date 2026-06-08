# frozen_string_literal: true

# Feature flag for account-based cart and unified checkout (DR-001).
# Plain module in app/models/ so Zeitwerk autoloads it for helpers, views, and controllers.
module UnifiedCart
  def self.enabled?
    ENV.fetch("UNIFIED_CART_ENABLED", "false") == "true"
  end
end
