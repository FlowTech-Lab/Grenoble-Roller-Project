# frozen_string_literal: true

module AdminPanel
  class ProductVariantsController < BaseController
    include Pagy::Backend
    
    before_action :set_product
    before_action :set_variant, only: %i[edit update destroy toggle_status]
    before_action :authorize_product

    # GET /admin-panel/products/:product_id/product_variants
    def index
      @variants = @product.product_variants
        .includes(:inventory, :option_values)
        .order(sku: :asc)
      
      @pagy, @variants = pagy(@variants, items: 50)
    end

    # GET /admin-panel/products/:product_id/product_variants/bulk_edit
    def bulk_edit
      @variant_ids = params[:variant_ids] || []
      @variants = @product.product_variants.where(id: @variant_ids)
      
      if @variants.empty?
        redirect_to admin_panel_product_product_variants_path(@product),
                    alert: 'Aucune variante sélectionnée'
      end
    end

    # PATCH /admin-panel/products/:product_id/product_variants/bulk_update
    def bulk_update
      variant_ids = params[:variant_ids] || []
      updates = params[:variants] || {}
      
      updated_count = 0
      variant_ids.each do |id|
        variant = @product.product_variants.find_by(id: id)
        next unless variant
        
        if updates[id.to_s].present?
          variant.update(updates[id.to_s].permit(:price_cents, :stock_qty, :is_active))
          updated_count += 1
        end
      end
      
      flash[:notice] = "#{updated_count} variante(s) mise(s) à jour"
      redirect_to admin_panel_product_product_variants_path(@product)
    end

    # PATCH /admin-panel/products/:product_id/product_variants/:id/toggle_status
    def toggle_status
      @variant.update(is_active: !@variant.is_active)
      
      respond_to do |format|
        format.html do
          redirect_back(
            fallback_location: admin_panel_product_product_variants_path(@product),
            notice: "Variante #{@variant.is_active ? 'activée' : 'désactivée'}"
          )
        end
        format.json { render json: { is_active: @variant.is_active } }
      end
    end

    # GET /admin-panel/products/:product_id/product_variants/new
    def new
      @variant = @product.product_variants.build
      @variant.price_cents = @product.price_cents || 0
      @variant.currency = @product.currency || "EUR"
      @variant.stock_qty = 0
      @variant.is_active = true
      
      @option_types = OptionType.includes(:option_values).order(:name)
    end

    # POST /admin-panel/products/:product_id/product_variants
    def create
      @variant = @product.product_variants.build(variant_params)
      @option_types = OptionType.includes(:option_values).order(:name)

      # Associer les OptionValues si fournis
      if params[:option_value_ids].present?
        option_values = OptionValue.where(id: params[:option_value_ids])
        @variant.option_values = option_values
      end

      if @variant.save
        flash[:notice] = "Variante créée avec succès"
        redirect_to admin_panel_product_path(@product)
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin-panel/products/:product_id/product_variants/:id/edit
    def edit
      @option_types = OptionType.includes(:option_values).order(:name)
    end

    # PATCH/PUT /admin-panel/products/:product_id/product_variants/:id
    def update
      @option_types = OptionType.includes(:option_values).order(:name)
      
      # Mettre à jour les OptionValues si fournis
      if params[:option_value_ids].present?
        option_values = OptionValue.where(id: params[:option_value_ids])
        @variant.option_values = option_values
      end

      if @variant.update(variant_params)
        flash[:notice] = "Variante mise à jour avec succès"
        redirect_to admin_panel_product_path(@product)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin-panel/products/:product_id/product_variants/:id
    def destroy
      if @variant.destroy
        flash[:notice] = "Variante supprimée avec succès"
      else
        flash[:alert] = "Erreur lors de la suppression: #{@variant.errors.full_messages.join(', ')}"
      end

      redirect_to admin_panel_product_path(@product)
    end

    private

    def set_product
      @product = Product.find(params[:product_id])
    end

    def set_variant
      @variant = @product.product_variants.find(params[:id])
    end

    def authorize_product
      authorize [:admin_panel, @product], :update?
    end

    def variant_params
      params.require(:product_variant).permit(
        :sku,
        :price_cents,
        :currency,
        :stock_qty,
        :is_active,
        images: []  # Images multiples
      )
    end
  end
end
