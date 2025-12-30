# frozen_string_literal: true

module AdminPanel
  class ProductsController < BaseController
    include Pagy::Backend

    before_action :set_product, only: %i[show edit update destroy publish unpublish]
    before_action :authorize_product, only: %i[show edit update destroy publish unpublish]

    # GET /admin-panel/products
    def index
      authorize [ :admin_panel, Product ]

      # Recherche et filtres
      @q = Product.ransack(params[:q])
      @products = @q.result.with_associations

      # Filtres supplémentaires
      @products = @products.where(is_active: params[:is_active]) if params[:is_active].present?
      @products = @products.where(category_id: params[:category_id]) if params[:category_id].present?

      # Pagination
      @pagy, @products = pagy(@products.order(created_at: :desc), items: params[:per_page] || 25)

      respond_to do |format|
        format.html
        format.csv { send_data ProductExporter.to_csv(@products), filename: csv_filename, type: "text/csv" }
      end
    end

    # GET /admin-panel/products/:id
    def show
      @variants = @product.product_variants.includes(:option_values).order(sku: :asc)
      @variant_pages, @variants = pagy(@variants, items: 10)  # NOUVEAU : pagination
    end

    # GET /admin-panel/products/new
    def new
      @product = Product.new
      @product.price_cents = 0
      @product.currency = "EUR"
      @product.is_active = true
      authorize [ :admin_panel, @product ]

      @categories = ProductCategory.order(:name)
      @option_types = OptionType.includes(:option_values).order(:name)
    end

    # GET /admin-panel/products/:id/edit
    def edit
      @categories = ProductCategory.order(:name)
      @option_types = OptionType.includes(:option_values).order(:name)
    end

    # POST /admin-panel/products
    def create
      @product = Product.new(product_params)
      authorize [ :admin_panel, @product ]

      @categories = ProductCategory.order(:name)
      @option_types = OptionType.includes(:option_values).order(:name)

      if @product.save
        # NOUVEAU : Génération auto si options sélectionnées
        if params[:generate_variants] == "true" && params[:option_ids].present?
          count = ProductVariantGenerator.generate_combinations(@product, params[:option_ids])
          flash[:notice] = "Produit créé avec #{count} variante(s) générée(s)"
        elsif params[:option_type_ids].present?
          # Ancien système de compatibilité
          option_types = OptionType.where(id: params[:option_type_ids])
          generator = ProductVariantGenerator.new(@product, option_types: option_types)
          variants = generator.generate(
            base_price_cents: @product.price_cents,
            base_stock_qty: params[:base_stock_qty].to_i
          )

          if generator.errors.any?
            flash[:alert] = "Produit créé mais erreurs lors de la génération des variantes: #{generator.errors.join(', ')}"
          else
            flash[:notice] = "Produit créé avec #{variants.count} variante(s)"
          end
        else
          flash[:notice] = "Produit créé avec succès"
        end

        redirect_to admin_panel_product_path(@product)
      else
        render :new, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /admin-panel/products/:id
    def update
      if @product.update(product_params)
        # NOUVEAU : Générer options manquantes si ajoutées après création
        if params[:generate_missing] == "true" && params[:option_ids].present?
          count = ProductVariantGenerator.generate_missing_combinations(@product, params[:option_ids])
          flash[:notice] = "Produit mis à jour avec #{count} nouvelle(s) variante(s) générée(s)"
        else
          flash[:notice] = "Produit mis à jour avec succès"
        end
        redirect_to admin_panel_product_path(@product)
      else
        @categories = ProductCategory.order(:name)
        @option_types = OptionType.includes(:option_values).order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin-panel/products/:id
    def destroy
      if @product.destroy
        flash[:notice] = "Produit supprimé avec succès"
      else
        flash[:alert] = "Erreur lors de la suppression: #{@product.errors.full_messages.join(', ')}"
      end

      redirect_to admin_panel_products_path
    end

    # POST /admin-panel/products/:id/publish
    def publish
      if @product.update(is_active: true)
        flash[:notice] = "Produit publié avec succès"
      else
        flash[:alert] = "Erreur : #{@product.errors.full_messages.join(', ')}"
      end

      redirect_to admin_panel_product_path(@product)
    end

    # POST /admin-panel/products/:id/unpublish
    def unpublish
      if @product.update(is_active: false)
        flash[:notice] = "Produit dépublié avec succès"
      else
        flash[:alert] = "Erreur : #{@product.errors.full_messages.join(', ')}"
      end

      redirect_to admin_panel_product_path(@product)
    end

    # GET /admin-panel/products/check_sku
    # Vérifie si un SKU est disponible (pour validation AJAX)
    def check_sku
      sku = params[:sku]&.strip
      variant_id = params[:variant_id]&.to_i

      if sku.blank?
        render json: { available: false, message: "SKU requis" }, status: :bad_request
        return
      end

      # Vérifier si le SKU existe déjà (sauf pour la variante en cours d'édition)
      existing = ProductVariant.find_by(sku: sku)
      available = existing.nil? || (variant_id.present? && existing.id == variant_id)

      render json: {
        available: available,
        message: available ? "SKU disponible" : "SKU déjà utilisé"
      }
    end

    # POST /admin-panel/products/import
    def import
      authorize Product

      unless params[:file].present?
        flash[:alert] = "Aucun fichier fourni"
        redirect_to admin_panel_products_path
        return
      end

      # TODO: Implémenter ProductImporter (PHASE 4)
      flash[:alert] = "Import non implémenté (PHASE 4)"
      redirect_to admin_panel_products_path
    end

    # GET /admin-panel/products/export
    def export
      authorize [ :admin_panel, Product ]

      @q = Product.ransack(params[:q])
      @products = @q.result.with_associations

      respond_to do |format|
        format.csv do
          send_data ProductExporter.to_csv(@products), filename: csv_filename, type: "text/csv"
        end
      end
    end

    # NOUVEAU : Preview variantes avant génération
    def preview_variants
      option_ids = params[:option_ids] || []
      preview = ProductVariantGenerator.preview(nil, option_ids)
      render json: preview
    end

    # NOUVEAU : Édition en masse variantes
    def bulk_update_variants
      # Sécuriser variant_ids : convertir en tableau d'entiers positifs
      input_ids = Array(params[:variant_ids]).filter_map { |id| id.to_i if id.to_i.positive? }

      # Valider que variant_ids contient au moins un ID valide
      if input_ids.empty?
        render json: { success: false, message: "Aucun ID de variante valide fourni" }, status: :bad_request
        return
      end

      # S'assurer que updates est un ActionController::Parameters pour pouvoir utiliser .permit
      updates = params[:updates] || {}

      # Valider que updates n'est pas vide avant conversion
      if updates.empty?
        render json: { success: false, message: "Aucune donnée de mise à jour fournie" }, status: :bad_request
        return
      end

      updates_params = updates.is_a?(ActionController::Parameters) ? updates : ActionController::Parameters.new(updates)

      # Permettre uniquement les champs autorisés
      permitted_updates = updates_params.permit(:price_cents, :stock_qty, :is_active)

      # Vérifier que permitted_updates n'est pas vide après filtrage
      # et qu'il contient au moins une clé avec une valeur non nulle
      if permitted_updates.empty? || permitted_updates.values.all?(&:nil?)
        render json: { success: false, message: "Aucun champ valide à mettre à jour. Champs autorisés: price_cents, stock_qty, is_active" }, status: :bad_request
        return
      end

      # Valider les IDs en récupérant les variantes existantes depuis la BDD
      # Utiliser where(id: input_ids) crée une relation ActiveRecord sécurisée
      # Rails sécurise automatiquement where(id: [1,2,3]) avec des entiers
      existing_variants_relation = ProductVariant.where(id: input_ids)

      # Vérifier qu'au moins une variante existe
      if existing_variants_relation.empty?
        render json: { success: false, message: "Aucune variante valide trouvée pour les IDs fournis" }, status: :bad_request
        return
      end

      # Mise à jour en masse directement sur la relation ActiveRecord existante
      # Cette approche est sécurisée car existing_variants_relation est une relation ActiveRecord
      # qui a déjà été construite avec des entiers validés
      begin
        count = existing_variants_relation.update_all(permitted_updates.to_h)
        render json: { success: true, count: count }
      rescue StandardError => e
        Rails.logger.error("Erreur lors de la mise à jour en masse: #{e.message}")
        render json: { success: false, message: "Erreur lors de la mise à jour: #{e.message}" }, status: :unprocessable_entity
      end
    end

    private

    def set_product
      @product = Product.find(params[:id])
    end

    def authorize_product
      authorize [ :admin_panel, @product ]
    end

    def product_params
      params.require(:product).permit(
        :category_id,
        :name,
        :slug,
        :description,
        :price_cents,
        :currency,
        :stock_qty,
        :is_active,
        :image_url,
        :image
      )
    end

    def csv_filename
      "products_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv"
    end
  end
end
