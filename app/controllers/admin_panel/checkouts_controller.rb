# frozen_string_literal: true

module AdminPanel
  class CheckoutsController < BaseController
    before_action :set_checkout, only: %i[show]

    # GET /admin-panel/checkouts
    def index
      authorize [ :admin_panel, Checkout ]

      @q = Checkout.ransack(params[:q])
      @checkouts = @q.result.includes(:user, :payment, :checkout_lines)

      @pagy, @checkouts = pagy(@checkouts.order(created_at: :desc), items: params[:per_page] || 25)
    end

    # GET /admin-panel/checkouts/:id
    def show
      authorize [ :admin_panel, @checkout ]
      @checkout_lines = @checkout.checkout_lines.includes(:reference)
    end

    private

    def set_checkout
      @checkout = Checkout.find(params[:id])
    end
  end
end
