# frozen_string_literal: true

module AdminPanel
  class ProductPolicy < BasePolicy
    # Seuls les admins peuvent gérer les produits
    # Les méthodes héritent de BasePolicy qui vérifie admin_user?
  end
end
