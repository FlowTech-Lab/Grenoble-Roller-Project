require 'rails_helper'

RSpec.describe Route, type: :model do
  describe 'validations' do
    it 'is valid with minimal attributes' do
      route = build_route
      expect(route).to be_valid
    end

    it 'requires a name' do
      route = build_route(name: nil)
      expect(route).to be_invalid
      expect(route.errors[:name]).to include("can't be blank")
    end

    it 'limits difficulty to the allowed list' do
      route = build_route(difficulty: 'extreme')
      expect(route).to be_invalid
      expect(route.errors[:difficulty]).to include('is not included in the list')
    end

    it 'rejects negative distance or elevation' do
      route = build_route(distance_km: -5, elevation_m: -10)
      expect(route).to be_invalid
      expect(route.errors[:distance_km]).to include('must be greater than or equal to 0')
      expect(route.errors[:elevation_m]).to include('must be greater than or equal to 0')
    end
  end

  describe 'associations' do
    it 'nullifies route on associated events when destroyed' do
      route = create_route
      event = create_event(route: route)

      expect { route.destroy }.to change { event.reload.route }.from(route).to(nil)
    end
  end
end
