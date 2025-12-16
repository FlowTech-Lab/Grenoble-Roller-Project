class UpdateAttendancesUniqueIndexToIncludeChildMembershipId < ActiveRecord::Migration[8.1]
  def up
    # Supprimer l'ancien index unique sur (user_id, event_id)
    remove_index :attendances, name: "index_attendances_on_user_id_and_event_id"

    # Créer un nouvel index unique sur (user_id, event_id, child_membership_id)
    # Cela permet d'avoir plusieurs attendances pour le même user_id et event_id
    # si child_membership_id est différent (parent + enfants)
    add_index :attendances, [ :user_id, :event_id, :child_membership_id ],
              unique: true,
              name: "index_attendances_on_user_event_child"
  end

  def down
    # Supprimer le nouvel index
    remove_index :attendances, name: "index_attendances_on_user_event_child"

    # Restaurer l'ancien index unique
    add_index :attendances, [ :user_id, :event_id ],
              unique: true,
              name: "index_attendances_on_user_id_and_event_id"
  end
end
