class AddLevelAndDistanceToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :level, :string, limit: 20
    add_column :events, :distance_km, :decimal, precision: 6, scale: 2
  end
end
