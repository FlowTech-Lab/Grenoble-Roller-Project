ActiveAdmin.register Payment do
  menu priority: 4, parent: "Orders"

  permit_params :provider, :status, :amount_cents, :external_id, :metadata

  index do
    selectable_column
    id_column
    column :provider
    column :status do |payment|
      status_tag payment.status, payment.status == "completed" ? :ok : (payment.status == "pending" ? :warning : :error)
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
        status_tag payment.status, payment.status == "completed" ? :ok : (payment.status == "pending" ? :warning : :error)
      end
      row :amount_cents do |payment|
        number_to_currency(payment.amount_cents / 100.0)
      end
      row :external_id
      row :metadata do |payment|
        pre JSON.pretty_generate(payment.metadata) if payment.metadata.present?
      end
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
      f.input :metadata, as: :text, input_html: { rows: 5 }
    end
    f.actions
  end
end

