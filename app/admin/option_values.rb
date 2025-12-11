ActiveAdmin.register OptionValue do
  menu priority: 5, label: "Valeurs d'options", parent: "Boutique"

  permit_params :option_type_id, :value

  index do
    selectable_column
    id_column
    column :value
    column :option_type
    column :product_variants_count do |option_value|
      option_value.product_variants.count
    end
    column :created_at
    actions
  end

  filter :option_type
  filter :value
  filter :created_at

  show do
    attributes_table do
      row :id
      row :value
      row :option_type
      row :created_at
      row :updated_at
    end

    panel "Product Variants" do
      table_for option_value.product_variants do
        column :id
        column :product do |variant|
          link_to variant.product.name, activeadmin_product_path(variant.product)
        end
        column :sku
        column :price_cents
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :option_type
      f.input :value
    end
    f.actions
  end

  controller do
    def destroy
      @option_value = resource
      if @option_value.destroy
        redirect_to collection_path, notice: "La valeur d'option ##{@option_value.id} a été supprimée avec succès."
      else
        redirect_to resource_path(@option_value), alert: "Impossible de supprimer la valeur d'option : #{@option_value.errors.full_messages.join(', ')}"
      end
    end
  end
end

