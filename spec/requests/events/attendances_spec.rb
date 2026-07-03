# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Events::Attendances", type: :request do
  include RequestAuthenticationHelper

  let(:role) { ensure_role(code: "USER", name: "Utilisateur", level: 10) }
  let(:user) { create_user(role: role, confirmed_at: Time.current) }

  before do
    allow_any_instance_of(User).to receive(:send_confirmation_instructions).and_return(true)
    allow_any_instance_of(User).to receive(:send_welcome_email_and_confirmation).and_return(true)
  end

  context "paid event" do
    let(:event) do
      create_event(
        status: "published",
        start_at: 1.week.from_now,
        max_participants: 20,
        payment_required: true,
        price_cents: 600
      )
    end

    before { login_user(user) }

    it "creates pending attendance with payment_expires_at" do
      post event_attendances_path(event)

      attendance = event.attendances.find_by(user: user)
      expect(attendance).to be_pending
      expect(attendance.payment_expires_at).to be_present
    end

    it "creates event_registration cart line" do
      expect {
        post event_attendances_path(event)
      }.to change(CartLine.event_registration, :count).by(1)
    end

    it "redirects to cart with reservation flash" do
      post event_attendances_path(event)

      expect(response).to redirect_to(cart_path)
      expect(flash[:notice]).to include("Place réservée")
    end

    it "does not send EventMailer.attendance_confirmed immediately" do
      expect(EventMailer).not_to receive(:attendance_confirmed)
      post event_attendances_path(event)
    end
  end

  context "free event" do
    let(:event) do
      create_event(
        status: "published",
        start_at: 1.week.from_now,
        max_participants: 20,
        payment_required: false,
        price_cents: 0
      )
    end

    before { login_user(user) }

    it "registers immediately with registered status" do
      post event_attendances_path(event)
      expect(event.attendances.find_by(user: user).status).to eq("registered")
    end

    it "sends confirmation email" do
      mailer = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
      expect(EventMailer).to receive(:attendance_confirmed).and_return(mailer)
      post event_attendances_path(event)
    end
  end

  context "when price_cents positive but payment_required false" do
    let(:event) do
      create_event(
        status: "published",
        start_at: 1.week.from_now,
        payment_required: false,
        price_cents: 500
      )
    end

    before { login_user(user) }

    it "registers immediately without cart line" do
      expect {
        post event_attendances_path(event)
      }.not_to change(CartLine, :count)

      expect(event.attendances.find_by(user: user).status).to eq("registered")
    end
  end
end
