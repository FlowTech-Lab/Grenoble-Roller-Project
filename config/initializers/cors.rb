# Be sure to restart your server when you modify this file.

# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Origines autorisées pour les applications mobiles et web
    origins do |origin, request|
      # En développement, autoriser localhost
      if Rails.env.development?
        origin.nil? || origin.match?(/^https?:\/\/localhost(:\d+)?$/) || 
        origin.match?(/^https?:\/\/127\.0\.0\.1(:\d+)?$/) ||
        origin.match?(/^https?:\/\/.*\.flowtech-lab\.org$/)
      # En staging, autoriser le domaine staging
      elsif ENV["APP_ENV"] == "staging" || ENV["DEPLOY_ENV"] == "staging"
        origin.nil? || 
        origin.match?(/^https?:\/\/.*\.flowtech-lab\.org$/) ||
        origin.match?(/^https?:\/\/.*\.localhost(:\d+)?$/)
      # En production, autoriser le domaine de production
      else
        origin.nil? || 
        origin.match?(/^https?:\/\/.*\.grenoble-roller\.org$/) ||
        origin.match?(/^https?:\/\/grenoble-roller\.org$/)
      end
    end

    # Ressources autorisées
    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true, # Permet l'envoi de cookies/credentials
      expose: ["Authorization", "X-Total-Count"] # Headers exposés à l'application
  end
end

