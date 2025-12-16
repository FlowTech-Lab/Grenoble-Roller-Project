ActiveAdmin.register Attendance do
  menu priority: 4, label: "Participations", parent: "Événements"

  includes :user, :event, :payment

  permit_params :user_id, :event_id, :status, :payment_id, :stripe_customer_id,
                :is_volunteer, :free_trial_used, :wants_reminder, :equipment_note,
                :needs_equipment, :roller_size

  scope :all, default: true
  scope("Actives") { |attendances| attendances.active }
  scope("Annulées") { |attendances| attendances.canceled }

  index do
    selectable_column
    id_column
    column :user
    column :event
    column :status do |attendance|
      status_tag(attendance.status)
    end
    column :payment
    column :stripe_customer_id
    column :created_at
    actions
  end

  filter :user, collection: -> { User.order(:last_name, :first_name) }
  filter :event
  filter :status, as: :select, collection: Attendance.statuses.keys
  filter :payment
  filter :is_volunteer
  filter :free_trial_used
  filter :created_at

  show do
    attributes_table do
      row :id
      row :user
      row :event
      row :status do |attendance|
        status_tag(attendance.status)
      end
      row :is_volunteer do |attendance|
        status_tag(attendance.is_volunteer? ? "Oui" : "Non", class: attendance.is_volunteer? ? "ok" : "")
      end
      row :free_trial_used do |attendance|
        status_tag(attendance.free_trial_used? ? "Oui" : "Non", class: attendance.free_trial_used? ? "warning" : "ok")
      end
      row :wants_reminder do |attendance|
        status_tag(attendance.wants_reminder? ? "Oui" : "Non", class: attendance.wants_reminder? ? "ok" : "")
      end
      row :needs_equipment do |attendance|
        status_tag(attendance.needs_equipment? ? "Oui" : "Non", class: attendance.needs_equipment? ? "ok" : "")
      end
      row :roller_size do |attendance|
        if attendance.needs_equipment? && attendance.roller_size.present?
          "#{attendance.roller_size} (EU)"
        else
          "-"
        end
      end
      row :equipment_note do |attendance|
        attendance.equipment_note.present? ? simple_format(attendance.equipment_note) : "-"
      end
      row :payment
      row :stripe_customer_id
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs "Inscription" do
      f.input :user, collection: -> { User.order(:last_name, :first_name) }
      f.input :event
      f.input :status, as: :select, collection: Attendance.statuses.keys
      f.input :is_volunteer, label: "Bénévole"
      f.input :free_trial_used, label: "Essai gratuit utilisé"
      f.input :wants_reminder, label: "Souhaite un rappel"
      f.input :needs_equipment, label: "Besoin de matériel"
      f.input :roller_size,
              as: :select,
              collection: RollerStock.available.ordered_by_size.map { |s| [ s.size_with_stock, s.size ] },
              include_blank: "Aucune taille",
              hint: "Taille de rollers demandée"
      f.input :equipment_note, as: :text, input_html: { rows: 3 }, hint: "Note sur l'équipement (ancien système)"
      f.input :payment
      f.input :stripe_customer_id
    end

    f.actions
  end

  controller do
    def destroy
      @attendance = resource
      authorize @attendance, :destroy?
      if @attendance.destroy
        redirect_to collection_path, notice: "La participation ##{@attendance.id} a été supprimée avec succès."
      else
        redirect_to resource_path(@attendance), alert: "Impossible de supprimer la participation : #{@attendance.errors.full_messages.join(', ')}"
      end
    end
  end
end
