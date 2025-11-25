class ContactMessage < ApplicationRecord
  validates :name, presence: true, length: { maximum: 140 }
  validates :email, presence: true, format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i }
  validates :subject, presence: true, length: { maximum: 140 }
  validates :message, presence: true, length: { minimum: 10 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name email subject message created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
