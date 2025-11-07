require 'rails_helper'

RSpec.describe Order, type: :model do
  let!(:role) { Role.create!(name: 'Utilisateur', code: 'USER', level: 1) }
  let!(:user) { User.create!(email: 'user@example.com', password: 'password123', first_name: 'User', role: role) }

  it 'belongs to user and optionally to payment' do
    order = Order.new(user: user, status: 'pending', total_cents: 1000, currency: 'EUR')
    expect(order).to be_valid
    expect(order.payment).to be_nil
  end

  it 'destroys order_items when destroyed' do
    category = ProductCategory.create!(name: 'Cat', slug: 'cat')
    product = Product.create!(category: category, name: 'Prod', slug: 'prod', price_cents: 1000, currency: 'EUR', stock_qty: 10, is_active: true, image_url: 'https://example.org/img.jpg')
    variant = ProductVariant.create!(product: product, sku: 'SKU-Z', price_cents: 1000, currency: 'EUR', stock_qty: 5, is_active: true)
    order = Order.create!(user: user, status: 'pending', total_cents: 1000, currency: 'EUR')
    OrderItem.create!(order: order, variant_id: variant.id, quantity: 1, unit_price_cents: 1000)
    expect {
      order.destroy
    }.to change { OrderItem.count }.by(-1)
  end
end

