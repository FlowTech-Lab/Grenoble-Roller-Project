class AddInitiationFieldsToAttendances < ActiveRecord::Migration[8.0]
  def change
    add_column :attendances, :free_trial_used, :boolean, default: false, null: false unless column_exists?(:attendances, :free_trial_used)
    add_column :attendances, :is_volunteer, :boolean, default: false, null: false unless column_exists?(:attendances, :is_volunteer)
    add_column :attendances, :equipment_note, :text unless column_exists?(:attendances, :equipment_note)

    add_index :attendances, [ :event_id, :is_volunteer ], name: "index_attendances_on_event_id_and_is_volunteer" unless index_exists?(:attendances, [ :event_id, :is_volunteer ])
    add_index :attendances, [ :user_id, :free_trial_used ], name: "index_attendances_on_user_id_and_free_trial_used" unless index_exists?(:attendances, [ :user_id, :free_trial_used ])
  end
end
