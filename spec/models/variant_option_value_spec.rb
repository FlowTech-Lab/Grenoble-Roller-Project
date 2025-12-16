require 'rails_helper'

RSpec.describe VariantOptionValue, type: :model do
  let!(:category) { create(:product_category, name: 'Cat-vov', slug: 'cat-vov') }
  let!(:product) { create(:product, category: category, name: 'Prod-vov', slug: 'prod-vov') }
  let!(:variant) { create(:product_variant, product: product, sku: 'SKU-VOV') }
  let!(:ot) { create(:option_type, name: 'Couleur-vov', presentation: 'Couleur') }
  let!(:ov) { create(:option_value, option_type: ot, value: 'Rouge', presentation: 'Rouge') }

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
