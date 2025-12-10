# lib/maintenance_middleware.rb
# Middleware pour intercepter les requêtes en mode maintenance

class MaintenanceMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    # Vérifier si maintenance est active (avec vérification de disponibilité)
    # Protection contre les erreurs si MaintenanceMode ou Rails.cache ne sont pas encore chargés
    begin
      maintenance_enabled = defined?(MaintenanceMode) && MaintenanceMode.enabled?
    rescue => e
      # Si erreur (cache non initialisé, etc.), considérer que maintenance est inactive
      Rails.logger.debug("MaintenanceMiddleware: Error checking maintenance: #{e.message}") if defined?(Rails)
      maintenance_enabled = false
    end

    if maintenance_enabled
      request_path = env["PATH_INFO"]

      # Routes autorisées en maintenance (pour visiteurs non connectés)
      allowed_paths = [
        "/admin",           # ActiveAdmin dashboard
        "/users/sign_in",   # Devise login (page de connexion)
        "/users/sign_up",   # Devise registration (inscription)
        "/users/sign_out",  # Logout
        "/users/password",  # Mot de passe oublié
        "/users/confirmation", # Confirmation de compte
        "/maintenance",     # Page maintenance elle-même
        "/assets",          # Assets (CSS, JS, images)
        "/packs",           # Webpack assets
        "/uploads",         # Uploads
        "/up",              # Health check endpoint (HAProxy/pfSense)
        "/health"           # Health check endpoint avancé
      ]

      # Vérifier si utilisateur est ADMIN ou SUPERADMIN connecté
      # Le middleware s'exécute tôt, donc on doit vérifier de manière robuste
      user_is_admin = false
      begin
        # Méthode 1 : Via Warden (Devise) - méthode principale
        if env["warden"]
          user = env["warden"].user
          if user.present?
            # Charger le rôle si disponible
            if user.respond_to?(:role)
              role = user.role
              if role.present?
                role_code = role.code.to_s.upcase
                role_level = role.level.to_i
                user_is_admin = [ "ADMIN", "SUPERADMIN" ].include?(role_code) || role_level >= 60
              end
            end
          end
        end

        # Méthode 2 : Via session (fallback si Warden n'est pas encore initialisé)
        # On charge l'utilisateur depuis la session pour vérifier son rôle
        unless user_is_admin
          rack_session = env["rack.session"]
          if rack_session && rack_session["warden.user.user.key"]
            begin
              # Charger l'utilisateur depuis la session
              user_id = rack_session["warden.user.user.key"]&.first&.first
              if user_id
                user = User.find_by(id: user_id)
                if user&.respond_to?(:role)
                  role = user.role
                  if role.present?
                    role_code = role.code.to_s.upcase
                    role_level = role.level.to_i
                    user_is_admin = [ "ADMIN", "SUPERADMIN" ].include?(role_code) || role_level >= 60
                  end
                end
              end
            rescue => e
              Rails.logger.debug("MaintenanceMiddleware: Session user load failed: #{e.message}") if defined?(Rails)
            end
          end
        end
      rescue => e
        Rails.logger.debug("MaintenanceMiddleware: User check failed: #{e.message}") if defined?(Rails)
      end

      # Autoriser l'accès si:
      # 1. Route autorisée (login, assets, etc.) OU
      # 2. Utilisateur ADMIN/SUPERADMIN connecté (accès complet à l'app)
      unless allowed_paths.any? { |p| request_path.start_with?(p) } || user_is_admin
        return show_maintenance_page(env)
      end
    end

    @app.call(env)
  end

  private

  def show_maintenance_page(env)
    # Retourner 200 au lieu de 503 pour éviter que HAProxy considère le serveur comme down
    # Le code 200 permet à HAProxy de continuer à router les requêtes vers les routes autorisées
    [
      200,
      { "Content-Type" => "text/html; charset=utf-8" },
      [ render_maintenance_page(env) ]
    ]
  end

  def render_maintenance_page(env)
    # Charger template HTML depuis public/maintenance.html
    template_path = Rails.root.join("public", "maintenance.html")
    if File.exist?(template_path)
      File.read(template_path)
    else
      # Fallback HTML simple si fichier manquant
      "<!DOCTYPE html><html><head><title>Maintenance</title></head><body><h1>Maintenance en cours</h1></body></html>"
    end
  end
end
