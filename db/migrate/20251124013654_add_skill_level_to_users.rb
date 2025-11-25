class AddSkillLevelToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :skill_level, :string
    add_index :users, :skill_level
  end
end
