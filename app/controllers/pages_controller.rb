class PagesController < ApplicationController
  def index
    # Récupérer le prochain événement publié à venir pour l'affichage sur la homepage
    # Note: on utilise attendances_count (counter cache) donc pas besoin de includes(:attendances)
    @highlighted_event = Event.published.upcoming
                              .includes(:route, :creator_user)
                              .order(:start_at)
                              .first
  end

  def association; end
end