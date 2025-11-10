require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Avoid pushing autoload paths into $LOAD_PATH to keep frozen arrays from Ruby 3.4 mutable.
    config.add_autoload_paths_to_load_path = false

    # Ruby 3.4 freezes some Rails path arrays; duplicate them to allow engines to modify load paths.
    config.autoload_paths = config.autoload_paths.dup
    config.eager_load_paths = config.eager_load_paths.dup
    config.paths['app/controllers'] = config.paths['app/controllers'].dup
    config.paths['app/helpers'] = config.paths['app/helpers'].dup
    config.paths['app/models'] = config.paths['app/models'].dup

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
