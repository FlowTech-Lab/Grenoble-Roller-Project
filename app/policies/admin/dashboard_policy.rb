module Admin
  class DashboardPolicy < ApplicationPolicy
    alias_method :index?, :admin_user?
    alias_method :show?, :admin_user?
  end
end
