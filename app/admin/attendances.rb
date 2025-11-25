ActiveAdmin.register Attendance do
  includes :user, :event, :payment

  permit_params :user_id, :event_id, :status, :payment_id, :stripe_customer_id

  scope :all, default: true
  scope("Actives") { |attendances| attendances.active }
  scope("Annulées") { |attendances| attendances.canceled }

  index do
    selectable_column
    id_column
    column :user
    column :event
    column :status do |attendance|
      status_tag(attendance.status)
    end
    column :payment
    column :stripe_customer_id
    column :created_at
    actions
  end

  filter :user, collection: -> { User.order(:email) }
  filter :event
  filter :status, as: :select, collection: Attendance.statuses.keys
  filter :payment
  filter :created_at

  form do |f|
    f.semantic_errors

    f.inputs "Inscription" do
      f.input :user, collection: User.order(:email)
      f.input :event
      f.input :status, as: :select, collection: Attendance.statuses.keys
      f.input :payment
      f.input :stripe_customer_id
    end

    f.actions
  end
end
