class ProductsController < ApplicationController
  def index
    @categories = ProductCategory.order(:name)
    products = Product.includes(:category, product_variants: { variant_option_values: :option_value })
                      .where(is_active: true)

    # Trier : produits avec stock en premier, puis par nom
    @products = products.to_a.sort_by do |product|
      has_stock = product.product_variants.any? { |v| v.is_active && v.stock_qty.to_i > 0 }
      [has_stock ? 0 : 1, product.name]
    end
  end

  def show
    # Try slug first, then numeric id; raise 404 if not found
    @product = Product.includes(product_variants: { variant_option_values: :option_value }).find_by(slug: params[:id])
    if @product.nil? && params[:id].to_s.match?(/\A\d+\z/)
      @product = Product.includes(product_variants: { variant_option_values: :option_value }).find_by(id: params[:id])
    end
    raise ActiveRecord::RecordNotFound, "Product not found" if @product.nil?
    @variants = @product.product_variants.where(is_active: true).includes(variant_option_values: :option_value).order(:sku)
  end
end


