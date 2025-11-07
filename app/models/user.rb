class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable
  # Relation avec Role
  belongs_to :role
  has_many :orders, dependent: :nullify
  
  # Phase 2 - Events associations
  has_many :created_events, class_name: 'Event', foreign_key: 'creator_user_id', dependent: :restrict_with_error
  has_many :attendances, dependent: :destroy
  has_many :events, through: :attendances
  
  # Phase 2 - Organizer applications
  has_many :organizer_applications, dependent: :destroy
  has_many :reviewed_applications, class_name: 'OrganizerApplication', foreign_key: 'reviewed_by_id', dependent: :nullify
  
  # Phase 2 - Audit logs
  has_many :audit_logs, class_name: 'AuditLog', foreign_key: 'actor_user_id', dependent: :nullify
  
  before_validation :set_default_role, on: :create
  
  # Validations: prénom obligatoire, nom optionnel
  validates :first_name, presence: true
  validates :phone, format: { with: /\A[0-9\s\-\+\(\)]+\z/, message: "format invalide" }, allow_blank: true
  
  private
  
  def set_default_role
    # Priorité au code stable, fallback sur un libellé courant
    self.role ||= Role.find_by(code: 'USER') || Role.find_by(name: 'Utilisateur') || Role.first
  end
end
