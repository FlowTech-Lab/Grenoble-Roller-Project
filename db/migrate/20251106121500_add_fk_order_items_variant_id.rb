class AddFkOrderItemsVariantId < ActiveRecord::Migration[8.0]
  def up
    # Nettoyage préventif d'enregistrements orphelins avant ajout de la FK
    execute <<~SQL
      DELETE FROM order_items oi
      WHERE oi.variant_id IS NULL
         OR NOT EXISTS (
           SELECT 1 FROM product_variants pv WHERE pv.id = oi.variant_id
         );
    SQL

    add_foreign_key :order_items, :product_variants, column: :variant_id
  end

  def down
    remove_foreign_key :order_items, column: :variant_id
  end
end
