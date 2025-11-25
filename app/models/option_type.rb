class OptionType < ApplicationRecord
  has_many :option_values, dependent: :destroy
  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
end
