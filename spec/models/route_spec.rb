require 'rails_helper'

RSpec.describe Route, type: :model do
  include TestDataHelper
  describe 'validations' do
    it 'is valid with minimal attributes' do
      route = build_route
      expect(route).to be_valid
    end

    it 'requires a name' do
      route = build_route(name: nil)
      expect(route).to be_invalid
      # En français, on vérifie simplement qu'une erreur est présente (i18n)
      expect(route.errors[:name]).to be_present
    end

    it 'limits difficulty to the allowed list' do
      route = build_route(difficulty: 'extreme')
      expect(route).to be_invalid
      expect(route.errors[:difficulty]).to be_present
    end

    it 'rejects negative distance or elevation' do
      route = build_route(distance_km: -5, elevation_m: -10)
      expect(route).to be_invalid
      expect(route.errors[:distance_km]).to be_present
      expect(route.errors[:elevation_m]).to be_present
    end
  end

  describe 'associations' do
    it 'nullifies route on associated events when destroyed' do
      route = create_route
      event = build_event(route: route)
      event.save!

      expect { route.destroy }.to change { event.reload.route }.from(route).to(nil)
    end
  end
end
