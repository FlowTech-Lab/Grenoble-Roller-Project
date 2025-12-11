class AddLoopsCountToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :loops_count, :integer, default: 1, null: false
  end
end
