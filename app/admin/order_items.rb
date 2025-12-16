ActiveAdmin.register OrderItem do
  menu priority: 3, label: "Articles de commande", parent: "Commandes"

  permit_params :order_id, :variant_id, :quantity, :unit_price_cents

  index do
    selectable_column
    id_column
    column :order do |item|
      link_to "Order ##{item.order_id}", activeadmin_order_path(item.order)
    end
    column :variant do |item|
      link_to item.variant.sku, activeadmin_product_variant_path(item.variant)
    end
    column :product do |item|
      link_to item.variant.product.name, activeadmin_product_path(item.variant.product)
    end
    column :quantity
    column :unit_price_cents do |item|
      number_to_currency(item.unit_price_cents / 100.0)
    end
    column :total do |item|
      number_to_currency((item.unit_price_cents * item.quantity) / 100.0)
    end
    column :created_at
    actions
  end

  filter :order
  filter :variant
  filter :quantity
  filter :created_at

  show do
    attributes_table do
      row :id
      row :order do |item|
        link_to "Order ##{item.order_id}", activeadmin_order_path(item.order)
      end
      row :variant do |item|
        link_to item.variant.sku, activeadmin_product_variant_path(item.variant)
      end
      row :product do |item|
        link_to item.variant.product.name, activeadmin_product_path(item.variant.product)
      end
      row :quantity
      row :unit_price_cents do |item|
        number_to_currency(item.unit_price_cents / 100.0)
      end
      row :total do |item|
        number_to_currency((item.unit_price_cents * item.quantity) / 100.0)
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :order
      f.input :variant
      f.input :quantity
      f.input :unit_price_cents
    end
    f.actions
  end

  controller do
    def destroy
      @order_item = resource
      authorize @order_item, :destroy?
      if @order_item.destroy
        redirect_to collection_path, notice: "L'article de commande ##{@order_item.id} a été supprimé avec succès."
      else
        redirect_to resource_path(@order_item), alert: "Impossible de supprimer l'article : #{@order_item.errors.full_messages.join(', ')}"
      end
    end
  end
end
