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
    scope: [:event_id, :child_membership_id], 
    message: "est déjà en liste d'attente pour cet événement",
    conditions: -> { where.not(status: "cancelled") }
  }
  validate :event_is_full, on: :create
  validate :user_not_already_registered, on: :create
  validate :child_membership_belongs_to_user

  # Scopes
  scope :active, -> { where(status: ["pending", "notified"]) }
  scope :for_event, ->(event) { where(event: event) }
  scope :ordered_by_position, -> { order(:position, :created_at) }
  scope :pending_notification, -> { where(status: "pending", notified_at: nil) }

  # Callbacks
  before_create :set_position
  after_create :log_waitlist_addition

  # Méthodes métier
  def participant_name
    if child_membership_id.present?
      "#{child_membership.child_first_name} #{child_membership.child_last_name}"
    else
      user.full_name.presence || user.email
    end
  end

  def for_child?
    child_membership_id.present?
  end

  def notify!
    return false unless pending?
    
    update!(
      status: "notified",
      notified_at: Time.current
    )
    
    EventMailer.waitlist_spot_available(self).deliver_later
    Rails.logger.info("WaitlistEntry #{id} notified for event #{event.id}")
    true
  end

  def convert_to_attendance!
    return false unless notified? || pending?
    
    # Créer l'inscription
    attendance = event.attendances.build(
      user: user,
      child_membership_id: child_membership_id,
      status: "registered",
      wants_reminder: true
    )
    
    if attendance.save
      update!(status: "converted")
      # Notifier les autres personnes en liste d'attente
      WaitlistEntry.notify_next_in_queue(event)
      Rails.logger.info("WaitlistEntry #{id} converted to attendance #{attendance.id}")
      true
    else
      Rails.logger.error("Failed to convert WaitlistEntry #{id}: #{attendance.errors.full_messages.join(', ')}")
      false
    end
  end

  def cancel!
    update!(status: "cancelled")
    # Réorganiser les positions des autres entrées
    WaitlistEntry.reorganize_positions(event)
  end

  # Méthodes de classe
  def self.add_to_waitlist(user, event, child_membership_id: nil)
    return nil if event.has_available_spots?
    
    # Vérifier si déjà en liste d'attente
    existing = find_by(
      user: user,
      event: event,
      child_membership_id: child_membership_id,
      status: ["pending", "notified"]
    )
    return existing if existing

    # Créer l'entrée
    create!(
      user: user,
      event: event,
      child_membership_id: child_membership_id
    )
  end

  def self.notify_next_in_queue(event, count: 1)
    # Notifier les N premières personnes en liste d'attente
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

  private

  def set_position
    # Position = nombre d'entrées actives pour cet événement
    max_position = WaitlistEntry.for_event(event).active.maximum(:position) || -1
    self.position = max_position + 1
  end

  def event_is_full
    return if event.nil?
    unless event.full?
      errors.add(:event, "L'événement n'est pas complet, vous pouvez vous inscrire directement")
    end
  end

  def user_not_already_registered
    return if user.nil? || event.nil?
    
    existing_attendance = user.attendances.where(
      event: event,
      child_membership_id: child_membership_id
    ).where.not(status: "canceled").exists?
    
    if existing_attendance
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
