# Auditable concern provides a simple audit trail via the AuditLog model.
# Models that include this concern should define an `audit_actor` method
# returning the User responsible for the change (or nil if unknown).
#
# Example:
#   class Attendance < ApplicationRecord
#     include Auditable
#
#     def audit_actor
#       user
#     end
#   end
#
# The concern adds after_create, after_update, and after_destroy callbacks
# that create an AuditLog entry with relevant metadata.
module Auditable
  extend ActiveSupport::Concern

  included do
    after_create  :audit_create
    after_update  :audit_update
    after_destroy :audit_destroy
  end

  private

  # Build a hash of attributes to store in the audit log.
  # Subclasses can override to customise what is audited.
  def audit_attributes
    {}
  end

  def audit_create
    AuditLog.create!(
      actor_user: audit_actor,
      action:     'created',
      target_type: self.class.name,
      target_id:   id,
      metadata:    audit_attributes.merge(id: id)
    )
  end

  def audit_update
    # Only log if there are changes to audited attributes.
    # We consider changes in the return of `audit_attributes` (excluding id).
    # To keep it simple, we log on every update; subclasses can override
    # to skip logging when irrelevant.
    AuditLog.create!(
      actor_user: audit_actor,
      action:     'updated',
      target_type: self.class.name,
      target_id:   id,
      metadata:    audit_attributes.merge(
                    id: id,
                    changed: saved_changes
                  )
    )
  end

  def audit_destroy
    AuditLog.create!(
      actor_user: audit_actor,
      action:     'destroyed',
      target_type: self.class.name,
      target_id:   id,
      metadata:    audit_attributes.merge(id: id)
    )
  end
end