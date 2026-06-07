# frozen_string_literal: true

class EventOrganizer < ApplicationRecord
  has_many :events, foreign_key: :organizer_id, dependent: :nullify, inverse_of: :organizer

  validates :name, presence: true, length: { maximum: 140 }
  validates :url, format: { with: /\Ahttps?:\/\/.+\z/i }, allow_blank: true
  validates :is_active, inclusion: { in: [ true, false ] }

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name url is_active created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
