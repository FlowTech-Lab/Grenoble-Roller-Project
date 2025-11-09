class EventsController < ApplicationController
  before_action :set_event, only: %i[show edit update destroy]
  before_action :authenticate_user!, except: %i[index show]
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

  private

  def set_event
    @event = Event.includes(:route, :creator_user).find(params[:id])
  end

  def load_supporting_data
    @routes = Route.order(:name)
  end
end

