# frozen_string_literal: true

class CheckoutFulfillmentService
  class << self
    def fulfill!(checkout, payment:)
      checkout.with_lock do
        checkout.reload
        return checkout if checkout.paid?

        checkout.checkout_lines.includes(:reference).find_each do |line|
          fulfill_line!(line, payment)
        end

        remove_fulfilled_cart_lines!(checkout)
        checkout.update!(status: :paid, payment: payment)
      end

      send_post_fulfillment_emails!(checkout)
      checkout.reload
    end

    private

    def fulfill_line!(line, payment)
      case line.line_type
      when "product_variant"
        fulfill_product!(line, payment)
      when "membership"
        fulfill_membership!(line, payment)
      when "event_registration"
        fulfill_event!(line, payment)
      end
    end

    def fulfill_product!(line, payment)
      order_id = line.metadata["order_id"] || line.checkout.metadata["order_id"]
      return unless order_id

      order = Order.find_by(id: order_id)
      return unless order
      return if order.status == "paid"

      order.update!(payment: payment, status: "paid")
    end

    def fulfill_membership!(line, payment)
      membership = line.reference
      return unless membership.is_a?(Membership)
      return if membership.active?

      membership.update!(status: :active, payment: payment)
    end

    def fulfill_event!(line, payment)
      attendance = line.reference
      return unless attendance.is_a?(Attendance)
      return if attendance.registered? && attendance.payment_expires_at.nil?

      attendance.update!(
        status: :registered,
        payment_expires_at: nil,
        payment: payment
      )
    end

    def remove_fulfilled_cart_lines!(checkout)
      cart_line_ids = checkout.checkout_lines.filter_map(&:cart_line_id)
      CartLine.where(id: cart_line_ids).find_each do |cart_line|
        if cart_line.event_registration?
          cart_line.destroy!
        else
          cart_line.destroy!
        end
      end
    end

    def send_post_fulfillment_emails!(checkout)
      checkout.checkout_lines.includes(:reference).find_each do |line|
        case line.line_type
        when "product_variant"
          order_id = line.metadata["order_id"] || checkout.metadata["order_id"]
          order = Order.find_by(id: order_id)
          OrderMailer.order_confirmation(order).deliver_later if order
        when "event_registration"
          attendance = line.reference
          EventMailer.attendance_confirmed(attendance).deliver_later if attendance.is_a?(Attendance)
        end
      end
    end
  end
end
