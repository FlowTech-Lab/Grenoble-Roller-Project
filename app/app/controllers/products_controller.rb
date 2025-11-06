class ProductsController < ApplicationController
  def index
    @categories = ProductCategory.order(:name)
    @products = Product.includes(:category).where(is_active: true).order(:name)
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


