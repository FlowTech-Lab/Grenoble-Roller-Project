class CreatePartners < ActiveRecord::Migration[8.0]
  def change
    create_table :partners do |t|
      t.string :name, limit: 140, null: false
      t.string :url, limit: 255
      t.string :logo_url, limit: 255
      t.text :description
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end
  end
end
