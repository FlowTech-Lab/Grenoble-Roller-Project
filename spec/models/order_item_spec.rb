require 'rails_helper'

RSpec.describe OrderItem, type: :model do
  let!(:role) { Role.create!(name: 'Utilisateur', code: 'USER', level: 1) }
  let!(:user) { User.create!(email: 'user2@example.com', password: 'password123', first_name: 'User', role: role) }
  let!(:order) { Order.create!(user: user, status: 'pending', total_cents: 1000, currency: 'EUR') }
  let!(:category) { ProductCategory.create!(name: 'Cat', slug: 'cat-2') }
  let!(:product) { Product.create!(category: category, name: 'Prod', slug: 'prod-2', price_cents: 1000, currency: 'EUR', stock_qty: 10, is_active: true, image_url: 'https://example.org/img.jpg') }
  let!(:variant) { ProductVariant.create!(product: product, sku: 'SKU-YY', price_cents: 1000, currency: 'EUR', stock_qty: 5, is_active: true) }

  it 'belongs to order and variant' do
    item = OrderItem.new(order: order, variant_id: variant.id, quantity: 2, unit_price_cents: 1000)
    expect(item).to be_valid
    item.save!
    expect(item.order).to eq(order)
    expect(item.variant_id).to eq(variant.id)
  end
end

