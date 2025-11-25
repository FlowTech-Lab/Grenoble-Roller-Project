require 'rails_helper'

RSpec.describe VariantOptionValue, type: :model do
  let!(:category) { ProductCategory.create!(name: 'Cat-vov', slug: 'cat-vov') }
  let!(:product) { Product.create!(category: category, name: 'Prod-vov', slug: 'prod-vov', price_cents: 1000, currency: 'EUR', stock_qty: 10, is_active: true, image_url: 'https://example.org/img.jpg') }
  let!(:variant) { ProductVariant.create!(product: product, sku: 'SKU-VOV', price_cents: 1000, currency: 'EUR', stock_qty: 5, is_active: true) }
  let!(:ot) { OptionType.create!(name: 'Couleur-vov', presentation: 'Couleur') }
  let!(:ov) { OptionValue.create!(option_type: ot, value: 'Rouge', presentation: 'Rouge') }

  it 'is valid with unique [variant, option_value] pair' do
    vov = VariantOptionValue.new(variant: variant, option_value: ov)
    expect(vov).to be_valid
  end

  it 'enforces uniqueness of variant scoped to option_value' do
    VariantOptionValue.create!(variant: variant, option_value: ov)
    dup = VariantOptionValue.new(variant: variant, option_value: ov)
    expect(dup).to be_invalid
    expect(dup.errors[:variant_id]).to be_present
  end
end
