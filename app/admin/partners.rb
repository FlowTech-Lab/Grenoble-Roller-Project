ActiveAdmin.register Partner do
  permit_params :name, :url, :logo_url, :description, :is_active

  scope :all, default: true
  scope("Actifs") { |scope| scope.active }
  scope("Inactifs") { |scope| scope.inactive }

  index do
    selectable_column
    id_column
    column :name
    column :url do |partner|
      link_to(partner.url, partner.url, target: "_blank") if partner.url.present?
    end
    column :is_active do |partner|
      status_tag(partner.is_active ? "actif" : "inactif", class: partner.is_active ? "ok" : "warning")
    end
    column :updated_at
    actions
  end

  filter :name
  filter :is_active
  filter :created_at

  form do |f|
    f.semantic_errors

    f.inputs "Partenaire" do
      f.input :name
      f.input :url
      f.input :logo_url
      f.input :description
      f.input :is_active
    end

    f.actions
  end
end
