# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventOrganizer, type: :model do
  describe 'validations' do
    it 'is valid with default attributes' do
      event_organizer = EventOrganizer.new(name: 'Grenoble Roller', url: 'https://grenoble-roller.example', is_active: true)
      expect(event_organizer).to be_valid
    end

    it 'requires a name' do
      event_organizer = EventOrganizer.new(url: 'https://example.com', is_active: true)
      expect(event_organizer).to be_invalid
      expect(event_organizer.errors[:name]).to be_present
    end

    it 'validates URL format when provided' do
      event_organizer = EventOrganizer.new(name: 'Invalid URL', url: 'ftp://example.com', is_active: true)
      expect(event_organizer).to be_invalid
      expect(event_organizer.errors[:url]).to be_present
    end

    it 'requires is_active to be a boolean' do
      event_organizer = EventOrganizer.new(name: 'Boolean Check', is_active: nil)
      expect(event_organizer).to be_invalid
      expect(event_organizer.errors[:is_active]).to be_present
    end
  end

  describe 'scopes' do
    before do
      EventOrganizer.delete_all
    end

    it 'returns active organizers for the active scope' do
      active = EventOrganizer.create!(name: 'Active Org', url: 'https://active.example', is_active: true)
      EventOrganizer.create!(name: 'Inactive Org', url: 'https://inactive.example', is_active: false)

      expect(EventOrganizer.active).to contain_exactly(active)
    end

    it 'returns inactive organizers for the inactive scope' do
      inactive = EventOrganizer.create!(name: 'Inactive Org', url: 'https://inactive.example', is_active: false)
      EventOrganizer.create!(name: 'Active Org', url: 'https://active.example', is_active: true)

      expect(EventOrganizer.inactive).to contain_exactly(inactive)
    end
  end

  describe 'associations' do
    it 'nullifies organizer_id on events when destroyed' do
      event_organizer = create(:event_organizer)
      event = create(:event, organizer: event_organizer)

      expect { event_organizer.destroy }.to change(EventOrganizer, :count).by(-1)
      expect(event.reload.organizer_id).to be_nil
    end
  end
end
