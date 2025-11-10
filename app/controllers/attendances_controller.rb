class AttendancesController < ApplicationController
  before_action :authenticate_user!

  def index
    @attendances = current_user.attendances
                                .active
                                .includes(event: :route)
                                .order('events.start_at ASC')
  end
end

