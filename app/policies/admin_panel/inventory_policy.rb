# frozen_string_literal: true

module AdminPanel
  class InventoryPolicy < BasePolicy
    def index?
      admin_user?
    end
    
    def transfers?
      admin_user?
    end
    
    def adjust_stock?
      admin_user?
    end
  end
end

