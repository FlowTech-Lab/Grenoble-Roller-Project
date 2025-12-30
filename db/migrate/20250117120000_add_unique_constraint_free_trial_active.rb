class AddUniqueConstraintFreeTrialActive < ActiveRecord::Migration[7.0]
  def up
    # Contrainte unique : un seul essai gratuit actif par utilisateur/enfant
    # Cette contrainte empêche les race conditions où deux requêtes parallèles
    # pourraient créer deux attendances avec free_trial_used = true

    # NOTE: En développement, on utilise un index normal (plus rapide)
    # En production, on peut utiliser CONCURRENTLY si la table est grande
    # Pour utiliser CONCURRENTLY, ajouter disable_ddl_transaction! et remplacer les index ci-dessous

    # Pour les parents (child_membership_id = NULL)
    unless index_exists?(:attendances, name: "index_attendances_unique_free_trial_parent_active")
      add_index :attendances, :user_id,
        unique: true,
        where: "free_trial_used = true AND status != 'canceled' AND child_membership_id IS NULL",
        name: "index_attendances_unique_free_trial_parent_active"
    end

    # Pour les enfants (child_membership_id != NULL)
    unless index_exists?(:attendances, name: "index_attendances_unique_free_trial_child_active")
      add_index :attendances, [ :user_id, :child_membership_id ],
        unique: true,
        where: "free_trial_used = true AND status != 'canceled' AND child_membership_id IS NOT NULL",
        name: "index_attendances_unique_free_trial_child_active"
    end
  end

  def down
    remove_index :attendances, name: "index_attendances_unique_free_trial_parent_active", if_exists: true
    remove_index :attendances, name: "index_attendances_unique_free_trial_child_active", if_exists: true
  end
end
