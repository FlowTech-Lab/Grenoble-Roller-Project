class EventMailer < ApplicationMailer
  # Email de confirmation d'inscription à un événement
  def attendance_confirmed(attendance)
    @attendance = attendance
    @event = attendance.event
    @user = attendance.user
    @is_initiation = @event.is_a?(Event::Initiation)

    subject = if @is_initiation
      "✅ Inscription confirmée - Initiation roller samedi #{l(@event.start_at, format: :day_month, locale: :fr)}"
    else
      "✅ Inscription confirmée : #{@event.title}"
    end

    mail(
      to: @user.email,
      subject: subject
    )
  end

  # Email de confirmation de désinscription d'un événement
  def attendance_cancelled(user, event)
    @user = user
    @event = event
    @is_initiation = @event.is_a?(Event::Initiation)

    subject = if @is_initiation
      "❌ Désinscription confirmée - Initiation roller samedi #{l(@event.start_at, format: :day_month, locale: :fr)}"
    else
      "❌ Désinscription confirmée : #{@event.title}"
    end

    mail(
      to: @user.email,
      subject: subject
    )
  end

  # Email de rappel 24h avant l'événement (optionnel, pour plus tard)
  def event_reminder(attendance)
    @attendance = attendance
    @event = attendance.event
    @user = attendance.user
    @is_initiation = @event.is_a?(Event::Initiation)

    subject = if @is_initiation
      "📅 Rappel : Initiation roller demain samedi #{l(@event.start_at, format: :day_month, locale: :fr)}"
    else
      "📅 Rappel : #{@event.title} demain !"
    end

    mail(
      to: @user.email,
      subject: subject
    )
  end

  # Email de notification de refus d'un événement au créateur
  def event_rejected(event)
    @event = event
    @creator = event.creator_user
    @is_initiation = @event.is_a?(Event::Initiation)

    subject = if @is_initiation
      "❌ Votre initiation a été refusée"
    else
      "❌ Votre événement \"#{@event.title}\" a été refusé"
    end

    mail(
      to: @creator.email,
      subject: subject
    )
  end

  # Email de notification qu'une place est disponible en liste d'attente
  def waitlist_spot_available(waitlist_entry)
    @waitlist_entry = waitlist_entry
    @event = waitlist_entry.event
    @user = waitlist_entry.user
    @is_initiation = @event.is_a?(Event::Initiation)
    @participant_name = waitlist_entry.participant_name

    subject = if @is_initiation
      "🎉 Place disponible - Initiation roller samedi #{l(@event.start_at, format: :day_month, locale: :fr)}"
    else
      "🎉 Place disponible : #{@event.title}"
    end

    mail(
      to: @user.email,
      subject: subject
    )
  end
end
