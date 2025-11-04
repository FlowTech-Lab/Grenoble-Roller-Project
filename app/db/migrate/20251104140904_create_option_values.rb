class CreateOptionValues < ActiveRecord::Migration[8.0]
  def change
    create_table :option_values do |t|
      t.references :option_type, null: false, foreign_key: true
      t.string :value, null: false, limit: 50
      t.string :presentation, limit: 100

      t.timestamps
    end
  end
end
