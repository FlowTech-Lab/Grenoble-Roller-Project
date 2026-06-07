require 'rails_helper'

RSpec.describe EventsHelper, type: :helper do
  let(:creator) { create_user }
  let(:route1) { create_route(name: 'Boucle principale') }
  let(:route2) { create_route(name: 'Boucle secondaire', distance_km: 15.0) }

  describe '#format_event_distance' do
    it 'formats a single-loop event distance' do
      event = create_event(creator_user: creator, route: route1, distance_km: 10.0, loops_count: 1)

      expect(helper.format_event_distance(event)).to eq('10 km')
    end

    it 'joins per-loop distances instead of showing the total' do
      event = create_event(
        creator_user: creator,
        route: route1,
        loops_count: 2,
        distance_km: 5.0
      )
      event.event_loop_routes.create!(loop_number: 1, route: route1, distance_km: 5.0)
      event.event_loop_routes.create!(loop_number: 2, route: route2, distance_km: 7.0)

      expect(helper.format_event_distance(event)).to eq('5 km + 7 km')
      expect(helper.format_event_distance(event)).not_to include('12')
    end
  end
end
