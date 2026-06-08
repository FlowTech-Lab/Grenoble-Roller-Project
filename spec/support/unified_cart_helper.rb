# frozen_string_literal: true

module UnifiedCartHelper
  def with_unified_cart_enabled
    previous = ENV["UNIFIED_CART_ENABLED"]
    ENV["UNIFIED_CART_ENABLED"] = "true"
    yield
  ensure
    if previous.nil?
      ENV.delete("UNIFIED_CART_ENABLED")
    else
      ENV["UNIFIED_CART_ENABLED"] = previous
    end
  end

  def with_unified_cart_disabled
    previous = ENV["UNIFIED_CART_ENABLED"]
    ENV["UNIFIED_CART_ENABLED"] = "false"
    yield
  ensure
    if previous.nil?
      ENV.delete("UNIFIED_CART_ENABLED")
    else
      ENV["UNIFIED_CART_ENABLED"] = previous
    end
  end
end

RSpec.configure do |config|
  config.include UnifiedCartHelper
end
