# frozen_string_literal: true

class CartSessionMergeService
  def self.merge!(user, session_cart:)
    return if session_cart.blank?

    session_cart.each do |variant_id_str, qty|
      quantity = qty.to_i
      next if quantity <= 0

      variant = ProductVariant.includes(:product, :inventory).find_by(id: variant_id_str.to_i)
      next unless variant

      CartLineService.add_product!(user: user, variant: variant, quantity: quantity)
    end
  end
end
