ActiveAdmin.register AuditLog do
  menu priority: 14, label: "Logs d'audit"

  actions :index, :show
  config.sort_order = "created_at_desc"
  includes :actor_user

  filter :action
  filter :actor_user, collection: -> { User.order(:email) }
  filter :target_type
  filter :target_id
  filter :created_at

  index do
    id_column
    column :created_at
    column :actor_user
    column :action do |log|
      status_tag(log.action)
    end
    column :target_type
    column :target_id
    column :metadata do |log|
      log.metadata.present? ? truncate(log.metadata.to_json, length: 80) : "-"
    end
    actions
  end

  show do
    attributes_table do
      row :created_at
      row :actor_user
      row :action
      row :target_type
      row :target_id
      row :metadata do |log|
        pre JSON.pretty_generate(log.metadata || {})
      end
    end
  end
end
