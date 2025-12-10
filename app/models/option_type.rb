class OptionType < ApplicationRecord
  has_many :option_values, dependent: :destroy
  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[option_values]
  end
end
