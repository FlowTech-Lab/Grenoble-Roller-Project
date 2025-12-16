ActiveAdmin.register VariantOptionValue do
  menu priority: 6, label: "Associations variantes-options", parent: "Boutique"

  permit_params :variant_id, :option_value_id

  index do
    selectable_column
    id_column
    column :variant do |vov|
      link_to vov.variant.sku, activeadmin_product_variant_path(vov.variant)
    end
    column :product do |vov|
      link_to vov.variant.product.name, activeadmin_product_path(vov.variant.product)
    end
    column :option_value do |vov|
      link_to "#{vov.option_value.option_type.name}: #{vov.option_value.value}", activeadmin_option_value_path(vov.option_value)
    end
    column :option_type do |vov|
      link_to vov.option_value.option_type.name, activeadmin_option_type_path(vov.option_value.option_type)
    end
    column :created_at
    actions
  end

  filter :variant
  filter :option_value
  filter :created_at

  show do
    attributes_table do
      row :id
      row :variant do |vov|
        link_to vov.variant.sku, activeadmin_product_variant_path(vov.variant)
      end
      row :product do |vov|
        link_to vov.variant.product.name, activeadmin_product_path(vov.variant.product)
      end
      row :option_value do |vov|
        link_to "#{vov.option_value.option_type.name}: #{vov.option_value.value}", activeadmin_option_value_path(vov.option_value)
      end
      row :option_type do |vov|
        link_to vov.option_value.option_type.name, activeadmin_option_type_path(vov.option_value.option_type)
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :variant
      f.input :option_value
    end
    f.actions
  end

  controller do
    def destroy
      @vov = resource
      if @vov.destroy
        redirect_to collection_path, notice: "L'association ##{@vov.id} a été supprimée avec succès."
      else
        redirect_to resource_path(@vov), alert: "Impossible de supprimer l'association : #{@vov.errors.full_messages.join(', ')}"
      end
    end
  end
end
