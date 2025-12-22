# frozen_string_literal: true

class WaitlistEntry < ApplicationRecord
  include Hashid::Rails

  belongs_to :user
  belongs_to :event
  belongs_to :child_membership, class_name: "Membership", optional: true

  enum :status, {
    pending: "pending",      # En attente
    notified: "notified",    # Notifié qu'une place est disponible
    converted: "converted",  # Converti en inscription (place prise)
    cancelled: "cancelled"   # Annulé par l'utilisateur
  }, validate: true

  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: {
    scope: [ :event_id, :child_membership_id ],
    message: "est déjà en liste d'attente pour cet événement",
    conditions: -> { where.not(status: "cancelled") }
  }
  validate :event_is_full, on: :create
  validate :user_not_already_registered, on: :create
  validate :child_membership_belongs_to_user
  validates :roller_size, presence: true, if: :needs_equipment?
  validates :roller_size, inclusion: { in: RollerStock::SIZES }, if: :needs_equipment?

  # Scopes
  scope :active, -> { where(status: [ "pending", "notified" ]) }
  scope :for_event, ->(event) { where(event: event) }
  scope :ordered_by_position, -> { order(:position, :created_at) }
  scope :pending_notification, -> { where(status: "pending", notified_at: nil) }

  # Callbacks
  before_create :set_position
  after_create :log_waitlist_addition

  # ==================== MÉTHODES MÉTIER ====================

  def participant_name
    if child_membership_id.present?
      "#{child_membership.child_first_name} #{child_membership.child_last_name}"
    else
      # Construire le nom complet à partir de first_name et last_name
      name_parts = [ user.first_name, user.last_name ].compact.reject(&:blank?)
      name_parts.any? ? name_parts.join(" ") : user.email
    end
  end

  def for_child?
    child_membership_id.present?
  end

  def notify!
    return false unless pending?

    # Créer une inscription "pending" pour verrouiller la place
    attendance = build_pending_attendance
    bypass_validations_if_initiation(attendance)

    if attendance.save(validate: false) # Sauvegarder sans validation pour éviter les erreurs d'autorisation
      update!(
        status: "notified",
        notified_at: Time.current
      )

      # Envoyer l'email immédiatement (pas en queue) pour s'assurer qu'il est envoyé
      send_notification_email
      Rails.logger.info("WaitlistEntry #{id} notified and pending attendance #{attendance.id} created for event #{event.id} (user: #{user_id})")
      true
    else
      handle_attendance_save_error(attendance, "notify!")
      false
    end
  end

  def convert_to_attendance!
    return false unless notified?

    # Trouver l'inscription "pending" créée lors de la notification
    attendance = find_pending_attendance

    unless attendance
      Rails.logger.error("Pending attendance not found for WaitlistEntry #{id} (user: #{user_id}, event: #{event_id}, child_membership_id: #{child_membership_id.inspect})")
      return false
    end

    # Passer de "pending" à "registered"
    # Ne pas re-vérifier les validations d'adhésion/essai gratuit car elles ont déjà été vérifiées lors de l'inscription en liste d'attente
    bypass_validations_if_initiation(attendance)

    # Utiliser update_column pour bypasser les validations
    if attendance.update_column(:status, "registered")
      update!(status: "converted")
      # Notifier les autres personnes en liste d'attente si une place se libère
      event.notify_next_waitlist_entry
      Rails.logger.info("WaitlistEntry #{id} converted to attendance #{attendance.id} (user: #{user_id}, event: #{event_id})")
      true
    else
      handle_attendance_save_error(attendance, "convert_to_attendance!")
      false
    end
  end

  def refuse!
    return false unless notified?

    # Trouver et supprimer l'inscription "pending"
    attendance = find_pending_attendance

    unless attendance
      Rails.logger.error("Pending attendance not found for WaitlistEntry #{id} (user: #{user_id}, event: #{event_id}, child_membership_id: #{child_membership_id.inspect})")
      return false
    end

    if attendance.destroy
      # Remettre l'entrée en "pending" pour qu'elle puisse être notifiée à nouveau plus tard
      update!(status: "pending", notified_at: nil)
      # Notifier la prochaine personne en liste d'attente
      WaitlistEntry.notify_next_in_queue(event)
      Rails.logger.info("WaitlistEntry #{id} refused, pending attendance destroyed, next person notified (user: #{user_id}, event: #{event_id})")
      true
    else
      Rails.logger.error("Failed to destroy pending attendance #{attendance.id} for WaitlistEntry #{id} (user: #{user_id}, event: #{event_id})")
      false
    end
  end

  def cancel!
    update!(status: "cancelled")
    # Réorganiser les positions des autres entrées
    WaitlistEntry.reorganize_positions(event)
  end

  # ==================== MÉTHODES DE CLASSE ====================

  def self.add_to_waitlist(user, event, child_membership_id: nil, needs_equipment: false, roller_size: nil, wants_reminder: false, use_free_trial: false)
    return nil if event.has_available_spots?

    # Vérifier si déjà en liste d'attente
    existing = find_by(
      user: user,
      event: event,
      child_membership_id: child_membership_id,
      status: [ "pending", "notified" ]
    )
    return existing if existing

    # Créer l'entrée avec toutes les informations
    create!(
      user: user,
      event: event,
      child_membership_id: child_membership_id,
      needs_equipment: needs_equipment,
      roller_size: roller_size,
      wants_reminder: wants_reminder,
      use_free_trial: use_free_trial
    )
  end

  def self.notify_next_in_queue(event, count: 1)
    # Notifier les N premières personnes en liste d'attente
    # Notifier si l'événement a des places disponibles (une place vient de se libérer)
    # Ne pas notifier si l'événement est encore complet (pas de place disponible)
    return if event.full?

    entries = for_event(event)
              .pending_notification
              .ordered_by_position
              .limit(count)

    entries.each(&:notify!)
  end

  def self.reorganize_positions(event)
    # Réorganiser les positions après une annulation
    entries = for_event(event).active.ordered_by_position
    entries.each_with_index do |entry, index|
      entry.update_column(:position, index) if entry.position != index
    end
  end

  # ==================== MÉTHODES PRIVÉES ====================

  private

  # Construire l'attendance pending pour verrouiller la place
  def build_pending_attendance
    event.attendances.build(
      user: user,
      child_membership_id: child_membership_id,
      status: "pending",
      wants_reminder: wants_reminder || false,
      needs_equipment: needs_equipment || false,
      roller_size: roller_size,
      free_trial_used: use_free_trial || false
    )
  end

  # Trouver l'attendance pending associée à cette waitlist entry
  # Utiliser where pour gérer correctement les valeurs NULL en SQL
  # Note: Utiliser Attendance.unscoped directement pour éviter les problèmes de cache/association
  def find_pending_attendance
    # Utiliser Attendance.unscoped directement au lieu de event.attendances pour éviter le cache
    base_query = Attendance.unscoped.where(
      event_id: event_id,
      user_id: user_id,
      status: "pending"
    )

    if child_membership_id.nil?
      base_query.where("child_membership_id IS NULL").first
    else
      base_query.where(child_membership_id: child_membership_id).first
    end
  end

  # Bypasser les validations pour les initiations si nécessaire
  def bypass_validations_if_initiation(attendance)
    return unless event.is_a?(Event::Initiation)

    # Bypasser les validations can_use_free_trial et can_register_to_initiation
    attendance.define_singleton_method(:can_use_free_trial) { true }
    attendance.define_singleton_method(:can_register_to_initiation) { true }
  end

  # Envoyer l'email de notification pour une place disponible
  def send_notification_email
    EventMailer.waitlist_spot_available(self).deliver_now
  rescue => e
    Rails.logger.error("Failed to send waitlist notification email for WaitlistEntry #{id}: #{e.message}")
    # Ne pas faire échouer la notification si l'email échoue
  end

  # Gérer les erreurs de sauvegarde d'attendance
  def handle_attendance_save_error(attendance, action)
    error_msg = attendance.errors.full_messages.join(", ")
    Rails.logger.error("Failed in #{action} for WaitlistEntry #{id}: #{error_msg} (user: #{user_id}, event: #{event_id})")
  end

  def set_position
    # Position = nombre d'entrées actives pour cet événement
    max_position = WaitlistEntry.for_event(event).active.maximum(:position) || -1
    self.position = max_position + 1
  end

  def event_is_full
    return if event.nil?
    # Vérifier que l'événement est complet (en excluant les inscriptions "pending")
    # car on peut rejoindre la liste d'attente même s'il y a des places "pending" verrouillées
    unless event.full?
      errors.add(:event, "L'événement n'est pas complet, vous pouvez vous inscrire directement")
    end
  end

  def user_not_already_registered
    return if user.nil? || event.nil?

    existing_attendance = user.attendances.find_by(
      event: event,
      child_membership_id: child_membership_id
    )

    if existing_attendance && existing_attendance.status != "canceled"
      errors.add(:user, "Vous êtes déjà inscrit(e) à cet événement")
    end
  end

  def child_membership_belongs_to_user
    return if child_membership_id.nil?

    unless user.memberships.exists?(id: child_membership_id, is_child_membership: true)
      errors.add(:child_membership_id, "Cette adhésion enfant ne vous appartient pas")
    end
  end

  def log_waitlist_addition
    Rails.logger.info("WaitlistEntry created - User: #{user.id}, Event: #{event.id}, Position: #{position}, Child: #{child_membership_id}")
  end
end
