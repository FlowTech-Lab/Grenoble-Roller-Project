module AdminPanel
  class DashboardController < BaseController
    def index
      # Statistiques simples
      @stats = {
        total_users: User.count,
        total_products: Product.count,
        total_orders: Order.count,
        pending_orders: Order.where(status: 'pending').count
      }
      
      # Commandes récentes (5 dernières)
      @recent_orders = Order.includes(:user).order(created_at: :desc).limit(5)
    end
  end
end
