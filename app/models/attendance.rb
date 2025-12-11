class Attendance < ApplicationRecord
  belongs_to :user
  belongs_to :event, counter_cache: true
  belongs_to :payment, optional: true
  belongs_to :child_membership, class_name: "Membership", optional: true

  enum :status, {
    registered: "registered",
    paid: "paid",
    canceled: "canceled",
    present: "present",
    no_show: "no_show"
  }, validate: true

  validates :status, presence: true
  # Permettre plusieurs attendances pour le même user_id et event_id si child_membership_id est différent
  validates :user_id, uniqueness: { 
    scope: [:event_id, :child_membership_id], 
    message: "a déjà une inscription pour cet événement" 
  }
  validates :free_trial_used, inclusion: { in: [ true, false ] }
  validate :event_has_available_spots, on: :create
  validate :can_use_free_trial, on: :create
  validate :can_register_to_initiation, on: :create
  validate :child_membership_belongs_to_user

  scope :active, -> { where.not(status: "canceled") }
  scope :canceled, -> { where(status: "canceled") }
  scope :volunteers, -> { where(is_volunteer: true) }
  scope :participants, -> { where(is_volunteer: false) }
  scope :for_parent, -> { where(child_membership_id: nil) }
  scope :for_children, -> { where.not(child_membership_id: nil) }

  # Vérifier si c'est une inscription pour un enfant
  def for_child?
    child_membership_id.present?
  end

  # Vérifier si c'est une inscription pour le parent
  def for_parent?
    child_membership_id.nil?
  end

  # Nom de la personne inscrite (parent ou enfant)
  def participant_name
    if for_child?
      child_membership&.child_full_name || "Enfant"
    else
      user&.full_name || "Parent"
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id user_id event_id status payment_id stripe_customer_id wants_reminder free_trial_used is_volunteer equipment_note created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user event payment]
  end

  private

  def event_has_available_spots
    return unless event
    return if event.unlimited?
    # Ne pas vérifier la limite pour les inscriptions annulées (elles ne comptent pas)
    return if status == "canceled"
    # Bénévoles ne comptent pas dans la limite
    return if is_volunteer

    # Compter uniquement les inscriptions actives (non annulées) et non-bénévoles
    active_attendances_count = event.attendances.active.where(is_volunteer: false).count

    # Si on crée une nouvelle inscription, vérifier qu'il reste de la place
    # (ne pas compter cette inscription si elle n'est pas encore sauvegardée)
    if new_record?
      if active_attendances_count >= event.max_participants
        errors.add(:event, "L'événement est complet (#{event.max_participants} participants maximum)")
      end
    end
  end

  def can_use_free_trial
    return unless free_trial_used
    return unless user

    # Vérifier que l'utilisateur n'a pas déjà utilisé son essai gratuit
    if user.attendances.where(free_trial_used: true).where.not(id: id).exists?
      errors.add(:free_trial_used, "Vous avez déjà utilisé votre essai gratuit")
    end
  end

  def can_register_to_initiation
    return unless event.is_a?(Event::Initiation)
    return if is_volunteer # Bénévoles bypassent les validations

    # Vérifier places disponibles (déjà fait dans event_has_available_spots mais on double-vérifie)
    if event.full?
      errors.add(:event, "Cette séance est complète")
      return
    end

    # Vérifier adhésion ou essai gratuit
    if free_trial_used
      # Essai utilisé → vérifier qu'il n'a pas déjà été utilisé ailleurs
      if user.attendances.where(free_trial_used: true).where.not(id: id).exists?
        errors.add(:free_trial_used, "Vous avez déjà utilisé votre essai gratuit")
      end
    else
      # Si c'est pour un enfant, vérifier que l'adhésion enfant est active
      if for_child?
        unless child_membership&.active?
          errors.add(:child_membership_id, "L'adhésion de cet enfant n'est pas active")
        end
      else
        # Pas d'essai → vérifier adhésion active (parent OU enfant)
        has_active_membership = user.memberships.active_now.exists?
        has_child_membership = user.memberships.active_now.where(is_child_membership: true).exists?

        unless has_active_membership || has_child_membership
          errors.add(:base, "Adhésion requise. Utilisez votre essai gratuit ou adhérez à l'association.")
        end
      end
    end
  end

  def child_membership_belongs_to_user
    return unless child_membership_id.present?
    return unless user

    unless user.memberships.exists?(id: child_membership_id)
      errors.add(:child_membership_id, "Cette adhésion enfant ne vous appartient pas")
    end
  end
end
