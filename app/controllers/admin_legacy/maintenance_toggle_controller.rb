# app/controllers/admin_legacy/maintenance_toggle_controller.rb
# Controller personnalisé pour gérer le toggle du mode maintenance
module AdminLegacy
  class MaintenanceToggleController < ApplicationController
    before_action :authenticate_user!

    def update
      toggle
    end

    def toggle
      # Vérifier que l'utilisateur est ADMIN ou SUPERADMIN
      user = current_user
      user_is_admin = false
      if user.present? && user.respond_to?(:role) && user.role.present?
        role_code = user.role.code.to_s.upcase
        role_level = user.role.level.to_i
        user_is_admin = [ "ADMIN", "SUPERADMIN" ].include?(role_code) || role_level >= 60
      end

      unless user_is_admin
        redirect_to activeadmin_maintenance_path, alert: "Accès refusé : Seuls les administrateurs (ADMIN/SUPERADMIN) peuvent modifier le mode maintenance"
        return
      end

      user_email = user&.email || "unknown"

      if MaintenanceMode.enabled?
        MaintenanceMode.disable!
        message = "✓ Mode maintenance DÉSACTIVÉ"
        Rails.logger.info("🔓 MAINTENANCE DÉSACTIVÉE par #{user_email}")
        status = :notice
      else
        MaintenanceMode.enable!
        message = "✓ Mode maintenance ACTIVÉ"
        Rails.logger.warn("🔒 MAINTENANCE ACTIVÉE par #{user_email}")
        status = :notice
      end

      redirect_to activeadmin_maintenance_path, status => message
    end
  end
end
