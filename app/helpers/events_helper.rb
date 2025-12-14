module EventsHelper
  # Helper pour obtenir les routes de manière polymorphique selon le type d'événement
  def event_path_for(event)
    event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
  end

  def edit_event_path_for(event)
    event.is_a?(Event::Initiation) ? edit_initiation_path(event) : edit_event_path(event)
  end

  def ical_event_path_for(event)
    event.is_a?(Event::Initiation) ? initiation_path(event, format: :ics) : event_path(event, format: :ics)
  end

  def toggle_reminder_event_path_for(event)
    event.is_a?(Event::Initiation) ? toggle_reminder_initiation_attendances_path(event) : toggle_reminder_event_attendances_path(event)
  end

  def attend_event_path_for(event)
    event.is_a?(Event::Initiation) ? initiation_attendances_path(event) : event_attendances_path(event)
  end

  def cancel_attendance_event_path_for(event, attendance = nil)
    # Toujours utiliser la route collection car destroy est une collection
    # Le paramètre child_membership_id sera passé dans les params du formulaire
    event.is_a?(Event::Initiation) ? initiation_attendances_path(event) : event_attendances_path(event)
  end

  def events_index_path_for(event)
    event.is_a?(Event::Initiation) ? initiations_path : events_path
  end

  def events_index_label_for(event)
    event.is_a?(Event::Initiation) ? "Toutes les initiations" : "Tous les événements"
  end

  def join_waitlist_event_path_for(event)
    event.is_a?(Event::Initiation) ? initiation_waitlist_entries_path(event) : event_waitlist_entries_path(event)
  end

  def leave_waitlist_event_path_for(event, waitlist_entry = nil)
    # Toujours utiliser la route collection car destroy est une collection
    # Le paramètre child_membership_id sera passé dans les params du formulaire
    event.is_a?(Event::Initiation) ? initiation_waitlist_entries_path(event) : event_waitlist_entries_path(event)
  end

  def convert_waitlist_to_attendance_event_path_for(event, waitlist_entry)
    # Routes shallow : /waitlist_entries/:id/convert_to_attendance
    convert_to_attendance_waitlist_entry_path(waitlist_entry)
  end

  def refuse_waitlist_event_path_for(event, waitlist_entry)
    # Routes shallow : /waitlist_entries/:id/refuse
    refuse_waitlist_entry_path(waitlist_entry)
  end

  def confirm_waitlist_event_path_for(event, waitlist_entry)
    # Routes shallow : /waitlist_entries/:id/confirm
    confirm_waitlist_entry_path(waitlist_entry)
  end

  def decline_waitlist_event_path_for(event, waitlist_entry)
    # Routes shallow : /waitlist_entries/:id/decline
    decline_waitlist_entry_path(waitlist_entry)
  end
end
