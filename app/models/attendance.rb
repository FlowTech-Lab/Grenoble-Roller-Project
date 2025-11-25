class Attendance < ApplicationRecord
  belongs_to :user
  belongs_to :event, counter_cache: true
  belongs_to :payment, optional: true

  enum :status, {
    registered: "registered",
    paid: "paid",
    canceled: "canceled",
    present: "present",
    no_show: "no_show"
  }, validate: true

  validates :status, presence: true
  validates :user_id, uniqueness: { scope: :event_id, message: "a déjà une inscription pour cet événement" }
  validate :event_has_available_spots, on: :create

  scope :active, -> { where.not(status: "canceled") }
  scope :canceled, -> { where(status: "canceled") }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id user_id event_id status payment_id stripe_customer_id wants_reminder created_at updated_at]
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

    # Compter uniquement les inscriptions actives (non annulées)
    active_attendances_count = event.attendances.active.count

    # Si on crée une nouvelle inscription, vérifier qu'il reste de la place
    # (ne pas compter cette inscription si elle n'est pas encore sauvegardée)
    if new_record?
      if active_attendances_count >= event.max_participants
        errors.add(:event, "L'événement est complet (#{event.max_participants} participants maximum)")
      end
    end
  end
end
