class EventsController < ApplicationController
  before_action :set_event, only: %i[show edit update destroy attend cancel_attendance ical toggle_reminder]
  before_action :authenticate_user!, except: %i[index show]
  before_action :load_supporting_data, only: %i[new create edit update]

  def index
    scoped_events = policy_scope(Event.includes(:route, :creator_user))
    # Seuls les événements publiés sont visibles pour les utilisateurs normaux
    upcoming_events_all = scoped_events.visible.upcoming.order(:start_at)
    @highlighted_event = upcoming_events_all.first
    # Exclure le highlighted_event de la liste "À venir" pour éviter la duplication
    @upcoming_events = @highlighted_event.present? ? upcoming_events_all.where.not(id: @highlighted_event.id) : upcoming_events_all
    @past_events = scoped_events.visible.past.order(start_at: :desc).limit(6)
  end

  def show
    authorize @event
    # Rediriger si l'événement n'est pas visible (publié ou annulé) et que l'utilisateur n'est pas modo+ ou créateur
    unless @event.published? || @event.canceled? || can_moderate? || @event.creator_user_id == current_user&.id
      redirect_to events_path, alert: 'Cet événement n\'est pas encore publié.'
    end
  end
  
  def can_moderate?
    current_user.present? && current_user.role&.level.to_i >= 50 # MODERATOR = 50
  end
  helper_method :can_moderate?

  def new
    @event = current_user.created_events.build(
      status: 'draft', # Toujours en brouillon à la création (en attente de validation)
      start_at: Time.zone.now.change(min: 0),
      duration_min: 60,
      max_participants: 0, # 0 = illimité par défaut
      currency: 'EUR' # Toujours EUR
    )
    authorize @event
  end

  def create
    @event = current_user.created_events.build
    authorize @event
    
    event_params = permitted_attributes(@event)
    # Toujours EUR
    event_params[:currency] = 'EUR'
    # Toujours en draft à la création (en attente de validation par un modérateur)
    event_params[:status] = 'draft'
    # Convertir le prix en euros en centimes
    if params[:price_euros].present?
      event_params[:price_cents] = (params[:price_euros].to_f * 100).round
    end

    if @event.update(event_params)
      redirect_to @event, notice: 'Événement créé avec succès. Il est en attente de validation par un modérateur.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @event
  end

  def update
    authorize @event
    
    event_params = permitted_attributes(@event)
    # Toujours EUR
    event_params[:currency] = 'EUR'
    
    # Seuls les modérateurs+ peuvent changer le statut
    unless current_user.role&.level.to_i >= 50 # MODERATOR = 50
      event_params.delete(:status) # Retirer le statut des params si l'utilisateur n'est pas modo+
    end
    
    # Convertir le prix en euros en centimes
    if params[:price_euros].present?
      event_params[:price_cents] = (params[:price_euros].to_f * 100).round
    end

    if @event.update(event_params)
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

  # Active/désactive le rappel la veille à 19h pour l'utilisateur inscrit
  def toggle_reminder
    authenticate_user!
    authorize @event, :cancel_attendance? # Même permission que cancel_attendance

    attendance = @event.attendances.find_by(user: current_user)
    if attendance
      attendance.update(wants_reminder: !attendance.wants_reminder)
      message = attendance.wants_reminder? ? 'Rappel activé. Vous recevrez un email la veille à 19h pour vous rappeler l\'événement.' : 'Rappel désactivé.'
      redirect_to @event, notice: message
    else
      redirect_to @event, alert: 'Vous n\'êtes pas inscrit(e) à cet événement.'
    end
  end

  # Export iCal pour un événement (réservé aux utilisateurs connectés)
  def ical
    authenticate_user!
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

