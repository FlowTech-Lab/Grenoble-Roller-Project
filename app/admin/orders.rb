ActiveAdmin.register Order do
  menu priority: 1, label: "Commandes", parent: "Commandes"

  includes :user, :payment, :order_items

  permit_params :user_id, :status, :total_cents, :donation_cents, :currency, :payment_id

  scope :all, default: true
  scope("En attente", default: true) { |orders| orders.where(status: "pending") }
  scope("Complétées") { |orders| orders.where(status: "completed") }
  scope("Annulées") { |orders| orders.where(status: "cancelled") }

  index do
    selectable_column
    id_column
    column :user
    column :status do |order|
      case order.status
      when "pending"
        status_tag("En attente", class: "warning")
      when "completed"
        status_tag("Complétée", class: "ok")
      when "cancelled", "canceled"
        status_tag("Annulée", class: "error")
      else
        status_tag(order.status)
      end
    end
    column :total_cents do |order|
      number_to_currency(order.total_cents / 100.0, unit: order.currency)
    end
    column :payment
    column :created_at do |order|
      order.created_at.strftime("%d/%m/%Y %H:%M")
    end
    actions
  end

  filter :user
  filter :status
  filter :payment
  filter :created_at

  show do
    attributes_table do
      row :id
      row :user
      row :status do |order|
        case order.status
        when "pending"
          status_tag("En attente", class: "warning")
        when "completed"
          status_tag("Complétée", class: "ok")
        when "cancelled", "canceled"
          status_tag("Annulée", class: "error")
        else
          status_tag(order.status)
        end
      end
      row :total_cents do |order|
        number_to_currency(order.total_cents / 100.0, unit: order.currency)
      end
      row :donation_cents do |order|
        if order.donation_cents > 0
          number_to_currency(order.donation_cents / 100.0, unit: order.currency)
        else
          "-"
        end
      end
      row :currency
      row :payment
      row :created_at
      row :updated_at
    end

    panel "Articles" do
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

    f.inputs "Commande" do
      f.input :user, collection: User.order(:last_name, :first_name).map { |u| [ u.to_s, u.id ] }
      f.input :status, as: :select, collection: {
        "En attente" => "pending",
        "Complétée" => "completed",
        "Annulée" => "cancelled"
      }, prompt: "Sélectionnez un statut"
      f.input :total_cents, label: "Total (cents)"
      f.input :donation_cents, label: "Don (cents)", hint: "Montant du don optionnel"
      f.input :currency, input_html: { value: f.object.currency || "EUR" }
      f.input :payment
    end

    f.actions
  end

  controller do
    def destroy
      @order = resource
      authorize @order, :destroy?
      if @order.destroy
        redirect_to collection_path, notice: "La commande ##{@order.id} a été supprimée avec succès."
      else
        redirect_to resource_path(@order), alert: "Impossible de supprimer la commande : #{@order.errors.full_messages.join(', ')}"
      end
    end
  end
end
