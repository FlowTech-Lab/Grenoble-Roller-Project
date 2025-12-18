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
    column "Liste d'attente" do |initiation|
      waitlist_count = initiation.waitlist_entries.active.count
      waitlist_count > 0 ? status_tag(waitlist_count, class: "warning") : "-"
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
  filter :creator_user, collection: -> { User.order(:last_name, :first_name) }
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
          total_attendances = initiation.attendances.where(is_volunteer: false, status: [ "registered", "present" ]).count
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
            if attendance.needs_equipment? && attendance.roller_size.present?
              "Roller #{attendance.roller_size} (EU)"
            else
              "-"
            end
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
            if attendance.needs_equipment? && attendance.roller_size.present?
              "Roller #{attendance.roller_size} (EU)"
            else
              "-"
            end
          end
          column :created_at
        end
      else
        para "Aucun participant inscrit pour le moment."
      end
    end

    # Panel Liste d'attente
    waitlist_entries = initiation.waitlist_entries.includes(:user, :child_membership).active.ordered_by_position
    if waitlist_entries.any?
      panel "Liste d'attente (#{waitlist_entries.count})" do
        table_for waitlist_entries do
          column "Position" do |entry|
            "##{entry.position + 1}"
          end
          column "Personne" do |entry|
            if entry.child_membership_id.present?
              "#{entry.participant_name} (enfant de #{entry.user.email})"
            else
              entry.user.email
            end
          end
          column :status do |entry|
            case entry.status
            when "pending"
              status_tag("En attente", class: "warning")
            when "notified"
              status_tag("Notifié", class: "ok")
            else
              status_tag(entry.status)
            end
          end
          column "Notifié le" do |entry|
            entry.notified_at ? l(entry.notified_at, format: :long) : "-"
          end
          column "Créé le" do |entry|
            l(entry.created_at, format: :short)
          end
          column "Actions" do |entry|
            if entry.notified?
              button_to("Convertir en inscription",
                        convert_waitlist_activeadmin_initiation_path(initiation),
                        method: :post,
                        params: { waitlist_entry_id: entry.hashid },
                        class: "button button-small",
                        data: { confirm: "Convertir cette entrée de liste d'attente en inscription ?" })
            elsif entry.pending? && initiation.has_available_spots?
              button_to("Notifier maintenant",
                        notify_waitlist_activeadmin_initiation_path(initiation),
                        method: :post,
                        params: { waitlist_entry_id: entry.hashid },
                        class: "button button-small",
                        data: { confirm: "Notifier cette personne qu'une place est disponible ?" })
            else
              "-"
            end
          end
        end
      end
    else
      panel "Liste d'attente" do
        para "Aucune personne en liste d'attente."
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
        collection: User.order(:last_name, :first_name).map { |u| [ u.to_s, u.id ] },
        label_method: :to_s,
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

  # Action personnalisée : Convertir une entrée de liste d'attente en inscription
  member_action :convert_waitlist, method: :post do
    @initiation = resource
    waitlist_entry_id = params[:waitlist_entry_id]

    unless waitlist_entry_id.present?
      redirect_to resource_path(@initiation), alert: "Paramètre waitlist_entry_id manquant."
      return
    end

    waitlist_entry = @initiation.waitlist_entries.find_by_hashid(waitlist_entry_id)

    unless waitlist_entry
      redirect_to resource_path(@initiation), alert: "Entrée de liste d'attente introuvable."
      return
    end

    unless waitlist_entry.notified?
      redirect_to resource_path(@initiation), alert: "Cette entrée de liste d'attente n'est pas en statut 'notifié'."
      return
    end

    # Trouver l'inscription "pending" créée lors de la notification
    pending_attendance = @initiation.attendances.find_by(
      user: waitlist_entry.user,
      child_membership_id: waitlist_entry.child_membership_id,
      status: "pending"
    )

    unless pending_attendance
      redirect_to resource_path(@initiation), alert: "L'inscription 'pending' associée n'a pas été trouvée."
      return
    end

    # Passer de "pending" à "registered" sans validation
    # Utiliser update_column pour bypasser les validations
    if pending_attendance.update_column(:status, "registered")
      waitlist_entry.update!(status: "converted")
      # Notifier les autres personnes en liste d'attente si une place se libère
      WaitlistEntry.notify_next_in_queue(@initiation) if @initiation.has_available_spots?
      redirect_to resource_path(@initiation), notice: "L'entrée de liste d'attente a été convertie en inscription avec succès."
    else
      redirect_to resource_path(@initiation), alert: "Impossible de convertir l'entrée de liste d'attente."
    end
  end

  # Action personnalisée : Notifier manuellement une personne en liste d'attente
  member_action :notify_waitlist, method: :post do
    @initiation = resource
    waitlist_entry_id = params[:waitlist_entry_id]

    unless waitlist_entry_id.present?
      redirect_to resource_path(@initiation), alert: "Paramètre waitlist_entry_id manquant."
      return
    end

    waitlist_entry = @initiation.waitlist_entries.find_by_hashid(waitlist_entry_id)

    unless waitlist_entry
      redirect_to resource_path(@initiation), alert: "Entrée de liste d'attente introuvable."
      return
    end

    unless waitlist_entry.pending?
      redirect_to resource_path(@initiation), alert: "Cette entrée de liste d'attente n'est pas en statut 'pending'."
      return
    end

    if waitlist_entry.notify!
      redirect_to resource_path(@initiation), notice: "La personne a été notifiée avec succès."
    else
      redirect_to resource_path(@initiation), alert: "Impossible de notifier cette personne."
    end
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

    def active_admin_access_denied(exception)
      Rails.logger.error("ActiveAdmin access denied: #{exception.message}")
      Rails.logger.error("Current user: #{current_user&.email}, Role: #{current_user&.role&.code}")
      Rails.logger.error("Policy class: #{exception.policy.class.name rescue 'N/A'}")
      Rails.logger.error("Query: #{exception.query rescue 'N/A'}")
      redirect_to activeadmin_root_path, alert: "Vous n'êtes pas autorisé à exécuter cette action."
    end
  end
end
