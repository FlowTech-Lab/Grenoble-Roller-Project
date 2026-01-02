require 'rails_helper'

RSpec.describe Order, type: :model do
  let!(:role) { ensure_role(code: 'USER_ORDER', name: 'Utilisateur Order', level: 30) }
  let!(:user) { create_user(role: role, email: 'order@example.com') }

  it 'belongs to user and optionally to payment' do
    order = Order.new(user: user, status: 'pending', total_cents: 1000, currency: 'EUR')
    expect(order).to be_valid
    expect(order.payment).to be_nil
  end

  it 'destroys order_items when destroyed' do
    category = ProductCategory.create!(name: 'Cat', slug: "cat-#{SecureRandom.hex(3)}")
    product = create_product_with_image(category: category, name: 'Prod', slug: "prod-#{SecureRandom.hex(3)}", price_cents: 1000, currency: 'EUR', stock_qty: 10, is_active: true)
    variant = create_variant_with_image(product,
      sku: "SKU-#{SecureRandom.hex(2).upcase}",
      price_cents: 1000,
      currency: 'EUR',
      stock_qty: 5,
      is_active: true
    )
    order = Order.create!(user: user, status: 'pending', total_cents: 1000, currency: 'EUR')
    OrderItem.create!(order: order, variant_id: variant.id, quantity: 1, unit_price_cents: 1000)
    expect {
      order.destroy
    }.to change { OrderItem.count }.by(-1)
  end
end
