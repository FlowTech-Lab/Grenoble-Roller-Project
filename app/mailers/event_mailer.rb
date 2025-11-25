class EventMailer < ApplicationMailer
  # Email de confirmation d'inscription à un événement
  def attendance_confirmed(attendance)
    @attendance = attendance
    @event = attendance.event
    @user = attendance.user

    mail(
      to: @user.email,
      subject: "✅ Inscription confirmée : #{@event.title}"
    )
  end

  # Email de confirmation de désinscription d'un événement
  def attendance_cancelled(user, event)
    @user = user
    @event = event

    mail(
      to: @user.email,
      subject: "❌ Désinscription confirmée : #{@event.title}"
    )
  end

  # Email de rappel 24h avant l'événement (optionnel, pour plus tard)
  def event_reminder(attendance)
    @attendance = attendance
    @event = attendance.event
    @user = attendance.user

    mail(
      to: @user.email,
      subject: "📅 Rappel : #{@event.title} demain !"
    )
  end
end
