class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable
  # Relation avec Role
  belongs_to :role
  before_validation :set_default_role, on: :create
  
  # Validations optionnelles
  validates :first_name, :last_name, presence: true
  validates :phone, format: { with: /\A[0-9\s\-\+\(\)]+\z/, message: "format invalide" }, allow_blank: true
  
  private
  
  def set_default_role
    self.role ||= Role.find_by(name: 'user')
  end
end
