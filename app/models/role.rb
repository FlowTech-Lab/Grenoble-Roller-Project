class Role < ApplicationRecord
  has_many :users
  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true
  validates :level, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
