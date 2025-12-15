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

    describe '.volunteers' do
      it 'returns only volunteer attendances' do
        volunteer = create_attendance(is_volunteer: true)
        participant = create_attendance(is_volunteer: false)

        expect(Attendance.volunteers).to contain_exactly(volunteer)
        expect(Attendance.volunteers).not_to include(participant)
      end
    end

    describe '.participants' do
      it 'returns only non-volunteer attendances' do
        volunteer = create_attendance(is_volunteer: true)
        participant = create_attendance(is_volunteer: false)

        expect(Attendance.participants).to contain_exactly(participant)
        expect(Attendance.participants).not_to include(volunteer)
      end
    end
  end

  describe 'initiation-specific validations' do
    let(:initiation) { create(:event_initiation, max_participants: 1) }
    let(:user) { create_user }

    describe 'when initiation is full' do
      before do
        create_attendance(event: initiation, is_volunteer: false, status: 'registered')
      end

      it 'prevents non-volunteer registration' do
        attendance = build_attendance(event: initiation, is_volunteer: false, status: 'registered')
        expect(attendance).to be_invalid
        expect(attendance.errors[:event]).to include(match(/complet/))
      end

      it 'allows volunteer registration even if full' do
        attendance = build_attendance(event: initiation, is_volunteer: true, status: 'registered')
        expect(attendance).to be_valid # Bénévoles bypass
      end
    end

    describe 'free_trial_used validation' do
      it 'prevents using free trial twice' do
        user = create_user
        create_attendance(user: user, free_trial_used: true, event: create(:event_initiation))

        attendance = build_attendance(user: user, free_trial_used: true, event: create(:event_initiation))
        expect(attendance).to be_invalid
        expect(attendance.errors[:free_trial_used]).to include("Vous avez déjà utilisé votre essai gratuit")
      end

      it 'allows free trial if never used' do
        user = create_user
        attendance = build_attendance(user: user, free_trial_used: true, event: create(:event_initiation))
        expect(attendance).to be_valid
      end
    end

    describe 'can_register_to_initiation' do
      let(:initiation) { create(:event_initiation, max_participants: 30) }
      let(:user) { create_user }

      context 'when user has active membership' do
        before do
          create(:membership, user: user, status: :active, season: '2025-2026')
        end

        it 'allows registration without free trial' do
          attendance = build_attendance(user: user, event: initiation, free_trial_used: false)
          expect(attendance).to be_valid
        end
      end

      context 'when user has child membership' do
        before do
          create(:membership, user: user, status: :active, season: '2025-2026', is_child_membership: true)
        end

        it 'allows registration with child membership' do
          attendance = build_attendance(user: user, event: initiation, free_trial_used: false)
          expect(attendance).to be_valid
        end
      end

      context 'when user has no membership and no free trial' do
        it 'prevents registration' do
          # S'assurer que l'utilisateur n'a pas d'adhésion active
          user.memberships.destroy_all
          attendance = build_attendance(user: user, event: initiation, free_trial_used: false)
          expect(attendance).to be_invalid
          expect(attendance.errors[:base]).to include(match(/Adhésion requise/))
        end
      end

      context 'when user uses free trial' do
        it 'allows registration with free trial' do
          # S'assurer que l'utilisateur n'a pas d'adhésion active et n'a pas utilisé l'essai gratuit
          user.memberships.destroy_all
          user.attendances.where(free_trial_used: true).destroy_all
          attendance = build_attendance(user: user, event: initiation, free_trial_used: true)
          expect(attendance).to be_valid
        end
      end
    end
  end
end
