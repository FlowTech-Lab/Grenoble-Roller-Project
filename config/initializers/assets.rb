# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
Rails.application.config.assets.paths << Rails.root.join("app/assets/builds")
Rails.application.config.assets.paths << Rails.root.join("node_modules/bootstrap-icons/font")
Rails.application.config.assets.paths << Rails.root.join("node_modules/bootstrap/dist/js")
active_admin_path = Gem::Specification.find_by_name("activeadmin").gem_dir
Rails.application.config.assets.paths << File.join(active_admin_path, "app/assets/stylesheets")
Rails.application.config.assets.paths << File.join(active_admin_path, "app/assets/javascripts")
Rails.application.config.assets.precompile << "bootstrap.bundle.min.js"
Rails.application.config.assets.precompile += %w[active_admin.js active_admin.css]