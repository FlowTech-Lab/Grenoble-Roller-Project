class OrganizerApplication < ApplicationRecord
  include Hashid::Rails

  belongs_to :user
  belongs_to :reviewed_by, class_name: "User", optional: true

  enum :status, { pending: "pending", approved: "approved", rejected: "rejected" }, validate: true

  validates :status, presence: true
  validates :motivation, presence: true, if: -> { status == "pending" }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id user_id reviewed_by_id status motivation reviewed_at created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user reviewed_by]
  end
end
