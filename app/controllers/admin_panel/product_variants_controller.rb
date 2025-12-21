# frozen_string_literal: true

module AdminPanel
  class ProductVariantsController < BaseController
    before_action :set_product
    before_action :set_variant, only: %i[edit update destroy]
    before_action :authorize_product

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
        :image_url,
        :image
      )
    end
  end
end
