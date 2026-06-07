# frozen_string_literal: true

module UnifiedCart
  def self.enabled?
    ENV.fetch("UNIFIED_CART_ENABLED", "false") == "true"
  end
end
