ActiveAdmin.register ContactMessage do
  menu priority: 13, label: "Messages de contact"
  
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
      row :name
      row :email
      row :subject
      row :message do |record|
        simple_format(record.message)
      end
      row :created_at
    end
  end
end
