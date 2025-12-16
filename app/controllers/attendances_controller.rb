class AttendancesController < ApplicationController
  before_action :authenticate_user!

  def index
    all_attendances = current_user.attendances
                                   .active
                                   .includes(event: [ :route, :creator_user ])

    # Séparer événements à venir et passés
    @upcoming_attendances = all_attendances.select { |a| a.event.start_at > Time.current }
                                            .sort_by { |a| a.event.start_at }

    @past_attendances = all_attendances.select { |a| a.event.start_at <= Time.current }
                                        .sort_by { |a| a.event.start_at }
                                        .reverse
  end
end
