ActiveAdmin.register AuditLog do
  menu priority: 1, label: "Logs d'audit", parent: "Système"

  actions :index, :show
  config.sort_order = "created_at_desc"
  includes :actor_user

  filter :action
  filter :actor_user, collection: -> { User.order(:last_name, :first_name) }
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
      row :id
      row :created_at
      row :updated_at
      row :actor_user
      row :action do |log|
        status_tag(log.action)
      end
      row :target_type
      row :target_id
      row :metadata do |log|
        if log.metadata.present?
          pre JSON.pretty_generate(log.metadata)
        else
          "-"
        end
      end
    end
  end
end
