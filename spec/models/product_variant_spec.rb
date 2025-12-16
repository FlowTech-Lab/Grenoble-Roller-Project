require 'rails_helper'

RSpec.describe ProductVariant, type: :model do
  let!(:category) { ProductCategory.create!(name: 'Accessoires', slug: "accessoires-#{SecureRandom.hex(3)}") }
  let!(:product) { Product.create!(category: category, name: 'T-shirt', slug: "tshirt-#{SecureRandom.hex(3)}", price_cents: 1900, currency: 'EUR', stock_qty: 10, is_active: true, image_url: 'https://example.org/tshirt.jpg') }

  def build_variant(attrs = {})
    defaults = {
      product: product,
      sku: 'SKU-001',
      price_cents: 1900,
      currency: 'EUR',
      stock_qty: 5,
      is_active: true,
      image_url: 'https://example.org/variant.jpg'
    }
    ProductVariant.new(defaults.merge(attrs))
  end

  it 'is valid with valid attributes' do
    expect(build_variant).to be_valid
  end

  it 'requires sku and price_cents (currency defaults to EUR)' do
    v = ProductVariant.new
    expect(v).to be_invalid
    expect(v.errors[:sku]).to be_present
    expect(v.errors[:price_cents]).to be_present
    expect(v.currency).to eq('EUR')
  end

  it 'enforces sku uniqueness' do
    build_variant.save!
    dup = build_variant(sku: 'SKU-001')
    expect(dup).to be_invalid
    expect(dup.errors[:sku]).to be_present
  end

  it 'has many variant_option_values and option_values through join table' do
    v = build_variant
    v.save!
    ot = OptionType.create!(name: 'Taille', presentation: 'Taille')
    ov = OptionValue.create!(option_type: ot, value: 'M', presentation: 'M')
    VariantOptionValue.create!(variant: v, option_value: ov)
    expect(v.variant_option_values.count).to eq(1)
    expect(v.option_values.first.value).to eq('M')
  end

  it 'destroys join rows when variant is destroyed' do
    v = build_variant
    v.save!
    ot = OptionType.create!(name: 'Couleur', presentation: 'Couleur')
    ov = OptionValue.create!(option_type: ot, value: 'Bleu', presentation: 'Bleu')
    VariantOptionValue.create!(variant: v, option_value: ov)
    expect {
      v.destroy
    }.to change { VariantOptionValue.count }.by(-1)
  end
end
