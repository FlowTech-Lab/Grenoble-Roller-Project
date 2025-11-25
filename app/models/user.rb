class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable, :confirmable
  # Relation avec Role
  belongs_to :role
  has_many :orders, dependent: :nullify

  # Phase 2 - Events associations
  has_many :created_events, class_name: "Event", foreign_key: "creator_user_id", dependent: :restrict_with_error
  has_many :attendances, dependent: :destroy
  has_many :events, through: :attendances

  # Phase 2 - Organizer applications
  has_many :organizer_applications, dependent: :destroy
  has_many :reviewed_applications, class_name: "OrganizerApplication", foreign_key: "reviewed_by_id", dependent: :nullify

  # Phase 2 - Audit logs
  has_many :audit_logs, class_name: "AuditLog", foreign_key: "actor_user_id", dependent: :nullify

  before_validation :set_default_role, on: :create
  after_create :send_welcome_email_and_confirmation

  # Permettre l'accès immédiat même sans confirmation (période de grâce)
  def active_for_authentication?
    super || !confirmed?
  end

  # Skill levels disponibles
  SKILL_LEVELS = %w[beginner intermediate advanced].freeze

  # Validations: skill_level obligatoire à l'inscription
  validates :skill_level, presence: true, inclusion: { in: SKILL_LEVELS }

  # Validations: prénom obligatoire (important pour personnaliser les événements)
  validates :first_name, presence: true, length: { maximum: 50 }
  validates :phone, format: { with: /\A[0-9\s\-\+\(\)]+\z/, message: "format invalide" }, allow_blank: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[id email first_name last_name phone email_verified role_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[orders created_events attendances events organizer_applications reviewed_applications audit_logs role]
  end

  private

  def set_default_role
    # Priorité au code stable, fallback sur un libellé courant
    self.role ||= Role.find_by(code: "USER") || Role.find_by(name: "Utilisateur") || Role.first
  end

  def send_welcome_email_and_confirmation
    # Envoyer email de bienvenue ET email de confirmation
    UserMailer.welcome_email(self).deliver_later
    send_confirmation_instructions
  end
end
