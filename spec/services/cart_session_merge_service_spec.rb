# frozen_string_literal: true

require "rails_helper"

RSpec.describe CartSessionMergeService do
  let(:user) { create(:user) }
  let(:category) { create(:product_category) }
  let(:product) { create(:product, category: category) }
  let(:variant) do
    create(:product_variant, product: product, stock_qty: 10, price_cents: 2000, is_active: true).tap do |v|
      v.inventory || Inventory.create!(product_variant: v, stock_qty: 10, reserved_qty: 0)
    end
  end

  describe ".merge!" do
    it "creates CartLines from session cart hash" do
      session_cart = { variant.id.to_s => 2 }

      described_class.merge!(user, session_cart: session_cart)

      line = CartLine.find_by(user: user, reference: variant)
      expect(line).to be_present
      expect(line.quantity).to eq(2)
    end

    it "does nothing when session cart is empty" do
      expect {
        described_class.merge!(user, session_cart: {})
      }.not_to change(CartLine, :count)
    end

    it "merges quantities with existing DB lines for same variant" do
      create(:cart_line, user: user, reference: variant, quantity: 2)
      session_cart = { variant.id.to_s => 3 }

      described_class.merge!(user, session_cart: session_cart)

      line = CartLine.find_by(user: user, reference: variant)
      expect(line.quantity).to eq(5)
    end
  end
end
