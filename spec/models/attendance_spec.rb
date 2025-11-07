require 'rails_helper'

RSpec.describe Attendance, type: :model do
  let(:user) { create_user }
  let(:event) { create_event(creator_user: create_user) }

  describe 'validations' do
    it 'is valid with default attributes' do
      attendance = build_attendance(user: user, event: event)
      expect(attendance).to be_valid
    end

    it 'requires a status' do
      attendance = build_attendance(user: user, event: event, status: nil)
      expect(attendance).to be_invalid
      expect(attendance.errors[:status]).to be_present
    end

    it 'enforces uniqueness of user scoped to event' do
      create_attendance(user: user, event: event)
      duplicate = build_attendance(user: user, event: event)

      expect(duplicate).to be_invalid
      expect(duplicate.errors[:user_id]).to include('a déjà une inscription pour cet événement')
    end
  end

  describe 'associations' do
    it 'accepts an optional payment' do
      payment = Payment.create!(provider: 'stripe', provider_payment_id: 'pi_123', amount_cents: 1000, currency: 'EUR', status: 'succeeded')
      attendance = build_attendance(user: user, event: event, payment: payment, status: 'paid')

      expect(attendance).to be_valid
      attendance.save!
      expect(attendance.payment).to eq(payment)
    end
  end

  describe 'scopes' do
    it 'returns non-canceled attendances for active scope' do
      active = create_attendance(status: 'registered')
      create_attendance(status: 'canceled')

      expect(Attendance.active).to contain_exactly(active)
    end

    it 'returns canceled attendances for canceled scope' do
      canceled = create_attendance(status: 'canceled')
      create_attendance(status: 'registered')

      expect(Attendance.canceled).to contain_exactly(canceled)
    end
  end
end

