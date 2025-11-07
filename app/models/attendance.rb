class Attendance < ApplicationRecord
  belongs_to :user
  belongs_to :event
  belongs_to :payment, optional: true

  enum :status, {
    registered: 'registered',
    paid: 'paid',
    canceled: 'canceled',
    present: 'present',
    no_show: 'no_show'
  }, validate: true

  validates :status, presence: true
  validates :user_id, uniqueness: { scope: :event_id, message: 'a déjà une inscription pour cet événement' }

  scope :active, -> { where.not(status: 'canceled') }
  scope :canceled, -> { where(status: 'canceled') }
end

