# frozen_string_literal: true

module Events
  class WaitlistEntriesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_event, only: [ :create ] # set_event seulement pour les routes collection (create)

    # POST /events/:event_id/waitlist_entries
    def create
      unless user_signed_in?
        redirect_to new_user_session_path
        return
      end

      # Vérifier que @event est défini (set_event est appelé par before_action)
      unless @event
        redirect_to events_path, alert: "Événement introuvable."
        return
      end

      authorize @event, :join_waitlist?

        child_membership_id = params[:child_membership_id].presence
        wants_reminder = params[:wants_reminder].present? ? params[:wants_reminder] == "1" : false

        waitlist_entry = WaitlistEntry.add_to_waitlist(
          current_user,
          @event,
          child_membership_id: child_membership_id,
          needs_equipment: false, # Pas de matériel pour les événements/randos
          roller_size: nil,
          wants_reminder: wants_reminder
        )

        if waitlist_entry
          participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
          redirect_to @event, notice: "#{participant_name} avez été ajouté(e) à la liste d'attente. Vous serez notifié(e) par email si une place se libère."
        else
          redirect_to @event, alert: "Impossible d'ajouter à la liste d'attente. Vérifiez que l'événement est complet et que vous n'êtes pas déjà inscrit(e) ou en liste d'attente."
        end
    end

    # DELETE /waitlist_entries/:id (shallow)
    def destroy
      unless user_signed_in?
        redirect_to new_user_session_path
        return
      end

      child_membership_id = params[:child_membership_id].presence

      waitlist_entry = if params[:id].present?
        # Si on a un ID (shallow route), chercher directement
        WaitlistEntry.find_by_hashid(params[:id])
      else
        # Sinon, chercher par child_membership_id (collection route)
        # Dans ce cas, on a besoin de @event qui est défini par set_event
        @event.waitlist_entries.find_by(
          user: current_user,
          child_membership_id: child_membership_id,
          status: [ "pending", "notified" ]
        )
      end

      unless waitlist_entry && waitlist_entry.user == current_user
        event = waitlist_entry&.event || @event
        if event
          redirect_to event_path(event), alert: "Vous n'êtes pas en liste d'attente pour cet événement."
        else
          redirect_to events_path, alert: "Événement introuvable."
        end
        return
      end

      # Autoriser l'action sur l'événement
      event = waitlist_entry.event
      authorize event, :leave_waitlist?

      participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
      waitlist_entry.cancel!
      redirect_to event_path(event), notice: "#{participant_name} avez été retiré(e) de la liste d'attente."
    end

    # POST /waitlist_entries/:id/convert_to_attendance (shallow route)
    def convert_to_attendance
      unless user_signed_in?
        redirect_to new_user_session_path
        return
      end

      waitlist_entry_id = params[:id] || params[:waitlist_entry_id]
      waitlist_entry = WaitlistEntry.find_by_hashid(waitlist_entry_id)

      unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
        event = waitlist_entry&.event || @event
        redirect_to event_path(event), alert: "Entrée de liste d'attente introuvable ou non notifiée."
        return
      end

      # Autoriser l'action sur l'événement
      authorize waitlist_entry.event, :convert_waitlist_to_attendance?

      # Vérifier que l'inscription "pending" existe toujours
      pending_attendance = waitlist_entry.event.attendances.find_by(
        user: current_user,
        child_membership_id: waitlist_entry.child_membership_id,
        status: "pending"
      )

      unless pending_attendance
        redirect_to event_path(waitlist_entry.event), alert: "La place réservée n'est plus disponible. Vous restez en liste d'attente."
        return
      end

      if waitlist_entry.convert_to_attendance!
        participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
        EventMailer.attendance_confirmed(pending_attendance.reload).deliver_later if current_user.wants_events_mail?
        redirect_to event_path(waitlist_entry.event), notice: "Inscription confirmée pour #{participant_name} ! Vous avez été retiré(e) de la liste d'attente."
      else
        redirect_to event_path(waitlist_entry.event), alert: "Impossible de confirmer votre inscription. Veuillez réessayer."
      end
    end

    # POST /waitlist_entries/:id/refuse (shallow route)
    def refuse
      unless user_signed_in?
        redirect_to new_user_session_path
        return
      end

      waitlist_entry_id = params[:id] || params[:waitlist_entry_id]
      waitlist_entry = WaitlistEntry.find_by_hashid(waitlist_entry_id)

      unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
        event = waitlist_entry&.event || @event
        redirect_to event_path(event), alert: "Entrée de liste d'attente introuvable ou non notifiée."
        return
      end

      # Autoriser l'action sur l'événement
      authorize waitlist_entry.event, :refuse_waitlist?

      if waitlist_entry.refuse!
        participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
        redirect_to event_path(waitlist_entry.event), notice: "Vous avez refusé la place pour #{participant_name}. Vous restez en liste d'attente et serez notifié(e) si une autre place se libère."
      else
        redirect_to event_path(waitlist_entry.event), alert: "Impossible de refuser la place. Veuillez réessayer."
      end
    end

    # GET /waitlist_entries/:id/confirm (shallow route)
    def confirm
      authenticate_user!

      waitlist_entry_id = params[:id] || params[:waitlist_entry_id]
      waitlist_entry = WaitlistEntry.find_by_hashid(waitlist_entry_id)

      unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
        event = waitlist_entry&.event || @event
        redirect_to event_path(event), alert: "Entrée de liste d'attente introuvable ou non notifiée."
        return
      end

      # Autoriser l'action sur l'événement
      authorize waitlist_entry.event, :convert_waitlist_to_attendance?

      # Appeler la méthode POST via convert_to_attendance!
      if waitlist_entry.convert_to_attendance!
        participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
        redirect_to event_path(waitlist_entry.event), notice: "Inscription confirmée pour #{participant_name} ! Vous avez été retiré(e) de la liste d'attente."
      else
        redirect_to event_path(waitlist_entry.event), alert: "Impossible de confirmer votre inscription. Veuillez réessayer."
      end
    end

    # GET /waitlist_entries/:id/decline (shallow route)
    def decline
      authenticate_user!

      waitlist_entry_id = params[:id] || params[:waitlist_entry_id]
      waitlist_entry = WaitlistEntry.find_by_hashid(waitlist_entry_id)

      unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
        event = waitlist_entry&.event || @event
        redirect_to event_path(event), alert: "Entrée de liste d'attente introuvable ou non notifiée."
        return
      end

      # Autoriser l'action sur l'événement
      authorize waitlist_entry.event, :refuse_waitlist?

      if waitlist_entry.refuse!
        participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
        redirect_to event_path(waitlist_entry.event), notice: "Vous avez refusé la place pour #{participant_name}. Vous avez été retiré(e) de la liste d'attente."
      else
        redirect_to event_path(waitlist_entry.event), alert: "Impossible de refuser la place. Veuillez réessayer."
      end
    end

    private

    def set_event
      @event = Event.find_by_hashid(params[:event_id]) || Event.find(params[:event_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to events_path, alert: "Événement introuvable."
    end
  end
end
