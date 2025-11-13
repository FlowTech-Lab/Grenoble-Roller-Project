require 'rails_helper'

RSpec.describe Payment, type: :model do
  let!(:role) { ensure_role(code: 'USER_PAYMENT', name: 'Utilisateur Payment', level: 40) }
  let!(:user) { create_user(role: role, email: 'pay@example.com', first_name: 'Pay') }

  it 'nullifies payment_id on associated orders when destroyed' do
    payment = Payment.create!(provider: 'test', provider_payment_id: 'abc123', amount_cents: 1000, currency: 'EUR', status: 'succeeded')
    order1 = Order.create!(user: user, payment: payment, status: 'pending', total_cents: 1000, currency: 'EUR')
    order2 = Order.create!(user: user, payment: payment, status: 'pending', total_cents: 2000, currency: 'EUR')
    payment.destroy
    expect(order1.reload.payment_id).to be_nil
    expect(order2.reload.payment_id).to be_nil
  end
end

