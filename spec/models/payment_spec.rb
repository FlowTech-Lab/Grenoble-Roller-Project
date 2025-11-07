require 'rails_helper'

RSpec.describe Payment, type: :model do
  let!(:role) { Role.create!(name: 'Utilisateur', code: 'USER', level: 1) }
  let!(:user) { User.create!(email: 'pay@example.com', password: 'password123', first_name: 'Pay', role: role) }

  it 'nullifies payment_id on associated orders when destroyed' do
    payment = Payment.create!(provider: 'test', provider_payment_id: 'abc123', amount_cents: 1000, currency: 'EUR', status: 'succeeded')
    order1 = Order.create!(user: user, payment: payment, status: 'pending', total_cents: 1000, currency: 'EUR')
    order2 = Order.create!(user: user, payment: payment, status: 'pending', total_cents: 2000, currency: 'EUR')
    payment.destroy
    expect(order1.reload.payment_id).to be_nil
    expect(order2.reload.payment_id).to be_nil
  end
end

