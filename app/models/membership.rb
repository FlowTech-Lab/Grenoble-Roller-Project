class Membership < ApplicationRecord
  include Hashid::Rails

  belongs_to :user
  belongs_to :payment, optional: true
  belongs_to :tshirt_variant, class_name: "ProductVariant", optional: true

  # Certificat médical (si requis par le questionnaire de santé)
  has_one_attached :medical_certificate

  enum :status, {
    pending: 0,
    active: 1,
    expired: 2,
    trial: 3  # Essai gratuit (uniquement pour enfants)
  }

  enum :category, {
    standard: 0,    # 10€ - Cotisation Adhérent Grenoble Roller
    with_ffrs: 1    # 56.55€ - Cotisation + Licence FFRS
  }

  enum :health_questionnaire_status, {
    ok: "ok",
    medical_required: "medical_required"
  }

  # Validation : un utilisateur ne peut avoir qu'une adhésion personnelle par saison
  # Mais peut avoir plusieurs adhésions enfants
  validate :unique_personal_membership_per_season
  # Pour les essais gratuits (trial), on n'exige pas les dates et montants
  validates :start_date, :end_date, :amount_cents, :category, presence: true, unless: -> { status == 'trial' }
  validates :start_date, comparison: { less_than: :end_date }, if: -> { start_date.present? && end_date.present? }

  # Validations pour adhésions enfants
  validates :child_first_name, :child_last_name, :child_date_of_birth, presence: true, if: :is_child_membership?
  validates :parent_authorization, inclusion: { in: [ true ] }, if: -> { is_child_membership? && child_age < 16 }
  
  # Validation : trial uniquement pour les enfants
  validate :trial_only_for_children

  # Scopes
  scope :active_now, -> { active.where("end_date > ?", Date.current) }
  scope :expiring_soon, -> { active.where("end_date BETWEEN ? AND ?", Date.current, 30.days.from_now) }
  scope :pending_payment, -> { pending }
  scope :personal, -> { where(is_child_membership: false) }
  scope :children, -> { where(is_child_membership: true) }

  # Ransack pour ActiveAdmin
  def self.ransackable_attributes(_auth_object = nil)
    %w[id user_id payment_id tshirt_variant_id category status season start_date end_date
       amount_cents currency is_child_membership is_minor child_first_name child_last_name
       child_date_of_birth parent_authorization parent_authorization_date parent_name
       parent_email parent_phone rgpd_consent legal_notices_accepted ffrs_data_sharing_consent
       health_questionnaire_status health_q1 health_q2 health_q3 health_q4 health_q5
       health_q6 health_q7 health_q8 health_q9 created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[medical_certificate_attachment medical_certificate_blob payment tshirt_variant user]
  end

  # Calcul automatique du prix selon la catégorie
  def self.price_for_category(category)
    case category.to_s
    when "standard" then 1000      # 10€ en centimes
    when "with_ffrs" then 5655      # 56.55€ en centimes
    else 0
    end
  end

  # Calculer le prix total (adhésion + T-shirt si présent)
  def total_amount_cents
    base = amount_cents || 0

    # Nouveau système simplifié : with_tshirt + tshirt_qty
    if with_tshirt && tshirt_qty.to_i > 0
      tshirt_total = tshirt_qty.to_i * 1400 # 14€ par T-shirt
      return base + tshirt_total
    end

    # Ancien système (rétrocompatibilité) : tshirt_variant_id
    if tshirt_variant_id.present?
      tshirt = tshirt_price_cents || 1400
      return base + tshirt
    end

    base
  end

  # Vérifie si le questionnaire de santé est complètement rempli (toutes les 9 questions)
  def health_questionnaire_complete?
    (1..9).all? { |i| send("health_q#{i}").present? }
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

    [ start_date, end_date ]
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
    status == "active" && end_date >= Date.current
  end

  # Vérifier si l'adhésion est expirée
  def expired?
    end_date < Date.current
  end

  # Méthode publique pour vérifier si c'est une adhésion enfant
  def is_child_membership?
    is_child_membership == true
  end

  # Nom complet de l'enfant
  def child_full_name
    return nil unless is_child_membership?
    "#{child_first_name} #{child_last_name}".strip
  end

  # Calculer l'âge de l'enfant
  def child_age
    return 0 unless child_date_of_birth.present?
    ((Date.today - child_date_of_birth) / 365.25).floor
  end

  private

  def trial_only_for_children
    if status == 'trial' && !is_child_membership?
      errors.add(:status, "Le statut 'trial' est uniquement disponible pour les adhésions enfants")
    end
  end

  def unique_personal_membership_per_season
    return if is_child_membership? # Pas de validation pour les enfants
    return if status == 'trial' # Les essais gratuits ne sont pas concernés par cette validation

    existing = Membership.where(
      user_id: user_id,
      season: season,
      is_child_membership: false
    ).where.not(id: id)

    # Empêcher plusieurs adhésions pending pour la même saison
    if status == "pending" && existing.where(status: "pending").exists?
      errors.add(:base, "Vous avez déjà une adhésion en attente de paiement pour cette saison")
      return
    end

    # Empêcher une nouvelle adhésion si une adhésion active existe déjà
    if existing.where(status: "active").where("end_date > ?", Date.current).exists?
      errors.add(:base, "Vous avez déjà une adhésion active pour cette saison")
      nil
    end
  end

  def activate_if_paid
    # Si le statut vient de passer à 'active', envoyer l'email
    if status == "active" && saved_change_to_status? && saved_change_to_status[0] == "pending"
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
    if is_child_membership?
      return false unless child_date_of_birth.present?
      child_age < 18
    else
      return false unless user.date_of_birth.present?
      age = ((Date.today - user.date_of_birth) / 365.25).floor
      age < 18
    end
  end

  # Vérifier si l'adhésion nécessite une autorisation parentale
  def requires_parent_authorization?
    if is_child_membership?
      return false unless child_date_of_birth.present?
      child_age < 16
    else
      return false unless user.date_of_birth.present?
      age = ((Date.today - user.date_of_birth) / 365.25).floor
      age < 16
    end
  end
end
