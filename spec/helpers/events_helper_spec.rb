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

  describe '#route_difficulty_label' do
    it 'returns French labels' do
      expect(helper.route_difficulty_label('easy')).to eq('Facile')
      expect(helper.route_difficulty_label('medium')).to eq('Moyen')
      expect(helper.route_difficulty_label('hard')).to eq('Difficile')
    end
  end

  describe '#route_map_viewer_data' do
    it 'returns viewer data when a map image is attached' do
      route = create_route
      route.map_image.attach(
        io: StringIO.new(DevLoopMapFixtures.build_map_png(loop_number: 1, color: '#2563eb')),
        filename: 'map.png',
        content_type: 'image/png'
      )

      data = helper.route_map_viewer_data(route, title: 'Boucle 1')

      expect(data[:controller]).to eq('route-image-viewer')
      expect(data[:route_image_viewer_src_value]).to include('/rails/active_storage/')
    end
  end

  describe '#route_map_image_path' do
    it 'returns a resized representation for PNG attachments' do
      route = create_route
      route.map_image.attach(
        io: StringIO.new(DevLoopMapFixtures.build_map_png(loop_number: 1, color: '#2563eb')),
        filename: 'map.png',
        content_type: 'image/png'
      )

      expect(helper.route_map_image_path(route, resize_to: [800, 400])).to include('/rails/active_storage/representations/proxy/')
    end
  end

  describe '#event_loop_columns_class' do
    it 'returns responsive column classes' do
      expect(helper.event_loop_columns_class(2)).to eq('col-12 col-md-6')
      expect(helper.event_loop_columns_class(3)).to eq('col-12 col-md-4')
      expect(helper.event_loop_columns_class(4)).to eq('col-12 col-sm-6 col-xl-3')
    end
  end
end
