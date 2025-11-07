class AuditLog < ApplicationRecord
  belongs_to :actor_user, class_name: 'User'

  validates :action, presence: true, length: { maximum: 80 }
  validates :target_type, presence: true, length: { maximum: 50 }
  validates :target_id, presence: true, numericality: { only_integer: true }

  scope :by_action, ->(action) { where(action: action) }
  scope :by_target, ->(type, id) { where(target_type: type, target_id: id) }
  scope :by_actor, ->(user_id) { where(actor_user_id: user_id) }
  scope :recent, -> { order(created_at: :desc) }
end

