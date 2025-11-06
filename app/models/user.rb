class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable
  # Relation avec Role
  belongs_to :role
  has_many :orders, dependent: :nullify
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
