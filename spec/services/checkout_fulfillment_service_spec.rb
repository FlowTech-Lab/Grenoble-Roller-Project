# frozen_string_literal: true

require "rails_helper"

RSpec.describe CheckoutFulfillmentService do
  include ActiveJob::TestHelper

  let(:user) { create_user }
  let(:payment) do
    create(:payment, provider: "helloasso", status: "succeeded", amount_cents: 5000, currency: "EUR")
  end

  describe ".fulfill!" do
    context "product lines" do
      it "marks related order as paid" do
        order = create(:order, user: user, status: "pending", total_cents: 2000)
        checkout = create(:checkout, user: user, status: :processing)
        create(
          :checkout_line,
          checkout: checkout,
          line_type: :product_variant,
          reference: create(:product_variant),
          metadata: { "order_id" => order.id }
        )
        checkout.update!(metadata: { "order_id" => order.id })

        described_class.fulfill!(checkout, payment: payment)

        expect(order.reload.status).to eq("paid")
        expect(checkout.reload).to be_paid
      end

      it "does not double-reserve stock" do
        variant = create(:product_variant, stock_qty: 10, is_active: true)
        inv = variant.inventory
        inv.update!(stock_qty: 10, reserved_qty: 2)
        order = create(:order, user: user, status: "pending", total_cents: 2000)
        create(:order_item, order: order, variant: variant, quantity: 2, unit_price_cents: 1000)
        checkout = create(:checkout, user: user, status: :processing, metadata: { "order_id" => order.id })
        create(:checkout_line, checkout: checkout, line_type: :product_variant, reference: variant, metadata: { "order_id" => order.id })

        expect {
          described_class.fulfill!(checkout, payment: payment)
        }.not_to change { inv.reload.reserved_qty }
      end
    end

    context "membership lines" do
      it "activates memberships" do
        membership = create(:membership, :pending, :with_health_questionnaire, user: user)
        checkout = create(:checkout, user: user, status: :processing)
        create(:checkout_line, checkout: checkout, line_type: :membership, reference: membership)

        described_class.fulfill!(checkout, payment: payment)

        expect(membership.reload).to be_active
      end

      it "links payment_id on memberships" do
        membership = create(:membership, :pending, :with_health_questionnaire, user: user)
        checkout = create(:checkout, user: user, status: :processing)
        create(:checkout_line, checkout: checkout, line_type: :membership, reference: membership)

        described_class.fulfill!(checkout, payment: payment)

        expect(membership.reload.payment_id).to eq(payment.id)
      end
    end

    context "event lines" do
      let(:creator) { create_user }
      let(:event) do
        create_event(
          creator_user: creator,
          status: "published",
          payment_required: true,
          price_cents: 800,
          max_participants: 20,
          start_at: 1.week.from_now
        )
      end

      it "sets attendance status to registered" do
        attendance = create(:attendance, user: user, event: event, status: :pending, payment_expires_at: 10.minutes.from_now)
        checkout = create(:checkout, user: user, status: :processing)
        create(:checkout_line, checkout: checkout, line_type: :event_registration, reference: attendance)

        described_class.fulfill!(checkout, payment: payment)

        expect(attendance.reload).to be_registered
      end

      it "clears payment_expires_at" do
        attendance = create(:attendance, user: user, event: event, status: :pending, payment_expires_at: 10.minutes.from_now)
        checkout = create(:checkout, user: user, status: :processing)
        create(:checkout_line, checkout: checkout, line_type: :event_registration, reference: attendance)

        described_class.fulfill!(checkout, payment: payment)

        expect(attendance.reload.payment_expires_at).to be_nil
      end

      it "links payment_id on attendance" do
        attendance = create(:attendance, user: user, event: event, status: :pending, payment_expires_at: 10.minutes.from_now)
        checkout = create(:checkout, user: user, status: :processing)
        create(:checkout_line, checkout: checkout, line_type: :event_registration, reference: attendance)

        described_class.fulfill!(checkout, payment: payment)

        expect(attendance.reload.payment_id).to eq(payment.id)
      end
    end

    context "partial checkout" do
      it "removes only fulfilled cart lines" do
        cart_line = create(:cart_line, user: user)
        other_line = create(:cart_line, user: user)
        checkout = create(:checkout, user: user, status: :processing)
        create(:checkout_line, checkout: checkout, cart_line_id: cart_line.id, reference: cart_line.reference)

        described_class.fulfill!(checkout, payment: payment)

        expect(CartLine.exists?(cart_line.id)).to be(false)
        expect(CartLine.exists?(other_line.id)).to be(true)
      end

      it "leaves unselected cart lines untouched" do
        kept = create(:cart_line, user: user)
        paid_line = create(:cart_line, user: user)
        checkout = create(:checkout, user: user, status: :processing)
        create(:checkout_line, checkout: checkout, cart_line_id: paid_line.id, reference: paid_line.reference)

        described_class.fulfill!(checkout, payment: payment)

        expect(CartLine.exists?(kept.id)).to be(true)
      end
    end

    it "is idempotent when called twice with same checkout" do
      membership = create(:membership, :pending, :with_health_questionnaire, user: user)
      checkout = create(:checkout, user: user, status: :processing)
      create(:checkout_line, checkout: checkout, line_type: :membership, reference: membership)

      described_class.fulfill!(checkout, payment: payment)
      expect {
        described_class.fulfill!(checkout.reload, payment: payment)
      }.not_to change { membership.reload.updated_at }
    end

    it "sends OrderMailer.order_confirmation after product fulfillment" do
      order = create(:order, user: user, status: "pending", total_cents: 2000)
      checkout = create(:checkout, user: user, status: :processing, metadata: { "order_id" => order.id })
      create(:checkout_line, checkout: checkout, line_type: :product_variant, reference: create(:product_variant), metadata: { "order_id" => order.id })

      expect {
        perform_enqueued_jobs do
          described_class.fulfill!(checkout, payment: payment)
        end
      }.to change { ActionMailer::Base.deliveries.count }.by_at_least(1)
    end

    it "sends EventMailer.attendance_confirmed after event fulfillment" do
      creator = create_user
      event = create_event(creator_user: creator, status: "published", payment_required: true, price_cents: 500, max_participants: 20, start_at: 1.week.from_now)
      attendance = create(:attendance, user: user, event: event, status: :pending, payment_expires_at: 10.minutes.from_now)
      checkout = create(:checkout, user: user, status: :processing)
      create(:checkout_line, checkout: checkout, line_type: :event_registration, reference: attendance)

      expect {
        perform_enqueued_jobs do
          described_class.fulfill!(checkout, payment: payment)
        end
      }.to change { ActionMailer::Base.deliveries.count }.by_at_least(1)
    end
  end
end
