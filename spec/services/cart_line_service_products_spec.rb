# frozen_string_literal: true

require "rails_helper"

RSpec.describe CartLineService, "product cart lines" do
  let(:user) { create(:user) }
  let(:category) { create(:product_category) }
  let(:product) { create(:product, category: category) }
  let(:variant) do
    v = create(:product_variant, product: product, stock_qty: 10, price_cents: 2000, is_active: true)
    inv = v.inventory || Inventory.create!(product_variant: v, stock_qty: 10, reserved_qty: 0)
    inv.update!(stock_qty: 10, reserved_qty: 0)
    v.reload
  end

  describe ".add_product!" do
    it "creates a cart line for the user" do
      line = described_class.add_product!(user: user, variant: variant, quantity: 2)

      expect(line).to be_persisted
      expect(line.user).to eq(user)
      expect(line.quantity).to eq(2)
      expect(line.amount_cents).to eq(2000)
    end

    it "merges quantity when a line already exists for the variant" do
      described_class.add_product!(user: user, variant: variant, quantity: 2)
      line = described_class.add_product!(user: user, variant: variant, quantity: 3)

      expect(line.quantity).to eq(5)
      expect(CartLine.where(user: user, reference: variant).count).to eq(1)
    end

    it "caps quantity to available inventory stock" do
      variant.inventory.update!(stock_qty: 10, reserved_qty: 8)

      line = described_class.add_product!(user: user, variant: variant, quantity: 5)

      expect(line.quantity).to eq(2)
    end

    it "raises when variant is inactive" do
      variant.update!(is_active: false)

      expect {
        described_class.add_product!(user: user, variant: variant, quantity: 1)
      }.to raise_error(CartLineService::InactiveVariantError)
    end
  end

  describe ".update_product_quantity!" do
    it "updates quantity on existing line" do
      described_class.add_product!(user: user, variant: variant, quantity: 2)
      line = described_class.update_product_quantity!(user, variant: variant, quantity: 4)

      expect(line.quantity).to eq(4)
    end

    it "removes line when quantity is zero" do
      described_class.add_product!(user: user, variant: variant, quantity: 2)
      result = described_class.update_product_quantity!(user, variant: variant, quantity: 0)

      expect(result).to be_nil
      expect(CartLine.where(user: user, reference: variant)).to be_empty
    end
  end

  describe ".remove!" do
    it "destroys the cart line belonging to the user" do
      line = create(:cart_line, user: user, reference: variant)

      described_class.remove!(user, cart_line_id: line.id)

      expect(CartLine.exists?(line.id)).to be(false)
    end

    it "raises when line belongs to another user" do
      other_user = create(:user)
      line = create(:cart_line, user: other_user, reference: variant)

      expect {
        described_class.remove!(user, cart_line_id: line.id)
      }.to raise_error(CartLineService::UnauthorizedError)
    end
  end

  describe ".clear!" do
    it "removes all cart lines for the user" do
      create(:cart_line, user: user, reference: variant)
      other_variant = create(:product_variant, product: product, is_active: true)
      create(:cart_line, user: user, reference: other_variant)

      described_class.clear!(user)

      expect(CartLine.where(user: user)).to be_empty
    end
  end

  describe ".list" do
    it "returns lines ordered by created_at" do
      first = create(:cart_line, user: user, reference: variant, created_at: 2.days.ago)
      second_variant = create(:product_variant, product: product, is_active: true)
      second = create(:cart_line, user: user, reference: second_variant, created_at: 1.day.ago)

      expect(described_class.list(user).map(&:id)).to eq([ first.id, second.id ])
    end

    it "preloads product variant and product" do
      create(:cart_line, user: user, reference: variant)

      lines = described_class.list(user)
      expect(lines.first.association(:reference)).to be_loaded
      expect(lines.first.reference.association(:product)).to be_loaded
    end

    it "excludes expired lines by default when option set" do
      create(:cart_line, user: user, reference: variant, expires_at: 1.minute.ago)
      active = create(:cart_line, user: user, reference: create(:product_variant, product: product, is_active: true), expires_at: 10.minutes.from_now)

      expect(described_class.list(user)).to contain_exactly(active)
    end
  end

  describe ".count" do
    it "returns the number of cart lines" do
      create(:cart_line, user: user, reference: variant)
      create(:cart_line, user: user, reference: create(:product_variant, product: product, is_active: true))

      expect(described_class.count(user)).to eq(2)
    end
  end

  describe ".total_cents" do
    it "sums subtotal_cents of all lines" do
      create(:cart_line, user: user, reference: variant, amount_cents: 2000, quantity: 2)
      other = create(:product_variant, product: product, is_active: true, price_cents: 1000)
      create(:cart_line, user: user, reference: other, amount_cents: 1000, quantity: 1)

      expect(described_class.total_cents(user)).to eq(5000)
    end
  end

  describe ".expire_stale!" do
    it "deletes lines with expires_at in the past" do
      expired = create(:cart_line, user: user, reference: variant, expires_at: 1.minute.ago)

      described_class.expire_stale!

      expect(CartLine.exists?(expired.id)).to be(false)
    end

    it "does not delete lines without expires_at" do
      active = create(:cart_line, user: user, reference: variant, expires_at: nil)

      described_class.expire_stale!

      expect(CartLine.exists?(active.id)).to be(true)
    end
  end
end
