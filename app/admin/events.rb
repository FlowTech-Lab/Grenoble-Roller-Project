ActiveAdmin.register Event do
  menu priority: 1, label: "Randos", parent: "Événements"
  includes :creator_user, :route
  
  # Filtrer pour exclure les initiations (STI)
  scope :all, default: true do |scope|
    scope.where("type IS NULL OR type != 'Event::Initiation'")
  end

  permit_params :creator_user_id, :status, :start_at, :duration_min, :title,
                :description, :price_cents, :currency, :location_text,
                :meeting_lat, :meeting_lng, :route_id,
                :max_participants, :level, :distance_km
  scope("À venir") { |events| events.where("type IS NULL OR type != 'Event::Initiation'").upcoming }
  scope("Publiés") { |events| events.where("type IS NULL OR type != 'Event::Initiation'").published }
  scope("En attente de validation", default: true) { |events| events.where("type IS NULL OR type != 'Event::Initiation'").pending_validation }
  scope("Refusés") { |events| events.where("type IS NULL OR type != 'Event::Initiation'").rejected }
  scope("Annulés") { |events| events.where("type IS NULL OR type != 'Event::Initiation'").where(status: "canceled") }

  index do
    selectable_column
    id_column
    column :title
    column :status do |event|
      case event.status
      when "draft"
        status_tag("En attente", class: "warning")
      when "published"
        status_tag("Publié", class: "ok")
      when "rejected"
        status_tag("Refusé", class: "error")
      when "canceled"
        status_tag("Annulé", class: "error")
      else
        status_tag(event.status)
      end
    end
    column :start_at
    column :duration_min
    column :max_participants do |event|
      event.unlimited? ? "Illimité" : event.max_participants
    end
    column :attendances_count
    column :route
    column :creator_user do |event|
      event.creator_user&.email || "N/A"
    end
    column :price_cents do |event|
      number_to_currency(event.price_cents / 100.0, unit: event.currency)
    end
    actions
  end

  filter :title
  filter :status, as: :select, collection: {
    "En attente de validation" => "draft",
    "Publié" => "published",
    "Refusé" => "rejected",
    "Annulé" => "canceled"
  }
  filter :route
  filter :creator_user, collection: -> { User.order(:email) }
  filter :start_at
  filter :created_at

  show do
    attributes_table do
      row :title
      row :status
      row :start_at
      row :duration_min
      row :max_participants do |event|
        event.unlimited? ? "Illimité (0)" : event.max_participants
      end
      row :attendances_count
      row :remaining_spots do |event|
        if event.unlimited?
          "Illimité"
        elsif event.full?
          "Complet (0)"
        else
          "#{event.remaining_spots} places restantes"
        end
      end
      row :creator_user do |event|
        event.creator_user&.email || "N/A"
      end
      row :route
      row :price_cents do |event|
        number_to_currency(event.price_cents / 100.0, unit: event.currency)
      end
      row :currency
      row :location_text
      row :meeting_lat
      row :meeting_lng
      row :cover_image do |event|
        if event.cover_image.attached?
          image_tag(rails_representation_path(event.cover_image_thumb), height: 150, style: "border-radius: 8px;")
        else
          status_tag("Aucune image", class: "warning")
        end
      end
      row :description
      row :created_at
      row :updated_at
    end

    panel "Inscriptions" do
      table_for event.attendances.includes(:user) do
        column :user
        column :status do |attendance|
          status_tag(attendance.status)
        end
        column :payment
        column :created_at
      end
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs "Informations générales" do
      f.input :title
      f.input :status,
        as: :select,
        collection: {
          "En attente de validation" => "draft",
          "Publié" => "published",
          "Refusé" => "rejected",
          "Annulé" => "canceled"
        },
        prompt: "Sélectionnez un statut",
        hint: "Changer le statut pour valider, publier, refuser ou annuler l'événement"
      f.input :route
      f.input :creator_user,
        collection: User.order(:email).map { |u| [ u.email, u.id ] },
        label_method: :email,
        value_method: :id
      f.input :start_at, as: :datetime_select
      f.input :duration_min
      f.input :max_participants, label: "Nombre maximum de participants", hint: "Mettez 0 pour un nombre illimité de participants."
      f.input :level,
        as: :select,
        collection: {
          "Débutant" => "beginner",
          "Intermédiaire" => "intermediate",
          "Confirmé" => "advanced",
          "Tous niveaux" => "all_levels"
        }
      f.input :distance_km, label: "Distance (km)", input_html: { min: 0.1, step: 0.1 }
      f.input :location_text
      f.input :description
    end

    f.inputs "Tarification" do
      f.input :price_cents, label: "Prix (cents)"
      f.input :currency, input_html: { value: f.object.currency || "EUR" }
    end

    f.inputs "Point de rendez-vous" do
      f.input :meeting_lat
      f.input :meeting_lng
      f.input :cover_image, as: :file, hint: "Upload une image de couverture (1200x800 recommandé)"
    end

    f.actions
  end
end
