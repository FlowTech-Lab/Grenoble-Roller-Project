# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CartLineService do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create_user }
  let(:creator) { create_user }
  let(:event) do
    create_event(
      creator_user: creator,
      status: 'published',
      payment_required: true,
      price_cents: 800,
      max_participants: 20,
      start_at: 1.week.from_now
    )
  end
  let(:attendance) do
    create(:attendance, user: user, event: event, status: :pending, payment_expires_at: 15.minutes.from_now)
  end

  describe '.add_event_registration!' do
    it 'creates cart line linked to pending attendance' do
      line = nil
      expect {
        line = described_class.add_event_registration!(user: user, attendance: attendance, event: event)
      }.to change(CartLine, :count).by(1)

      expect(line.event_registration?).to be true
      expect(line.reference).to eq(attendance)
    end

    it 'sets expires_at to 15 minutes from now' do
      freeze_time do
        line = described_class.add_event_registration!(user: user, attendance: attendance, event: event)
        expect(line.expires_at).to be_within(1.second).of(15.minutes.from_now)
      end
    end

    it 'sets amount_cents from event price_cents' do
      line = described_class.add_event_registration!(user: user, attendance: attendance, event: event)
      expect(line.amount_cents).to eq(800)
    end

    it 'sets label from event title and participant name' do
      line = described_class.add_event_registration!(user: user, attendance: attendance, event: event)
      expect(line.label).to include(event.title)
      expect(line.label).to include(attendance.participant_name)
    end
  end

  describe '.release_event_line!' do
    it 'destroys pending attendance and cart line' do
      line = described_class.add_event_registration!(user: user, attendance: attendance, event: event)

      expect {
        described_class.release_event_line!(line)
      }.to change(CartLine, :count).by(-1)
        .and change(Attendance, :count).by(-1)
    end

    it 'frees a seat on the event' do
      line = described_class.add_event_registration!(user: user, attendance: attendance, event: event)
      event.reload
      expect(event.occupied_spots_for_capacity).to eq(1)

      described_class.release_event_line!(line)
      event.reload
      expect(event.occupied_spots_for_capacity).to eq(0)
    end
  end
end
