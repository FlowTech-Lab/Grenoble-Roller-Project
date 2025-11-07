require 'rails_helper'

RSpec.describe Event, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    travel_to(Time.zone.local(2025, 1, 1, 12)) { example.run }
  end

  let(:creator) { create_user }

  describe 'validations' do
    it 'is valid with default attributes' do
      event = build_event(creator_user: creator, route: create_route)
      expect(event).to be_valid
    end

    it 'requires mandatory attributes' do
      event = Event.new
      expect(event).to be_invalid
      expect(event.errors[:creator_user]).to be_present
      expect(event.errors[:title]).to be_present
      expect(event.errors[:description]).to be_present
      expect(event.errors[:start_at]).to be_present
      expect(event.errors[:duration_min]).to be_present
      expect(event.errors[:location_text]).to be_present
    end

    it 'enforces duration to be a positive multiple of 5' do
      event = build_event(creator_user: creator, duration_min: 42)
      expect(event).to be_invalid
      expect(event.errors[:duration_min]).to include('must be a multiple of 5')
    end

    it 'requires non-negative pricing' do
      event = build_event(creator_user: creator, price_cents: -10)
      expect(event).to be_invalid
      expect(event.errors[:price_cents]).to include('must be greater than or equal to 0')
    end
  end

  describe 'scopes' do
    it 'returns events with future dates for upcoming scope' do
      future_event = create_event(creator_user: creator, start_at: 2.days.from_now)
      create_event(creator_user: creator, start_at: 2.days.ago)

      expect(Event.upcoming).to contain_exactly(future_event)
    end

    it 'returns past events for past scope' do
      past_event = create_event(creator_user: creator, start_at: 3.days.ago)
      create_event(creator_user: creator, start_at: 2.days.from_now)

      expect(Event.past).to contain_exactly(past_event)
    end

    it 'returns published events for published scope' do
      published_event = create_event(creator_user: creator, status: 'published')
      create_event(creator_user: creator, status: 'draft')

      expect(Event.published).to contain_exactly(published_event)
    end
  end

  describe '#full?' do
    it 'returns false by default' do
      event = build_event(creator_user: creator)
      expect(event.full?).to be false
    end
  end
end

