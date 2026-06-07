# frozen_string_literal: true

module AdminPanel
  class EventOrganizersController < BaseController
    before_action :set_event_organizer, only: %i[show edit update destroy]
    before_action :authorize_event_organizer, only: %i[show edit update destroy]

    # GET /admin-panel/event-organizers
    def index
      authorize [ :admin_panel, EventOrganizer ]

      @q = EventOrganizer.ransack(params[:q])
      @event_organizers = @q.result

      @event_organizers = @event_organizers.active if params[:scope] == "active"
      @event_organizers = @event_organizers.inactive if params[:scope] == "inactive"

      @pagy, @event_organizers = pagy(@event_organizers.order(created_at: :desc), items: params[:per_page] || 25)
    end

    def show
    end

    def new
      @event_organizer = EventOrganizer.new
      authorize [ :admin_panel, @event_organizer ]
    end

    def create
      @event_organizer = EventOrganizer.new(event_organizer_params)
      authorize [ :admin_panel, @event_organizer ]

      if @event_organizer.save
        flash[:notice] = "Entité organisatrice créée avec succès"
        redirect_to admin_panel_event_organizer_path(@event_organizer)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @event_organizer.update(event_organizer_params)
        flash[:notice] = "Entité organisatrice mise à jour avec succès"
        redirect_to admin_panel_event_organizer_path(@event_organizer)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @event_organizer.destroy
        flash[:notice] = "L'entité organisatrice ##{@event_organizer.id} a été supprimée avec succès."
        redirect_to admin_panel_event_organizers_path
      else
        flash[:alert] = "Impossible de supprimer l'entité organisatrice : #{@event_organizer.errors.full_messages.join(', ')}"
        redirect_to admin_panel_event_organizer_path(@event_organizer)
      end
    end

    private

    def set_event_organizer
      @event_organizer = EventOrganizer.find(params[:id])
    end

    def authorize_event_organizer
      authorize [ :admin_panel, @event_organizer ]
    end

    def event_organizer_params
      params.require(:event_organizer).permit(:name, :url, :is_active)
    end
  end
end
