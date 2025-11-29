class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :payment, optional: true

  enum status: {
    pending: 0,
    active: 1,
    expired: 2
  }

  enum category: {
    adult: 0,
    student: 1,
    family: 2
  }

  validates :user_id, uniqueness: { scope: :season, message: "ne peut avoir qu'une adhésion par saison" }
  validates :start_date, :end_date, :amount_cents, :category, presence: true
  validates :start_date, comparison: { less_than: :end_date }

  # Scopes
  scope :active_now, -> { active.where("end_date > ?", Date.current) }
  scope :expiring_soon, -> { active.where("end_date BETWEEN ? AND ?", Date.current, 30.days.from_now) }
  scope :pending_payment, -> { pending }

  # Calcul automatique du prix selon la catégorie
  def self.price_for_category(category)
    case category.to_s
    when 'adult' then 5000      # 50€ en centimes
    when 'student' then 2500    # 25€ en centimes
    when 'family' then 8000     # 80€ en centimes
    else 0
    end
  end

  # Calcul automatique des dates de saison (1er sept - 31 août)
  def self.current_season_dates
    today = Date.today
    year = today.year

    # Si on est après le 1er septembre, la saison courante a déjà commencé
    if today >= Date.new(year, 9, 1)
      start_date = Date.new(year, 9, 1)
      end_date = Date.new(year + 1, 8, 31)
    else
      # Sinon, on est dans la saison précédente (qui se termine le 31 août)
      start_date = Date.new(year - 1, 9, 1)
      end_date = Date.new(year, 8, 31)
    end

    [start_date, end_date]
  end

  # Génère le nom de la saison (ex: "2025-2026")
  def self.current_season_name
    start_date, end_date = current_season_dates
    "#{start_date.year}-#{end_date.year}"
  end

  # Callback pour mettre à jour le statut après paiement et envoyer les emails
  after_update :activate_if_paid, if: :saved_change_to_status?

  # Vérifier si l'adhésion est active (payée ET dans la période de validité)
  def active?
    status == 'active' && end_date >= Date.current
  end

  # Vérifier si l'adhésion est expirée
  def expired?
    end_date < Date.current
  end

  private

  def activate_if_paid
    # Si le statut vient de passer à 'active', envoyer l'email
    if status == 'active' && saved_change_to_status? && saved_change_to_status[0] == 'pending'
      MembershipMailer.activated(self).deliver_later
    end
  end

  # Calculer les jours restants avant expiration
  def days_until_expiry
    return 0 if expired?
    (end_date - Date.current).to_i
  end

  # Vérifier si l'adhésion est pour un mineur
  def is_minor?
    return false unless user.date_of_birth.present?
    age = ((Date.today - user.date_of_birth) / 365.25).floor
    age < 18
  end

  # Vérifier si l'adhésion nécessite une autorisation parentale
  def requires_parent_authorization?
    return false unless user.date_of_birth.present?
    age = ((Date.today - user.date_of_birth) / 365.25).floor
    age < 16
  end
end

