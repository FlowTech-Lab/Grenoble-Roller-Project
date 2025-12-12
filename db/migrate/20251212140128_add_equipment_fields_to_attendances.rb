class AddEquipmentFieldsToAttendances < ActiveRecord::Migration[8.1]
  def change
    add_column :attendances, :needs_equipment, :boolean, default: false, null: false unless column_exists?(:attendances, :needs_equipment)
    add_column :attendances, :roller_size, :string unless column_exists?(:attendances, :roller_size)
  end
end
