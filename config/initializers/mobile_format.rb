# Configuration pour les formats mobiles dans Rails
# Active la détection automatique des appareils mobiles et les formats associés

# Ajouter les formats mobiles aux formats MIME reconnus
Mime::Type.register_alias "text/html", :mobile
Mime::Type.register_alias "text/html", :iphone
Mime::Type.register_alias "text/html", :android

# Configuration ActionDispatch pour la détection automatique des appareils mobiles
Rails.application.config.action_dispatch.best_standards_support = :builtin

# Détection automatique des variantes mobiles basée sur le User-Agent
# Cela permet d'utiliser des vues spécifiques comme index.html+mobile.erb
ActionController::Base.class_eval do
  before_action :set_mobile_variant

  private

  def set_mobile_variant
    request.variant = :mobile if mobile_device?
  end

  def mobile_device?
    request.user_agent =~ /Mobile|webOS|iPhone|iPad|Android|BlackBerry|Opera Mini|IEMobile/
  end
  helper_method :mobile_device?
end

