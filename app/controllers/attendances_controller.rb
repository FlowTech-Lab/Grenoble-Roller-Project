class AttendancesController < ApplicationController
  before_action :authenticate_user!

  def index
    @attendances = current_user.attendances
                                .active
                                .includes(event: [:route, :creator_user])
                                .order('events.start_at ASC')
  end
end

