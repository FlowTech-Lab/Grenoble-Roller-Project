class PagesController < ApplicationController
  def index
    # Récupérer le prochain événement publié à venir pour l'affichage sur la homepage
    @highlighted_event = Event.published.upcoming
                              .includes(:route, :creator_user, :attendances)
                              .order(:start_at)
                              .first
  end

  def association; end
end