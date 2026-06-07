# frozen_string_literal: true

namespace :dev do
  desc "Attach SVG map previews to routes and upsert [DEV TEST] multi-loop events (development only)"
  task loop_maps: :environment do
    unless Rails.env.development?
      abort "dev:loop_maps is only available in development"
    end

    creator = User.find_by(email: "admin@roller.com") || User.find_by(email: "T3rorX@hotmail.fr") || User.first
    abort "No user found to assign as event creator" unless creator

    puts "Attaching map images to routes..."
    DevLoopMapFixtures.ensure_all_route_maps!(force: true)
    attached = Route.joins(:map_image_attachment).count
    puts "  #{attached}/#{Route.count} routes with map_image"

    puts "Upserting [DEV TEST] multi-loop events..."
    [2, 3, 4].each do |loops_count|
      event = DevLoopMapFixtures.upsert_dev_multi_loop_event!(loops_count: loops_count, creator: creator)
      puts "  #{event.title} → /events/#{event.hashid}"
    end

    puts "Done."
  end
end
