ActiveAdmin.register ProductCategory do
  menu priority: 2, parent: "Shop"

  permit_params :name, :slug

  index do
    selectable_column
    id_column
    column :name
    column :slug
    column :products_count do |category|
      category.products.count
    end
    column :created_at
    actions
  end

  filter :name
  filter :slug
  filter :created_at

  show do
    attributes_table do
      row :id
      row :name
      row :slug
      row :created_at
      row :updated_at
    end

    panel "Products" do
      table_for product_category.products do
        column :id do |product|
          link_to "Product ##{product.id}", activeadmin_product_path(product)
        end
        column :name
        column :price_cents do |product|
          number_to_currency(product.price_cents / 100.0)
        end
        column :stock_quantity
        column :status
        column :created_at
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :slug
    end
    f.actions
  end
end

