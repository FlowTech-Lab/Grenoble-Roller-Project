class UpdateAttendancesUniqueIndexToIncludeIsVolunteer < ActiveRecord::Migration[8.1]
  def up
    # Supprimer l'ancien index unique sur (user_id, event_id, child_membership_id)
    remove_index :attendances, name: "index_attendances_on_user_event_child" if index_exists?(:attendances, name: "index_attendances_on_user_event_child")
    
    # Créer un nouvel index unique sur (user_id, event_id, child_membership_id, is_volunteer)
    # Cela permet d'avoir plusieurs attendances pour le même user_id et event_id
    # si child_membership_id est différent (parent + enfants) OU si is_volunteer est différent (bénévole + participant)
    add_index :attendances, [:user_id, :event_id, :child_membership_id, :is_volunteer], 
              unique: true, 
              name: "index_attendances_on_user_event_child_volunteer"
  end

  def down
    # Supprimer le nouvel index
    remove_index :attendances, name: "index_attendances_on_user_event_child_volunteer" if index_exists?(:attendances, name: "index_attendances_on_user_event_child_volunteer")
    
    # Restaurer l'ancien index unique
    add_index :attendances, [:user_id, :event_id, :child_membership_id], 
              unique: true, 
              name: "index_attendances_on_user_event_child"
  end
end
