# frozen_string_literal: true

module Initiations
  class WaitlistEntriesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_initiation

    # POST /initiations/:initiation_id/waitlist_entries
    def create
      authorize @initiation, :join_waitlist? # Utiliser la policy spécifique pour la liste d'attente
      
      child_membership_id = params[:child_membership_id].presence
      needs_equipment = params[:needs_equipment] == "1"
      roller_size = params[:roller_size].presence
      wants_reminder = params[:wants_reminder].present? ? params[:wants_reminder] == "1" : false
      use_free_trial = params[:use_free_trial] == "1"
      
      # Vérifier que l'utilisateur peut utiliser l'essai gratuit si demandé
      if use_free_trial && current_user.attendances.where(free_trial_used: true).exists?
        redirect_to initiation_path(@initiation), alert: "Vous avez déjà utilisé votre essai gratuit."
        return
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
      authorize @initiation
      
      # Avec shallow, on reçoit l'ID directement dans params[:id]
      # Mais on peut aussi recevoir child_membership_id pour identifier l'entrée
      child_membership_id = params[:child_membership_id].presence
      
      waitlist_entry = if params[:id].present?
        # Si on a un ID (shallow route), chercher directement
        @initiation.waitlist_entries.find_by_hashid(params[:id])
      else
        # Sinon, chercher par child_membership_id (collection route)
        @initiation.waitlist_entries.find_by(
          user: current_user,
          child_membership_id: child_membership_id,
          status: ["pending", "notified"]
        )
      end
      
      unless waitlist_entry && waitlist_entry.user == current_user
        redirect_to initiation_path(@initiation), alert: "Vous n'êtes pas en liste d'attente pour cet événement."
        return
      end
      
      participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
      waitlist_entry.cancel!
      redirect_to initiation_path(@initiation), notice: "#{participant_name} avez été retiré(e) de la liste d'attente."
    end

    # POST /initiations/:initiation_id/waitlist_entries/:id/convert_to_attendance
    def convert_to_attendance
      authorize @initiation, :convert_waitlist_to_attendance?

      waitlist_entry_id = params[:id] || params[:waitlist_entry_id]
      waitlist_entry = @initiation.waitlist_entries.find_by_hashid(waitlist_entry_id)
      
      unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
        redirect_to initiation_path(@initiation), alert: "Entrée de liste d'attente introuvable ou non notifiée."
        return
      end
      
      # Vérifier que l'inscription "pending" existe toujours
      pending_attendance = @initiation.attendances.find_by(
        user: current_user,
        child_membership_id: waitlist_entry.child_membership_id,
        status: "pending"
      )
      
      unless pending_attendance
        redirect_to initiation_path(@initiation), alert: "La place réservée n'est plus disponible. Vous restez en liste d'attente."
        return
      end
      
      if waitlist_entry.convert_to_attendance!
        participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
        EventMailer.attendance_confirmed(pending_attendance.reload).deliver_later if current_user.wants_initiation_mail?
        redirect_to initiation_path(@initiation), notice: "Inscription confirmée pour #{participant_name} ! Vous avez été retiré(e) de la liste d'attente."
      else
        redirect_to initiation_path(@initiation), alert: "Impossible de confirmer votre inscription. Veuillez réessayer."
      end
    end

    # POST /initiations/:initiation_id/waitlist_entries/:id/refuse
    def refuse
      authorize @initiation, :refuse_waitlist?

      waitlist_entry_id = params[:id] || params[:waitlist_entry_id]
      waitlist_entry = @initiation.waitlist_entries.find_by_hashid(waitlist_entry_id)
      
      unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
        redirect_to initiation_path(@initiation), alert: "Entrée de liste d'attente introuvable ou non notifiée."
        return
      end
      
      if waitlist_entry.refuse!
        participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
        redirect_to initiation_path(@initiation), notice: "Vous avez refusé la place pour #{participant_name}. Vous restez en liste d'attente et serez notifié(e) si une autre place se libère."
      else
        redirect_to initiation_path(@initiation), alert: "Impossible de refuser la place. Veuillez réessayer."
      end
    end

    # GET /initiations/:initiation_id/waitlist_entries/:id/confirm
    def confirm
      authenticate_user!
      authorize @initiation, :convert_waitlist_to_attendance?

      waitlist_entry_id = params[:id] || params[:waitlist_entry_id]
      waitlist_entry = @initiation.waitlist_entries.find_by_hashid(waitlist_entry_id)
      
      unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
        redirect_to initiation_path(@initiation), alert: "Entrée de liste d'attente introuvable ou non notifiée."
        return
      end
      
      # Appeler la méthode POST via convert_to_attendance!
      if waitlist_entry.convert_to_attendance!
        participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
        redirect_to initiation_path(@initiation), notice: "Inscription confirmée pour #{participant_name} ! Vous avez été retiré(e) de la liste d'attente."
      else
        redirect_to initiation_path(@initiation), alert: "Impossible de confirmer votre inscription. Veuillez réessayer."
      end
    end

    # GET /initiations/:initiation_id/waitlist_entries/:id/decline
    def decline
      authenticate_user!
      authorize @initiation, :refuse_waitlist?

      waitlist_entry_id = params[:id] || params[:waitlist_entry_id]
      waitlist_entry = @initiation.waitlist_entries.find_by_hashid(waitlist_entry_id)
      
      unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
        redirect_to initiation_path(@initiation), alert: "Entrée de liste d'attente introuvable ou non notifiée."
        return
      end
      
      if waitlist_entry.refuse!
        participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
        redirect_to initiation_path(@initiation), notice: "Vous avez refusé la place pour #{participant_name}. Vous restez en liste d'attente et serez notifié(e) si une autre place se libère."
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

