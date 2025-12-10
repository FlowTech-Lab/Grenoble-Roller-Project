class FixMembershipsUniqueIndexForChildren < ActiveRecord::Migration[8.1]
  def up
    # Supprimer l'index unique existant qui s'applique à toutes les adhésions
    remove_index :memberships, name: "index_memberships_on_user_id_and_season_unique", if_exists: true

    # Créer un index unique partiel qui ne s'applique qu'aux adhésions personnelles (pas aux enfants)
    # Cela permet à un utilisateur d'avoir plusieurs adhésions enfants pour la même saison
    add_index :memberships, [ :user_id, :season ],
              unique: true,
              name: "index_memberships_on_user_id_and_season_unique_personal",
              where: "is_child_membership = false"
  end

  def down
    # Supprimer l'index unique partiel
    remove_index :memberships, name: "index_memberships_on_user_id_and_season_unique_personal", if_exists: true

    # Restaurer l'index unique original
    add_index :memberships, [ :user_id, :season ],
              unique: true,
              name: "index_memberships_on_user_id_and_season_unique"
  end
end
