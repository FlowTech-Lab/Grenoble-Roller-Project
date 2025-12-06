ActiveAdmin.register Event::Initiation, as: "Initiation" do
  menu priority: 2, label: "Initiations", parent: "Événements"
  includes :creator_user, :attendances
  
  # Filtrer pour n'afficher que les initiations
  scope :all, default: true do |scope|
    scope.where(type: 'Event::Initiation')
  end

  permit_params :creator_user_id, :status, :start_at, :duration_min, :title,
                :description, :location_text, :meeting_lat, :meeting_lng,
                :max_participants, :level, :distance_km

  scope :all, default: true
  scope("À venir") { |initiations| initiations.upcoming_initiations }
  scope("Publiées") { |initiations| initiations.published }
  scope("Annulées") { |initiations| initiations.where(status: "canceled") }

  index do
    selectable_column
    id_column
    column :title
    column :start_at
    column :status do |initiation|
      case initiation.status
      when "draft"
        status_tag("En attente", class: "warning")
      when "published"
        status_tag("Publié", class: "ok")
      when "canceled"
        status_tag("Annulé", class: "error")
      else
        status_tag(initiation.status)
      end
    end
    column "Places" do |initiation|
      "#{initiation.available_places} / #{initiation.max_participants}"
    end
    column "Participants" do |initiation|
      initiation.participants_count
    end
    column "Bénévoles" do |initiation|
      initiation.volunteers_count
    end
    column :creator_user do |initiation|
      initiation.creator_user&.email || "N/A"
    end
    actions
  end

  filter :title
  filter :status, as: :select, collection: {
    "En attente" => "draft",
    "Publié" => "published",
    "Annulé" => "canceled"
  }
  filter :start_at
  filter :creator_user, collection: -> { User.order(:email) }
  filter :created_at

  show do
    attributes_table do
      row :title
      row :status
      row :start_at
      row :duration_min
      row :max_participants
      row "Places disponibles" do |initiation|
        if initiation.full?
          "Complet (0)"
        else
          "#{initiation.available_places} places restantes"
        end
      end
      row "Participants" do |initiation|
        initiation.participants_count
      end
      row "Bénévoles" do |initiation|
        initiation.volunteers_count
      end
      row :creator_user do |initiation|
        initiation.creator_user&.email || "N/A"
      end
      row :location_text
      row :meeting_lat
      row :meeting_lng
      row :description
      row :created_at
      row :updated_at
    end

    panel "Inscriptions" do
      table_for initiation.attendances.includes(:user).order(:created_at) do
        column :user do |attendance|
          attendance.user.email
        end
        column :status do |attendance|
          status_tag(attendance.status)
        end
        column "Essai gratuit" do |attendance|
          attendance.free_trial_used? ? status_tag("Oui", class: "ok") : status_tag("Non", class: "no")
        end
        column "Bénévole" do |attendance|
          attendance.is_volunteer? ? status_tag("Oui", class: "ok") : status_tag("Non", class: "no")
        end
        column "Matériel demandé" do |attendance|
          attendance.equipment_note.presence || "-"
        end
        column :created_at
      end
    end

    panel "Actions" do
      div do
        link_to "Voir les présences", presences_admin_initiation_path(initiation), class: "button"
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
          "En attente" => "draft",
          "Publié" => "published",
          "Annulé" => "canceled"
        },
        prompt: "Sélectionnez un statut"
      f.input :creator_user,
        collection: User.order(:email).map { |u| [u.email, u.id] },
        label_method: :email,
        value_method: :id
      f.input :start_at, as: :datetime_select, hint: "Doit être un samedi à 10h15"
      f.input :duration_min, input_html: { value: f.object.duration_min || 105 }, hint: "Durée en minutes (105 = 1h45)"
      f.input :max_participants, label: "Nombre maximum de participants", input_html: { value: f.object.max_participants || 30 }
      f.input :description
    end

    f.inputs "Lieu" do
      f.input :location_text, input_html: { value: f.object.location_text || "Gymnase Ampère, 74 Rue Anatole France, 38100 Grenoble" }
      f.input :meeting_lat, hint: "45.1891"
      f.input :meeting_lng, hint: "5.7317"
    end

    f.actions
  end

  # Action personnalisée : Dashboard présences
  member_action :presences, method: :get do
    @initiation = resource
    @attendances = @initiation.attendances
      .includes(:user)
      .where(status: ['registered', 'present'])
      .order(:created_at)
  end

  # Action personnalisée : Mise à jour présences (bulk)
  member_action :update_presences, method: :patch do
    @initiation = resource
    attendance_ids = params[:attendance_ids] || []
    presences = params[:presences] || {}

    attendance_ids.each do |attendance_id|
      attendance = @initiation.attendances.find_by(id: attendance_id)
      next unless attendance

      presence_status = presences[attendance_id.to_s]
      if presence_status.present?
        attendance.update(status: presence_status)
      end
    end

    redirect_to presences_admin_initiation_path(@initiation), notice: "Présences mises à jour avec succès."
  end
end

