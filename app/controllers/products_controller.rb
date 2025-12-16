class ProductsController < ApplicationController
  def index
    @categories = ProductCategory.order(:name)

    # Filtrer par catégorie si un slug est fourni
    @selected_category = nil
    if params[:category].present?
      @selected_category = ProductCategory.find_by(slug: params[:category])
    end

    products = Product.includes(:category, product_variants: { variant_option_values: :option_value })
                      .where(is_active: true)

    # Appliquer le filtre de catégorie si une catégorie est sélectionnée
    if @selected_category
      products = products.where(category_id: @selected_category.id)
    end

    # Trier : produits avec stock en premier, puis par nom
    @products = products.to_a.sort_by do |product|
      has_stock = product.product_variants.any? { |v| v.is_active && v.stock_qty.to_i > 0 }
      [ has_stock ? 0 : 1, product.name ]
    end

    # Compter les produits par catégorie (pour afficher dans les filtres)
    @category_counts = ProductCategory.left_joins(:products)
                                      .where(products: { is_active: true })
                                      .group("product_categories.id")
                                      .count("products.id")
  end

  def show
    # Try slug first, then numeric id; raise 404 if not found
    @product = Product.includes(product_variants: { variant_option_values: { option_value: :option_type } }).find_by(slug: params[:id])
    if @product.nil? && params[:id].to_s.match?(/\A\d+\z/)
      @product = Product.includes(product_variants: { variant_option_values: { option_value: :option_type } }).find_by(id: params[:id])
    end
    raise ActiveRecord::RecordNotFound, "Product not found" if @product.nil?
    @variants = @product.product_variants.where(is_active: true)
                        .includes(variant_option_values: { option_value: :option_type })
                        .order(:sku)
  end
end
