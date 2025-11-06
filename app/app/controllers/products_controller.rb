class ProductsController < ApplicationController
  def index
    @categories = ProductCategory.order(:name)
    @products = Product.includes(:category).where(is_active: true).order(:name)
  end

  def show
    @product = Product.includes(:product_variants).find_by!(slug: params[:id]) rescue Product.find(params[:id])
    @variants = @product.product_variants.where(is_active: true).order(:sku)
  end
end


