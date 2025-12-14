# frozen_string_literal: true

module WaitlistTestHelper
  # Créer une waitlist entry notifiée avec son attendance pending associée
  # Retourne [pending_attendance, waitlist_entry]
  # Pattern qui fonctionne : créer dans before block avec event.attendances.build + save(validate: false)
  def create_notified_waitlist_with_pending_attendance(user, event)
    # Créer l'attendance pending directement via l'association pour éviter le cache
    pending_attendance = event.attendances.build(
      user: user,
      child_membership_id: nil,
      status: "pending",
      wants_reminder: false,
      needs_equipment: false,
      roller_size: nil,
      free_trial_used: false
    )
    pending_attendance.save(validate: false)
    
    # Créer la waitlist entry
    waitlist_entry = build(:waitlist_entry, user: user, event: event, status: 'pending', child_membership_id: nil, wants_reminder: false)
    waitlist_entry.save(validate: false)
    waitlist_entry.update!(status: 'notified', notified_at: 1.hour.ago)
    
    [pending_attendance, waitlist_entry]
  end
end

RSpec.configure do |config|
  config.include WaitlistTestHelper, type: :request
end


