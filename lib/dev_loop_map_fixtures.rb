# frozen_string_literal: true

require "vips"

module DevLoopMapFixtures
  MAP_COLORS = %w[#2563eb #059669 #d97706 #7c3aed #dc2626].freeze

  module_function

  def attach_map_image!(route, loop_number: nil, force: false)
    if route.map_image.attached?
      return route if !force && route.map_image.content_type != "image/svg+xml"

      route.map_image.purge
    end

    color = MAP_COLORS[(loop_number || route.id).to_i % MAP_COLORS.size]

    route.map_image.attach(
      io: StringIO.new(build_map_png(loop_number: loop_number, color: color)),
      filename: "dev-map-route-#{route.id}-#{loop_number || 'main'}.png",
      content_type: "image/png"
    )
    route
  end

  def ensure_all_route_maps!(force: false)
    Route.find_each.with_index do |route, index|
      attach_map_image!(route, loop_number: index + 1, force: force)
    end
  end

  def upsert_dev_multi_loop_event!(loops_count:, creator:)
    title = "[DEV TEST] Rando #{loops_count} boucles"
    routes = Route.order(:id).limit(loops_count).to_a
    raise "Need at least #{loops_count} routes, found #{routes.size}" if routes.size < loops_count

    routes.each_with_index { |route, index| attach_map_image!(route, loop_number: index + 1, force: true) }

    event = Event.find_or_initialize_by(title: title)
    event.assign_attributes(
      creator_user: creator,
      route: routes.first,
      status: "published",
      start_at: loops_count.weeks.from_now.change(hour: 10, min: 0),
      duration_min: 120,
      description: "Dev test event with #{loops_count} loops and PNG route map previews.",
      price_cents: 0,
      currency: "EUR",
      location_text: "Place de la Bastille, Grenoble",
      meeting_lat: 45.1917,
      meeting_lng: 5.7278,
      level: "all_levels",
      distance_km: routes.first.distance_km || (5.0 + loops_count),
      loops_count: loops_count,
      max_participants: 0
    )
    event.save!

    event.event_loop_routes.destroy_all
    routes.each_with_index do |route, index|
      event.event_loop_routes.create!(
        loop_number: index + 1,
        route: route,
        distance_km: route.distance_km || (5.0 + index + 1)
      )
    end

    event
  end

  def build_map_png(loop_number:, color:)
    width = 800
    height = 450
    r, g, b = hex_to_rgb(color)
    bg_r = [r + 180, 255].min
    bg_g = [g + 180, 255].min
    bg_b = [b + 180, 255].min

    background = Vips::Image.black(width, height, bands: 3).linear([1, 1, 1], [bg_r, bg_g, bg_b])
    route_line = Vips::Image.black(width, 12, bands: 3).linear([1, 1, 1], [r, g, b])
    y_offset = (height * 0.62).round
    composed = background.composite(route_line, :over, x: 0, y: y_offset)

    if loop_number
      label_band = Vips::Image.black(width, 56, bands: 3).linear([1, 1, 1], [r, g, b])
      composed = composed.composite(label_band, :over, x: 0, y: 0)
    end

    composed.write_to_buffer(".png")
  end

  def hex_to_rgb(hex)
    value = hex.delete("#")
    [value[0, 2], value[2, 2], value[4, 2]].map { |part| part.to_i(16) }
  end
end
