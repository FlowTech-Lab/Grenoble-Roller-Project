class AddNonMemberDiscoveryToInitiations < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :allow_non_member_discovery, :boolean, default: false, null: false
    add_column :events, :non_member_discovery_slots, :integer, default: 0, null: false
  end
end
