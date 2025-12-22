# frozen_string_literal: true

module Initiations
  class WaitlistEntriesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_initiation, only: [ :create, :destroy ] # set_initiation seulement pour les routes collection

    # POST /initiations/:initiation_id/waitlist_entries
    def create
      authorize @initiation, :join_waitlist? # Utiliser la policy spécifique pour la liste d'attente

      child_membership_id = params[:child_membership_id].presence
      needs_equipment = params[:needs_equipment] == "1"
      roller_size = params[:roller_size].presence
      wants_reminder = params[:wants_reminder].present? ? params[:wants_reminder] == "1" : false
      use_free_trial = params[:use_free_trial] == "1"

      # Vérifier que l'utilisateur peut utiliser l'essai gratuit si demandé
      # IMPORTANT : Distinguer parent vs enfant pour vérifier l'essai gratuit
      if use_free_trial
        if child_membership_id.present?
          # Pour un enfant : vérifier si CET ENFANT a déjà utilisé son essai gratuit
          free_trial_already_used = current_user.attendances.active.where(
            free_trial_used: true, 
            child_membership_id: child_membership_id
          ).exists?
          
          if free_trial_already_used
            redirect_to initiation_path(@initiation), alert: "Cet enfant a déjà utilisé son essai gratuit."
            return
          end
        else
          # Pour le parent : vérifier si le PARENT a déjà utilisé son essai gratuit
          free_trial_already_used = current_user.attendances.active.where(
            free_trial_used: true, 
            child_membership_id: nil
          ).exists?
          
          if free_trial_already_used
            redirect_to initiation_path(@initiation), alert: "Vous avez déjà utilisé votre essai gratuit."
            return
          end
        end
      end

      if needs_equipment && roller_size.blank?
        redirect_to initiation_path(@initiation), alert: "Veuillez sélectionner une taille de rollers si vous avez besoin de matériel."
        return
      end
      if needs_equipment && roller_size.present?
        unless RollerStock::SIZES.include?(roller_size)
          redirect_to initiation_path(@initiation), alert: "La taille de rollers sélectionnée n'est pas valide."
          return
        end
      end

      waitlist_entry = WaitlistEntry.add_to_waitlist(
        current_user,
        @initiation,
        child_membership_id: child_membership_id,
        needs_equipment: needs_equipment,
        roller_size: roller_size,
        wants_reminder: wants_reminder,
        use_free_trial: use_free_trial
      )

      if waitlist_entry
        participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
        redirect_to initiation_path(@initiation), notice: "#{participant_name} avez été ajouté(e) à la liste d'attente. Vous serez notifié(e) par email si une place se libère."
      else
        redirect_to initiation_path(@initiation), alert: "Impossible d'ajouter à la liste d'attente. Vérifiez que l'événement est complet et que vous n'êtes pas déjà inscrit(e) ou en liste d'attente."
      end
    end

    # DELETE /waitlist_entries/:id (shallow)
    def destroy
      child_membership_id = params[:child_membership_id].presence

      waitlist_entry = if params[:id].present?
        # Si on a un ID (shallow route), chercher directement
        WaitlistEntry.find_by_hashid(params[:id])
      else
        # Sinon, chercher par child_membership_id (collection route)
        # Dans ce cas, on a besoin de @initiation qui est défini par set_initiation
        @initiation.waitlist_entries.find_by(
          user: current_user,
          child_membership_id: child_membership_id,
          status: [ "pending", "notified" ]
        )
      end

      unless waitlist_entry && waitlist_entry.user == current_user
        event = waitlist_entry&.event || @initiation
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "Vous n'êtes pas en liste d'attente pour cet événement."
        return
      end

      # Autoriser l'action sur l'événement
      authorize waitlist_entry.event, :leave_waitlist?

      participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
      waitlist_entry.cancel!
      event = waitlist_entry.event
      redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
      redirect_to redirect_path, notice: "#{participant_name} avez été retiré(e) de la liste d'attente."
    end

    # POST /waitlist_entries/:id/convert_to_attendance (shallow route)
    def convert_to_attendance
      waitlist_entry_id = params[:id] || params[:waitlist_entry_id]
      waitlist_entry = WaitlistEntry.find_by_hashid(waitlist_entry_id)

      unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
        event = waitlist_entry&.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "Entrée de liste d'attente introuvable ou non notifiée."
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
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "La place réservée n'est plus disponible. Vous restez en liste d'attente."
        return
      end

      if waitlist_entry.convert_to_attendance!
        participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
        EventMailer.attendance_confirmed(pending_attendance.reload).deliver_later if current_user.wants_initiation_mail?
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, notice: "Inscription confirmée pour #{participant_name} ! Vous avez été retiré(e) de la liste d'attente."
      else
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "Impossible de confirmer votre inscription. Veuillez réessayer."
      end
    end

    # POST /waitlist_entries/:id/refuse (shallow route)
    def refuse
      waitlist_entry_id = params[:id] || params[:waitlist_entry_id]
      waitlist_entry = WaitlistEntry.find_by_hashid(waitlist_entry_id)

      unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
        event = waitlist_entry&.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "Entrée de liste d'attente introuvable ou non notifiée."
        return
      end

      # Autoriser l'action sur l'événement
      authorize waitlist_entry.event, :refuse_waitlist?

      if waitlist_entry.refuse!
        participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, notice: "Vous avez refusé la place pour #{participant_name}. Vous restez en liste d'attente et serez notifié(e) si une autre place se libère."
      else
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "Impossible de refuser la place. Veuillez réessayer."
      end
    end

    # GET /waitlist_entries/:id/confirm (shallow route)
    def confirm
      waitlist_entry_id = params[:id] || params[:waitlist_entry_id]
      waitlist_entry = WaitlistEntry.find_by_hashid(waitlist_entry_id)

      unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
        event = waitlist_entry&.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "Entrée de liste d'attente introuvable ou non notifiée."
        return
      end

      # Autoriser l'action sur l'événement
      authorize waitlist_entry.event, :convert_waitlist_to_attendance?

      # Appeler la méthode POST via convert_to_attendance!
      if waitlist_entry.convert_to_attendance!
        participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, notice: "Inscription confirmée pour #{participant_name} ! Vous avez été retiré(e) de la liste d'attente."
      else
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "Impossible de confirmer votre inscription. Veuillez réessayer."
      end
    end

    # GET /waitlist_entries/:id/decline (shallow route)
    def decline
      waitlist_entry_id = params[:id] || params[:waitlist_entry_id]
      waitlist_entry = WaitlistEntry.find_by_hashid(waitlist_entry_id)

      unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
        event = waitlist_entry&.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "Entrée de liste d'attente introuvable ou non notifiée."
        return
      end

      # Autoriser l'action sur l'événement
      authorize waitlist_entry.event, :refuse_waitlist?

      if waitlist_entry.refuse!
        participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, notice: "Vous avez refusé la place pour #{participant_name}. Vous restez en liste d'attente et serez notifié(e) si une autre place se libère."
      else
        event = waitlist_entry.event
        redirect_path = event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
        redirect_to redirect_path, alert: "Impossible de refuser la place. Veuillez réessayer."
      end
    end

    private

    def set_initiation
      @initiation = Event::Initiation.find(params[:initiation_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to initiations_path, alert: "Initiation introuvable."
    end
  end
end
