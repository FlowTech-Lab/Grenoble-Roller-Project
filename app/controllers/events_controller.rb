class EventsController < ApplicationController
  before_action :set_event, only: %i[show edit update destroy attend cancel_attendance ical toggle_reminder]
  before_action :authenticate_user!, except: %i[index show ical]
  before_action :load_supporting_data, only: %i[new create edit update]

  def index
    scoped_events = policy_scope(Event.includes(:route, :creator_user))
    @upcoming_events = scoped_events.upcoming.order(:start_at)
    @past_events = scoped_events.past.order(start_at: :desc).limit(6)
    @highlighted_event = @upcoming_events.first
  end

  def show
    authorize @event
  end

  def new
    @event = current_user.created_events.build(
      status: 'draft',
      start_at: Time.zone.now.change(min: 0),
      duration_min: 60,
      max_participants: 0, # 0 = illimité par défaut
      currency: 'EUR'
    )
    authorize @event
  end

  def create
    @event = current_user.created_events.build
    authorize @event

    if @event.update(permitted_attributes(@event))
      redirect_to @event, notice: 'Événement créé avec succès.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @event
  end

  def update
    authorize @event

    if @event.update(permitted_attributes(@event))
      redirect_to @event, notice: 'Événement mis à jour avec succès.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @event
    @event.destroy

    redirect_to events_path, notice: 'Événement supprimé.'
  end

  def attend
    authenticate_user!
    authorize @event, :attend?

    attendance = @event.attendances.find_or_initialize_by(user: current_user)
    if attendance.persisted?
      redirect_to @event, notice: "Vous êtes déjà inscrit(e) à cet événement."
    else
      attendance.status = 'registered'
      # Accepter wants_reminder depuis les params (formulaire ou paramètre direct)
      attendance.wants_reminder = params[:wants_reminder].present? ? params[:wants_reminder] == '1' : false
      if attendance.save
        EventMailer.attendance_confirmed(attendance).deliver_later
        redirect_to @event, notice: 'Inscription confirmée.'
      else
        redirect_to @event, alert: attendance.errors.full_messages.to_sentence
      end
    end
  end

  def cancel_attendance
    authenticate_user!
    authorize @event, :cancel_attendance?

    attendance = @event.attendances.find_by(user: current_user)
    if attendance&.destroy
      EventMailer.attendance_cancelled(current_user, @event).deliver_later
      redirect_to @event, notice: 'Inscription annulée.'
    else
      redirect_to @event, alert: "Impossible d'annuler votre participation."
    end
  end

  # Active/désactive le rappel 24h avant pour l'utilisateur inscrit
  def toggle_reminder
    authenticate_user!
    authorize @event, :cancel_attendance? # Même permission que cancel_attendance

    attendance = @event.attendances.find_by(user: current_user)
    if attendance
      attendance.update(wants_reminder: !attendance.wants_reminder)
      message = attendance.wants_reminder? ? 'Rappel activé. Vous recevrez un email 24h avant l\'événement.' : 'Rappel désactivé.'
      redirect_to @event, notice: message
    else
      redirect_to @event, alert: 'Vous n\'êtes pas inscrit(e) à cet événement.'
    end
  end

  # Export iCal pour un événement
  def ical
    authorize @event, :show?

    calendar = Icalendar::Calendar.new
    calendar.prodid = '-//Grenoble Roller//Events//FR'

    event_ical = Icalendar::Event.new
    event_ical.dtstart = Icalendar::Values::DateTime.new(@event.start_at)
    event_ical.dtend = Icalendar::Values::DateTime.new(@event.start_at + @event.duration_min.minutes)
    event_ical.summary = @event.title
    event_ical.description = @event.description.presence || "Événement organisé par #{@event.creator_user.first_name}"
    event_ical.location = @event.location_text
    event_ical.url = event_url(@event)
    event_ical.uid = "event-#{@event.id}@grenobleroller.fr"
    event_ical.last_modified = @event.updated_at
    event_ical.created = @event.created_at
    event_ical.organizer = Icalendar::Values::CalAddress.new("mailto:noreply@grenobleroller.fr", cn: 'Grenoble Roller')

    calendar.add_event(event_ical)
    calendar.publish

    send_data calendar.to_ical,
              filename: "#{@event.title.parameterize}.ics",
              type: 'text/calendar; charset=utf-8',
              disposition: 'attachment'
  end

  private

  def set_event
    @event = Event.includes(:route, :creator_user).find(params[:id])
    # Charger l'attendance de l'utilisateur connecté si présent
    @user_attendance = current_user&.attendances&.find_by(event: @event) if user_signed_in?
  end

  def load_supporting_data
    @routes = Route.order(:name)
  end
end

