class Partner < ApplicationRecord
  validates :name, presence: true, length: { maximum: 140 }
  validates :url, format: { with: /\Ahttps?:\/\/.+\z/i }, allow_blank: true
  validates :is_active, inclusion: { in: [true, false] }

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
end

