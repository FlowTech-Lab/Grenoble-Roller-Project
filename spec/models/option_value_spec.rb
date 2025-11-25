require 'rails_helper'

RSpec.describe OptionValue, type: :model do
  let!(:ot) { OptionType.create!(name: 'Taille2', presentation: 'Taille') }

  it 'is valid with value and option_type' do
    ov = OptionValue.new(option_type: ot, value: 'L', presentation: 'L')
    expect(ov).to be_valid
  end

  it 'requires value' do
    ov = OptionValue.new(option_type: ot)
    expect(ov).to be_invalid
    expect(ov.errors[:value]).to be_present
  end

  it 'destroys join rows when option_value is destroyed' do
    category = ProductCategory.create!(name: 'Cat-ov', slug: 'cat-ov')
    product = Product.create!(category: category, name: 'Prod-ov', slug: 'prod-ov', price_cents: 1000, currency: 'EUR', stock_qty: 10, is_active: true, image_url: 'https://example.org/img.jpg')
    variant = ProductVariant.create!(product: product, sku: 'SKU-OV', price_cents: 1000, currency: 'EUR', stock_qty: 5, is_active: true)
    ov = OptionValue.create!(option_type: ot, value: 'XL', presentation: 'XL')
    VariantOptionValue.create!(variant: variant, option_value: ov)
    expect {
      ov.destroy
    }.to change { VariantOptionValue.count }.by(-1)
  end
end
