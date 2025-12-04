ActiveAdmin.register Event::Initiation, as: "Initiation" do
  menu priority: 7, label: "Initiations", parent: "Événements"
  includes :creator_user, :attendances

  # Action pour générer une série d'initiations
  collection_action :generate_series, method: :get do
    @season = params[:season] || Membership.current_season_name
    @start_date = params[:start_date] || Date.new(Date.current.year, 9, 1)
    @end_date = params[:end_date] || Date.new(Date.current.year + 1, 8, 31)
  end

  collection_action :create_series, method: :post do
    season = params[:season]
    start_date = Date.parse(params[:start_date]) rescue nil
    end_date = Date.parse(params[:end_date]) rescue nil
    # Dans ActiveAdmin, current_user est disponible et retourne l'User
    creator_user = current_user

    if season.blank? || start_date.blank? || end_date.blank?
      redirect_to generate_series_admin_initiations_path, alert: "Tous les champs sont requis."
      return
    end

    service = Initiations::GenerationService.new(
      season: season,
      start_date: start_date,
      end_date: end_date,
      creator_user: creator_user
    )

    result = service.call

    if result[:success]
      redirect_to admin_initiations_path(scope: "all"), 
        notice: "#{result[:count]} séances d'initiation créées avec succès pour la saison #{season}."
    else
      redirect_to generate_series_admin_initiations_path, 
        alert: "Erreurs lors de la création : #{result[:errors].join(', ')}"
    end
  end

  permit_params :creator_user_id, :status, :start_at, :duration_min, :title,
                :description, :location_text, :meeting_lat, :meeting_lng,
                :max_participants, :level, :distance_km, :season,
                :is_recurring, :recurring_day, :recurring_time,
                :recurring_start_date, :recurring_end_date

  scope :all, default: true
  scope("À venir") { |initiations| initiations.upcoming_initiations }
  scope("Publiées") { |initiations| initiations.published }
  scope("Annulées") { |initiations| initiations.where(status: "canceled") }
  scope("Saison courante") { |initiations| initiations.by_season(Membership.current_season_name) }

  action_item :generate_series, only: :index do
    link_to "Générer une série", generate_series_admin_initiations_path, class: "button"
  end

  index do
    selectable_column
    id_column
    column :title
    column :start_at
    column :season
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
  filter :season
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
      row :season
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
      row :is_recurring
      row :recurring_day
      row :recurring_time
      row :recurring_start_date
      row :recurring_end_date
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
      div style: "margin-top: 10px;" do
        link_to "Exporter demandes matériel", material_export_admin_initiation_path(initiation), class: "button"
      end
      div style: "margin-top: 10px;" do
        link_to "Exporter CSV participants", participants_export_admin_initiation_path(initiation), class: "button"
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
      f.input :season, hint: "Ex: 2025-2026"
      f.input :description
    end

    f.inputs "Lieu" do
      f.input :location_text, input_html: { value: f.object.location_text || "Gymnase Ampère, 74 Rue Anatole France, 38100 Grenoble" }
      f.input :meeting_lat, hint: "45.1891"
      f.input :meeting_lng, hint: "5.7317"
    end

    f.inputs "Récurrence (optionnel)" do
      f.input :is_recurring, as: :boolean
      f.input :recurring_day, as: :select, collection: { "Samedi" => "saturday" }, hint: "Toujours samedi pour les initiations"
      f.input :recurring_time, input_html: { value: f.object.recurring_time || "10:15" }, hint: "Format HH:MM"
      f.input :recurring_start_date, as: :date_picker
      f.input :recurring_end_date, as: :date_picker
    end

    f.actions
  end

  # Action personnalisée : Export demandes matériel (WhatsApp)
  member_action :material_export, method: :get do
    initiation = resource
    demands = initiation.attendances
      .where("equipment_note IS NOT NULL AND equipment_note != ''")
      .includes(:user)
      .order(:created_at)

    text = demands.map do |attendance|
      user = attendance.user
      phone = user.phone.presence || "N/A"
      "#{user.first_name} #{user.last_name} (#{phone}): #{attendance.equipment_note}"
    end.join("\n")

    send_data text, filename: "demandes_materiel_#{initiation.id}_#{Date.current.strftime('%Y%m%d')}.txt", type: "text/plain"
  end

  # Action personnalisée : Export CSV participants
  member_action :participants_export, method: :get do
    initiation = resource
    attendances = initiation.attendances.includes(:user).order(:created_at)

    require 'csv'
    csv = CSV.generate(headers: true) do |csv|
      csv << ["Nom", "Prénom", "Email", "Téléphone", "Statut", "Essai gratuit", "Bénévole", "Matériel demandé", "Date inscription"]
      attendances.each do |attendance|
        user = attendance.user
        csv << [
          user.last_name,
          user.first_name,
          user.email,
          user.phone || "",
          attendance.status,
          attendance.free_trial_used? ? "Oui" : "Non",
          attendance.is_volunteer? ? "Oui" : "Non",
          attendance.equipment_note || "",
          attendance.created_at.strftime("%d/%m/%Y %H:%M")
        ]
      end
    end

    send_data csv, filename: "participants_#{initiation.id}_#{Date.current.strftime('%Y%m%d')}.csv", type: "text/csv"
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

