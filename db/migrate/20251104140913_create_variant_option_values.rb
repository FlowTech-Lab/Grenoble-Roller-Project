class CreateVariantOptionValues < ActiveRecord::Migration[8.0]
  def change
    create_table :variant_option_values do |t|
      t.references :variant, null: false, foreign_key: { to_table: :product_variants }
      t.references :option_value, null: false, foreign_key: true
      t.index [ :variant_id, :option_value_id ], unique: true

      t.timestamps
    end
  end
end
