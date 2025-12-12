module EventsHelper
  # Helper pour obtenir les routes de manière polymorphique selon le type d'événement
  def event_path_for(event)
    event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
  end

  def edit_event_path_for(event)
    event.is_a?(Event::Initiation) ? edit_initiation_path(event) : edit_event_path(event)
  end

  def ical_event_path_for(event)
    event.is_a?(Event::Initiation) ? ical_initiation_path(event, format: :ics) : ical_event_path(event, format: :ics)
  end

  def toggle_reminder_event_path_for(event)
    event.is_a?(Event::Initiation) ? toggle_reminder_initiation_path(event) : toggle_reminder_event_path(event)
  end

  def attend_event_path_for(event)
    event.is_a?(Event::Initiation) ? attend_initiation_path(event) : attend_event_path(event)
  end

  def cancel_attendance_event_path_for(event)
    event.is_a?(Event::Initiation) ? cancel_attendance_initiation_path(event) : cancel_attendance_event_path(event)
  end

  def events_index_path_for(event)
    event.is_a?(Event::Initiation) ? initiations_path : events_path
  end

  def events_index_label_for(event)
    event.is_a?(Event::Initiation) ? "Toutes les initiations" : "Tous les événements"
  end
end
