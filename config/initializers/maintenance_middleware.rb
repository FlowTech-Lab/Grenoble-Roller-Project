# config/initializers/maintenance_middleware.rb
# Enregistrement du middleware de maintenance
#
# Conforme à la doc Rails : les middlewares doivent être chargés explicitement
# (pas d'autoload) car ils ne sont pas rechargés automatiquement.
# Référence: https://guides.rubyonrails.org/autoloading_and_reloading_constants.html

# Charger explicitement le middleware depuis lib/middleware/
# (sous-répertoire standard pour les middlewares, ignoré par autoload)
# Utiliser require_relative pour un chargement plus fiable
require_relative "../../lib/middleware/maintenance_middleware"

# Enregistrer le middleware APRÈS Warden/Devise pour pouvoir détecter l'utilisateur connecté
# mais AVANT les controllers pour intercepter les requêtes
# Warden est généralement chargé via ActionDispatch::Session::CookieStore
# On l'insère après ActionDispatch::Flash pour être sûr que la session est initialisée
Rails.application.config.middleware.insert_after(
  ActionDispatch::Flash,
  MaintenanceMiddleware
)
