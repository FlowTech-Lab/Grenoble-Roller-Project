# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExpireCartLinesJob do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create_user }
  let(:creator) { create_user }
  let(:event) do
    create_event(
      creator_user: creator,
      status: 'published',
      payment_required: true,
      price_cents: 500,
      max_participants: 5,
      start_at: 1.week.from_now
    )
  end

  describe '#perform' do
    it 'releases expired event cart lines' do
      attendance = create(:attendance, user: user, event: event, status: :pending, payment_expires_at: 1.minute.ago)
      line = create(:cart_line, :event_registration, user: user, reference: attendance, expires_at: 1.minute.ago)

      expect {
        described_class.perform_now
      }.to change(CartLine, :count).by(-1)
        .and change(Attendance, :count).by(-1)
    end

    it 'frees event seat when line expires' do
      freeze_time do
        attendance = create(:attendance, user: user, event: event, status: :pending, payment_expires_at: 10.minutes.from_now)
        create(:cart_line, :event_registration, user: user, reference: attendance, expires_at: 10.minutes.from_now)
        event.reload
        expect(event.occupied_spots_for_capacity).to eq(1)

        travel 11.minutes
        described_class.perform_now
        event.reload
        expect(event.occupied_spots_for_capacity).to eq(0)
        expect(Attendance.exists?(attendance.id)).to be false
      end
    end

    it 'does not touch non-expired event lines' do
      attendance = create(:attendance, user: user, event: event, status: :pending, payment_expires_at: 10.minutes.from_now)
      create(:cart_line, :event_registration, user: user, reference: attendance, expires_at: 10.minutes.from_now)

      expect {
        described_class.perform_now
      }.not_to change(CartLine, :count)
    end

    it 'does not touch product or membership lines without expires_at' do
      create(:cart_line, user: user)

      expect {
        described_class.perform_now
      }.not_to change(CartLine, :count)
    end
  end
end
