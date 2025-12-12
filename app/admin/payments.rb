ActiveAdmin.register Payment do
  menu priority: 2, label: "Paiements", parent: "Commandes"

  permit_params :provider, :status, :amount_cents, :external_id

  index do
    selectable_column
    id_column
    column :provider
    column :status do |payment|
      case payment.status
      when "completed"
        status_tag("Complété", class: "ok")
      when "pending"
        status_tag("En attente", class: "warning")
      when "failed"
        status_tag("Échoué", class: "error")
      when "cancelled"
        status_tag("Annulé", class: "error")
      else
        status_tag(payment.status.to_s)
      end
    end
    column :amount_cents do |payment|
      number_to_currency(payment.amount_cents / 100.0)
    end
    column :external_id
    column :orders_count do |payment|
      payment.orders.count
    end
    column :memberships_count do |payment|
      payment.memberships.count
    end
    column :attendances_count do |payment|
      payment.attendances.count
    end
    column :created_at
    actions
  end

  filter :provider
  filter :status
  filter :external_id
  filter :created_at

  show do
    attributes_table do
      row :id
      row :provider
      row :status do |payment|
        case payment.status
        when "completed"
          status_tag("Complété", class: "ok")
        when "pending"
          status_tag("En attente", class: "warning")
        when "failed"
          status_tag("Échoué", class: "error")
        when "cancelled"
          status_tag("Annulé", class: "error")
        else
          status_tag(payment.status.to_s)
        end
      end
      row :amount_cents do |payment|
        number_to_currency(payment.amount_cents / 100.0)
      end
      row :external_id
      row :provider_payment_id
      row :currency
      row :created_at
      row :updated_at
    end

    panel "Orders" do
      table_for payment.orders do
        column :id do |order|
          link_to "Order ##{order.id}", activeadmin_order_path(order)
        end
        column :user
        column :total_cents do |order|
          number_to_currency(order.total_cents / 100.0)
        end
        column :status
        column :created_at
      end
    end

    panel "Memberships" do
      table_for payment.memberships do
        column :id do |membership|
          link_to "Membership ##{membership.id}", activeadmin_membership_path(membership)
        end
        column :user
        column :type
        column :status
        column :created_at
      end
    end

    panel "Attendances" do
      table_for payment.attendances do
        column :id do |attendance|
          link_to "Attendance ##{attendance.id}", activeadmin_attendance_path(attendance)
        end
        column :user
        column :event do |attendance|
          link_to attendance.event.title, activeadmin_event_path(attendance.event) if attendance.event
        end
        column :status
        column :created_at
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :provider
      f.input :status, as: :select, collection: %w[pending completed failed cancelled]
      f.input :amount_cents
      f.input :external_id
      f.input :provider_payment_id
      f.input :currency
    end
    f.actions
  end

  controller do
    def destroy
      @payment = resource
      if @payment.destroy
        redirect_to collection_path, notice: "Le paiement ##{@payment.id} a été supprimé avec succès."
      else
        redirect_to resource_path(@payment), alert: "Impossible de supprimer le paiement : #{@payment.errors.full_messages.join(', ')}"
      end
    end
  end
end

