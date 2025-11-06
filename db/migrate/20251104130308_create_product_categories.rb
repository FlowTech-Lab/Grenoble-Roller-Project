class CreateProductCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :product_categories do |t|
      t.string :name, null: false, limit: 100
      t.string :slug, null: false, limit: 120
      t.index :slug, unique: true
      
      t.timestamps
    end
  end
end
