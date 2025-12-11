ActiveAdmin.register Role do
  menu priority: 2, label: "Rôles", parent: "Utilisateurs", if: proc { authorized?(:read, Role) }

  permit_params :name, :code, :description, :level

  config.filters = true

  index do
    selectable_column
    id_column
    column :name
    column :code
    column :level
    column :description
    column :created_at
    column :updated_at
    actions
  end

  filter :name
  filter :code
  filter :level
  filter :users_email_cont, label: "Utilisateur (email contient)"
  filter :created_at
  filter :updated_at

  show do
    attributes_table do
      row :name
      row :code
      row :level
      row :description
      row :created_at
      row :updated_at
    end

    panel "Utilisateurs associés" do
      table_for role.users.order(:email) do
        column :email
        column :first_name
        column :last_name
        column :created_at
      end
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs "Rôle" do
      f.input :name
      f.input :code
      f.input :level
      f.input :description
    end

    f.actions
  end
end
