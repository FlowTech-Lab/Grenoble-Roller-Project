ActiveAdmin.register Product do
  includes :category

  permit_params :category_id, :name, :slug, :description, :price_cents,
                :currency, :stock_qty, :is_active, :image_url

  index do
    selectable_column
    id_column
    column :name
    column :category
    column :slug
    column :is_active do |product|
      status_tag(product.is_active ? 'actif' : 'inactive', class: product.is_active ? 'ok' : 'warning')
    end
    column :price_cents do |product|
      number_to_currency(product.price_cents / 100.0, unit: product.currency)
    end
    column :stock_qty
    actions
  end

  filter :name
  filter :category
  filter :is_active
  filter :currency
  filter :created_at

  show do
    attributes_table do
      row :name
      row :category
      row :slug
      row :description
      row :price_cents do |product|
        number_to_currency(product.price_cents / 100.0, unit: product.currency)
      end
      row :stock_qty
      row :currency
      row :is_active
      row :image_url do |product|
        if product.image_url.present?
          image_tag(product.image_url, height: 80)
        else
          status_tag('aucune image', :warning)
        end
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs 'Produit' do
      f.input :category
      f.input :name
      f.input :slug
      f.input :description
      f.input :price_cents, label: 'Prix (cents)'
      f.input :currency, input_html: { value: f.object.currency || 'EUR' }
      f.input :stock_qty
      f.input :is_active
      f.input :image_url
    end

    f.actions
  end
end
