# frozen_string_literal: true

require "rails_helper"

RSpec.describe CheckoutService do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create_user }
  let(:other_user) { create_user }
  let(:category) { create(:product_category) }
  let(:product) { create(:product, category: category) }
  let(:variant) do
    v = create(:product_variant, product: product, stock_qty: 10, is_active: true)
    Inventory.create!(product_variant: v, stock_qty: 10, reserved_qty: 0) unless v.inventory
    v.reload
  end

  def add_product_line!(qty: 1)
    CartLineService.add_product!(user: user, variant: variant, quantity: qty)
  end

  describe ".build_from_cart" do
    it "creates checkout with selected lines only" do
      line1 = add_product_line!
      membership = create(:membership, :pending, :with_health_questionnaire, user: user)
      line2 = CartLineService.add_membership!(user, membership: membership)

      checkout = described_class.build_from_cart(user, cart_line_ids: [ line1.id ], donation_cents: 0)

      expect(checkout.checkout_lines.count).to eq(1)
      expect(checkout.checkout_lines.first.cart_line_id).to eq(line1.id)
      expect(CartLine.exists?(line2.id)).to be(true)
    end

    it "raises EmptySelectionError when cart_line_ids is empty" do
      expect {
        described_class.build_from_cart(user, cart_line_ids: [], donation_cents: 0)
      }.to raise_error(CheckoutService::EmptySelectionError)
    end

    it "raises ExpiredLinesError when selection includes expired event line" do
      creator = create_user
      event = create_event(
        creator_user: creator,
        status: "published",
        payment_required: true,
        price_cents: 500,
        max_participants: 20,
        start_at: 1.week.from_now
      )
      attendance = create(:attendance, user: user, event: event, status: :pending, payment_expires_at: 15.minutes.from_now)
      line = create(:cart_line, :event_registration, user: user, reference: attendance, expires_at: 1.minute.ago)

      expect {
        described_class.build_from_cart(user, cart_line_ids: [ line.id ], donation_cents: 0)
      }.to raise_error(CheckoutService::ExpiredLinesError)
    end

    it "raises ForbiddenError when line belongs to another user" do
      line = add_product_line!
      other_line = CartLineService.add_product!(user: other_user, variant: variant, quantity: 1)

      expect {
        described_class.build_from_cart(user, cart_line_ids: [ other_line.id ], donation_cents: 0)
      }.to raise_error(CheckoutService::ForbiddenError)
    end

    it "validates stock for product lines in selection" do
      line = add_product_line!(qty: 1)
      variant.inventory.update!(stock_qty: 0, reserved_qty: 0)

      expect {
        described_class.build_from_cart(user, cart_line_ids: [ line.id ], donation_cents: 0)
      }.to raise_error(CheckoutService::InsufficientStockError)
    end

    it "validates event seat still held for event lines" do
      creator = create_user
      event = create_event(
        creator_user: creator,
        status: "published",
        payment_required: true,
        price_cents: 500,
        max_participants: 20,
        start_at: 1.week.from_now
      )
      attendance = create(:attendance, user: user, event: event, status: :pending, payment_expires_at: 15.minutes.from_now)
      line = CartLineService.add_event_registration!(user: user, attendance: attendance, event: event)

      checkout = described_class.build_from_cart(user, cart_line_ids: [ line.id ], donation_cents: 0)
      expect(checkout.checkout_lines.first.line_type).to eq("event_registration")
    end

    it "validates membership health questionnaire complete" do
      membership = create(:membership, :pending, user: user)
      expect {
        CartLineService.add_membership!(user, membership: membership)
      }.to raise_error(CartLineService::HealthQuestionnaireIncompleteError)
    end

    it "creates pending Order with OrderItems for product subset only" do
      line = add_product_line!(qty: 2)

      expect {
        described_class.build_from_cart(user, cart_line_ids: [ line.id ], donation_cents: 0)
      }.to change(Order, :count).by(1)

      order = Order.last
      expect(order.status).to eq("pending")
      expect(order.order_items.count).to eq(1)
      expect(order.order_items.first.quantity).to eq(2)
    end

    it "does not include unselected lines in checkout_lines" do
      line1 = add_product_line!
      variant2 = create(:product_variant, product: product, stock_qty: 5, is_active: true)
      line2 = CartLineService.add_product!(user: user, variant: variant2, quantity: 1)

      checkout = described_class.build_from_cart(user, cart_line_ids: [ line1.id ], donation_cents: 0)
      expect(checkout.checkout_lines.pluck(:cart_line_id)).to eq([ line1.id ])
    end

    it "stores donation_cents on checkout" do
      line = add_product_line!
      checkout = described_class.build_from_cart(user, cart_line_ids: [ line.id ], donation_cents: 300)
      expect(checkout.donation_cents).to eq(300)
    end

    it "sets total_cents to subtotal plus donation" do
      line = add_product_line!
      checkout = described_class.build_from_cart(user, cart_line_ids: [ line.id ], donation_cents: 500)
      expect(checkout.total_cents).to eq(checkout.subtotal_cents + 500)
    end

    context "partial payment" do
      it "leaves unselected cart lines in cart after checkout creation" do
        line1 = add_product_line!
        variant2 = create(:product_variant, product: product, stock_qty: 5, is_active: true)
        line2 = CartLineService.add_product!(user: user, variant: variant2, quantity: 1)

        described_class.build_from_cart(user, cart_line_ids: [ line1.id ], donation_cents: 0)

        expect(CartLine.exists?(line1.id)).to be(true)
        expect(CartLine.exists?(line2.id)).to be(true)
      end
    end
  end
end
