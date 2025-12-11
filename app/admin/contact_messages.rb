ActiveAdmin.register ContactMessage do
  menu priority: 1, label: "Messages de contact", parent: "Communication"

  actions :all, except: %i[new create edit update]

  config.filters = true

  index do
    selectable_column
    id_column
    column :name
    column :email
    column :subject
    column :created_at
    actions defaults: true do |message|
      link_to "Répondre", "mailto:#{message.email}?subject=#{ERB::Util.url_encode("Re: #{message.subject}")}"
    end
  end

  filter :name
  filter :email
  filter :subject
  filter :created_at

  show do
    attributes_table do
      row :id
      row :name
      row :email do |message|
        mail_to(message.email, message.email)
      end
      row :subject
      row :message do |record|
        simple_format(record.message)
      end
      row :created_at
      row :updated_at
    end
  end
end
