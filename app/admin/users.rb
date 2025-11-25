ActiveAdmin.register User do
  permit_params :email, :password, :password_confirmation,
                :first_name, :last_name, :bio, :phone, :avatar_url,
                :email_verified, :role_id

  includes :role

  index do
    selectable_column
    id_column
    column :email
    column :first_name
    column :last_name
    column :role
    column :email_verified do |user|
      status_tag(user.email_verified? ? "Vérifié" : "Non vérifié", class: user.email_verified? ? "ok" : "warning")
    end
    column :created_at
    actions
  end

  filter :email
  filter :first_name
  filter :last_name
  filter :role
  filter :email_verified
  filter :created_at

  show do
    attributes_table do
      row :email
      row :first_name
      row :last_name
      row :bio
      row :phone
      row :avatar_url
      row :role
      row :email_verified
      row :created_at
      row :updated_at
    end

    panel "Inscriptions" do
      table_for user.attendances.includes(:event) do
        column :event
        column :status do |attendance|
          status_tag(attendance.status)
        end
        column :created_at
      end
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs "Utilisateur" do
      f.input :email
      f.input :password, hint: ("Laissez vide pour conserver le mot de passe actuel" if f.object.persisted?)
      f.input :password_confirmation
      f.input :first_name
      f.input :last_name
      f.input :bio
      f.input :phone
      f.input :avatar_url
      f.input :role
      f.input :email_verified
    end

    f.actions
  end

  controller do
    def update
      if params[:user].present? && params[:user][:password].blank? && params[:user][:password_confirmation].blank?
        params[:user].delete(:password)
        params[:user].delete(:password_confirmation)
      end
      super
    end
  end
end
