# frozen_string_literal: true

# Non-persisted checkout doubles for Wave 0 HelloAsso payload spike (Checkout AR model lands in Wave 4).
UnifiedCheckoutDouble = Struct.new(:id, :subtotal_cents, :donation_cents, :total_cents, :checkout_lines, keyword_init: true) do
  def checkout_lines
    self[:checkout_lines] || []
  end
end

UnifiedCheckoutLineDouble = Struct.new(
  :id, :line_type, :reference_type, :reference_id,
  :amount_cents, :label, :quantity, :metadata,
  keyword_init: true
) do
  def metadata
    self[:metadata] || {}
  end
end
