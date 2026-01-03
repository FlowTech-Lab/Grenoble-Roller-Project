# frozen_string_literal: true

module AdminPanel
  # Policy pour le mode maintenance
  # MaintenanceMode n'est pas un modèle ActiveRecord, donc on utilise une classe wrapper
  class MaintenancePolicy < BasePolicy
    # Seuls les admins/superadmins peuvent activer/désactiver le mode maintenance
    def toggle?
      admin_user? # level >= 60 (ADMIN ou SUPERADMIN)
    end
  end
end
