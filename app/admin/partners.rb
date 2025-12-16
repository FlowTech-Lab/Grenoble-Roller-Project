ActiveAdmin.register Partner do
  menu priority: 2, label: "Partenaires", parent: "Communication"

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

  show do
    attributes_table do
      row :id
      row :name
      row :url do |partner|
        if partner.url.present?
          link_to(partner.url, partner.url, target: "_blank")
        else
          "-"
        end
      end
      row :logo_url do |partner|
        if partner.logo_url.present?
          image_tag(partner.logo_url, height: 100, style: "border-radius: 8px;")
        else
          status_tag("Aucun logo", class: "warning")
        end
      end
      row :description do |partner|
        partner.description.present? ? simple_format(partner.description) : "-"
      end
      row :is_active do |partner|
        status_tag(partner.is_active ? "Actif" : "Inactif", class: partner.is_active ? "ok" : "warning")
      end
      row :created_at
      row :updated_at
    end
  end

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

  controller do
    def destroy
      @partner = resource
      authorize @partner, :destroy?
      if @partner.destroy
        redirect_to collection_path, notice: "Le partenaire ##{@partner.id} a été supprimé avec succès."
      else
        redirect_to resource_path(@partner), alert: "Impossible de supprimer le partenaire : #{@partner.errors.full_messages.join(', ')}"
      end
    end
  end
end
