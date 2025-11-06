class CreateOptionTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :option_types do |t|
    t.string :name, null: false, limit: 50
    t.string :presentation, limit: 100
    
    t.index :name, unique: true
    end
  end
end
