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

    describe 'counter cache' do
      it 'increments event.attendances_count when attendance is created' do
        expect(event.attendances_count).to eq(0)
        
        create_attendance(user: user, event: event)
        event.reload
        
        expect(event.attendances_count).to eq(1)
      end

      it 'decrements event.attendances_count when attendance is destroyed' do
        attendance = create_attendance(user: user, event: event)
        event.reload
        expect(event.attendances_count).to eq(1)
        
        attendance.destroy
        event.reload
        
        expect(event.attendances_count).to eq(0)
      end

      it 'does not increment counter when attendance creation fails' do
        invalid_attendance = build_attendance(user: user, event: event, status: nil)
        initial_count = event.attendances_count
        
        expect { invalid_attendance.save }.not_to change { event.reload.attendances_count }
      end
    end

    describe 'max_participants validation' do
      let(:limited_event) { create_event(creator_user: create_user, max_participants: 2) }

      it 'allows attendance when event has available spots' do
        attendance = build_attendance(user: user, event: limited_event)
        expect(attendance).to be_valid
      end

      it 'allows attendance when event is unlimited (max_participants = 0)' do
        unlimited_event = create_event(creator_user: create_user, max_participants: 0)
        attendance = build_attendance(user: user, event: unlimited_event)
        expect(attendance).to be_valid
      end

      it 'prevents attendance when event is full' do
        # Fill the event to capacity
        create_attendance(event: limited_event, user: create_user, status: 'registered')
        create_attendance(event: limited_event, user: create_user, status: 'registered')
        limited_event.reload
        
        # Try to create another attendance
        attendance = build_attendance(user: user, event: limited_event)
        expect(attendance).to be_invalid
        expect(attendance.errors[:event]).to include(match(/complet/))
      end

      it 'does not count canceled attendances when checking capacity' do
        # Fill with one active and one canceled
        create_attendance(event: limited_event, user: create_user, status: 'registered')
        create_attendance(event: limited_event, user: create_user, status: 'canceled')
        limited_event.reload
        
        # Should still allow new attendance (only 1 active)
        attendance = build_attendance(user: user, event: limited_event)
        expect(attendance).to be_valid
      end
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

