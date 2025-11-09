ActiveAdmin.register Order do
  includes :user, :payment, :order_items

  permit_params :user_id, :status, :total_cents, :currency, :payment_id

  index do
    selectable_column
    id_column
    column :user
    column :status do |order|
      status_tag(order.status)
    end
    column :total_cents do |order|
      number_to_currency(order.total_cents / 100.0, unit: order.currency)
    end
    column :payment
    column :created_at
    actions
  end

  filter :user
  filter :status
  filter :payment
  filter :created_at

  show do
    attributes_table do
      row :user
      row :status
      row :total_cents do |order|
        number_to_currency(order.total_cents / 100.0, unit: order.currency)
      end
      row :currency
      row :payment
      row :created_at
      row :updated_at
    end

    panel 'Articles' do
      table_for order.order_items.includes(:variant) do
        column :variant_id
        column :quantity
        column :unit_price_cents do |item|
          number_to_currency(item.unit_price_cents / 100.0, unit: order.currency)
        end
        column :created_at
      end
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs 'Commande' do
      f.input :user
      f.input :status
      f.input :total_cents, label: 'Total (cents)'
      f.input :currency
      f.input :payment
    end

    f.actions
  end
end
