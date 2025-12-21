# frozen_string_literal: true

module AdminPanel
  class OrderPolicy < BasePolicy
    # Seuls les admins peuvent gérer les commandes
    def create?
      false # Les commandes sont créées par les utilisateurs, pas par les admins
    end

    def change_status?
      admin_user? # Seuls les admins peuvent changer le statut
    end

    def export?
      admin_user? # Seuls les admins peuvent exporter
    end

    # Les méthodes index?, show?, update?, destroy? héritent de BasePolicy
  end
end
