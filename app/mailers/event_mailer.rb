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
end
