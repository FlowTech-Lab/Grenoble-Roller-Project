ActiveAdmin.register Event::Initiation, as: "Initiation" do
  menu priority: 2, label: "Initiations", parent: "Événements"
  includes :creator_user, :attendances

  # Filtrer pour n'afficher que les initiations
  scope :all, default: true do |scope|
    scope.where(type: "Event::Initiation")
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
      begin
        count = initiation.participants_count
        "#{count} / #{initiation.max_participants}"
      rescue => e
        "Erreur"
      end
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
      row :id
      row :title
      row :status do |initiation|
        case initiation.status
        when "draft"
          status_tag("En attente", class: "warning")
        when "published"
          status_tag("Publié", class: "ok")
        when "canceled"
          status_tag("Annulé", class: "error")
        when "rejected"
          status_tag("Refusé", class: "error")
        else
          status_tag(initiation.status)
        end
      end
      row :start_at
      row :duration_min
      row :max_participants
      row "Places disponibles" do |initiation|
        begin
          if initiation.full?
            "Complet (0)"
          else
            "#{initiation.available_places} places restantes"
          end
        rescue => e
          "Erreur: #{e.message}"
        end
      end
      row "Participants" do |initiation|
        begin
          count = initiation.participants_count
          total_attendances = initiation.attendances.where(is_volunteer: false, status: ["registered", "present"]).count
          "#{count} (#{total_attendances} total inscriptions)"
        rescue => e
          "Erreur: #{e.message}"
        end
      end
      row "Bénévoles" do |initiation|
        begin
          initiation.volunteers_count
        rescue => e
          "Erreur: #{e.message}"
        end
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

    # Panel Bénévoles
    volunteers = initiation.attendances.includes(:user, :child_membership).where(is_volunteer: true).order(:created_at)
    if volunteers.any?
      panel "Bénévoles encadrants (#{volunteers.count})" do
        table_for volunteers do
          column "Bénévole" do |attendance|
            if attendance.child_membership_id.present?
              "#{attendance.participant_name} (enfant de #{attendance.user.email})"
            else
              attendance.user.email
            end
          end
          column :status do |attendance|
            status_tag(attendance.status)
          end
          column "Actions" do |attendance|
            link_to("Retirer bénévole", toggle_volunteer_activeadmin_initiation_path(initiation, attendance_id: attendance.id), 
                    method: :patch, 
                    class: "button button-small",
                    data: { confirm: "Retirer le statut bénévole pour #{attendance.user.email} ?" })
          end
          column "Matériel demandé" do |attendance|
            attendance.equipment_note.presence || "-"
          end
          column :created_at
        end
      end
    end

    # Panel Participants
    participants = initiation.attendances.includes(:user, :child_membership).where(is_volunteer: false).order(:created_at)
    panel "Participants (#{participants.count})" do
      if participants.any?
        table_for participants do
          column "Participant" do |attendance|
            if attendance.child_membership_id.present?
              "#{attendance.participant_name} (enfant de #{attendance.user.email})"
            else
              attendance.user.email
            end
          end
          column :status do |attendance|
            status_tag(attendance.status)
          end
          column "Essai gratuit" do |attendance|
            attendance.free_trial_used? ? status_tag("Oui", class: "ok") : status_tag("Non", class: "no")
          end
          column "Actions" do |attendance|
            link_to("Ajouter bénévole", toggle_volunteer_activeadmin_initiation_path(initiation, attendance_id: attendance.id), 
                    method: :patch, 
                    class: "button button-small",
                    data: { confirm: "Ajouter le statut bénévole pour #{attendance.user.email} ?" })
          end
          column "Matériel demandé" do |attendance|
            attendance.equipment_note.presence || "-"
          end
          column :created_at
        end
      else
        para "Aucun participant inscrit pour le moment."
      end
    end

    panel "Actions" do
      div do
        link_to "Voir les présences", presences_activeadmin_initiation_path(initiation), class: "button"
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
        collection: User.order(:email).map { |u| [ u.email, u.id ] },
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
    all_attendances = @initiation.attendances
      .includes(:user, :child_membership)
      .where(status: [ "registered", "present", "no_show" ])
      .order(:created_at)
    
    # Séparer bénévoles et participants
    @volunteers = all_attendances.where(is_volunteer: true)
    @participants = all_attendances.where(is_volunteer: false)
  end

  # Action personnalisée : Mise à jour présences (bulk)
  member_action :update_presences, method: :patch do
    @initiation = resource
    attendance_ids = params[:attendance_ids] || []
    presences = params[:presences] || {}
    is_volunteer_changes = params[:is_volunteer] || {}

    attendance_ids.each do |attendance_id|
      attendance = @initiation.attendances.find_by(id: attendance_id)
      next unless attendance

      # Mettre à jour le statut de présence
      presence_status = presences[attendance_id.to_s]
      if presence_status.present?
        attendance.update(status: presence_status)
      end
      
      # Mettre à jour is_volunteer si modifié
      if is_volunteer_changes[attendance_id.to_s].present?
        attendance.update(is_volunteer: is_volunteer_changes[attendance_id.to_s] == "1")
      end
    end

    redirect_to presences_activeadmin_initiation_path(@initiation), notice: "Présences mises à jour avec succès."
  end

  # Action pour basculer le statut bénévole d'une attendance
  member_action :toggle_volunteer, method: :patch do
    @initiation = resource
    attendance = @initiation.attendances.find_by(id: params[:attendance_id])
    
    if attendance
      attendance.update(is_volunteer: !attendance.is_volunteer)
      status = attendance.is_volunteer? ? "ajouté" : "retiré"
      redirect_to admin_initiation_path(@initiation), notice: "Statut bénévole #{status} pour #{attendance.user.email}."
    else
      redirect_to admin_initiation_path(@initiation), alert: "Inscription introuvable."
    end
  end

  controller do
    def destroy
      @initiation = resource
      if @initiation.destroy
        redirect_to collection_path, notice: "L'initiation ##{@initiation.id} a été supprimée avec succès."
      else
        redirect_to resource_path(@initiation), alert: "Impossible de supprimer l'initiation : #{@initiation.errors.full_messages.join(', ')}"
      end
    end
  end
end
