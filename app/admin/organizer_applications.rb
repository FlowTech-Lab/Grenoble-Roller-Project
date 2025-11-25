ActiveAdmin.register OrganizerApplication do
  includes :user, :reviewed_by

  permit_params :user_id, :motivation, :status, :reviewed_by_id, :reviewed_at

  scope :all, default: true
  scope("En attente") { |scope| scope.where(status: "pending") }
  scope("Approuvées") { |scope| scope.where(status: "approved") }
  scope("Refusées") { |scope| scope.where(status: "rejected") }

  action_item :approve, only: :show, if: proc { resource.pending? } do
    link_to "Approuver", approve_admin_organizer_application_path(resource), method: :put
  end

  action_item :reject, only: :show, if: proc { resource.pending? } do
    link_to "Refuser", reject_admin_organizer_application_path(resource), method: :put
  end

  member_action :approve, method: :put do
    resource.update!(
      status: "approved",
      reviewed_by: current_user,
      reviewed_at: Time.current
    )
    redirect_to resource_path, notice: "Candidature approuvée."
  end

  member_action :reject, method: :put do
    resource.update!(
      status: "rejected",
      reviewed_by: current_user,
      reviewed_at: Time.current
    )
    redirect_to resource_path, alert: "Candidature refusée."
  end

  index do
    selectable_column
    id_column
    column :user
    column :status do |application|
      status_tag(application.status)
    end
    column :reviewed_by
    column :reviewed_at
    column :created_at
    actions
  end

  filter :user, collection: -> { User.order(:email) }
  filter :status, as: :select, collection: OrganizerApplication.statuses.keys
  filter :reviewed_by, collection: -> { User.order(:email) }
  filter :created_at

  show do
    attributes_table do
      row :user
      row :status
      row :motivation
      row :reviewed_by
      row :reviewed_at
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs "Candidature" do
      f.input :user, collection: User.order(:email)
      f.input :status, as: :select, collection: OrganizerApplication.statuses.keys
      f.input :motivation
      f.input :reviewed_by, collection: User.order(:email)
      f.input :reviewed_at, as: :datetime_select
    end

    f.actions
  end
end
