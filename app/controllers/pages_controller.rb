class PagesController < ApplicationController
  def index
    # Récupérer le prochain événement publié à venir pour l'affichage sur la homepage
    # Exclure les initiations (qui ont leur propre section)
    # Note: on utilise attendances_count (counter cache) donc pas besoin de includes(:attendances)
    @highlighted_event = Event.not_initiations.published.upcoming
                              .includes(:route, :creator_user)
                              .order(:start_at)
                              .first

    # Statistiques synthétiques pour la homepage (exclure les initiations)
    @users_count = User.count
    @events_count = Event.not_initiations.published.count
    @upcoming_events_count = Event.not_initiations.published.upcoming.count
    @attendances_count = Attendance.count
  end

  def association; end

  def about
    # Statistiques pour la page "À propos" (exclure les initiations)
    @users_count = User.count
    @events_count = Event.not_initiations.published.count
    @upcoming_events_count = Event.not_initiations.published.upcoming.count
    @attendances_count = Attendance.count

    # Partenaires commerciaux actifs
    @commercial_partners = Partner.active.order(:name)
  end
end
