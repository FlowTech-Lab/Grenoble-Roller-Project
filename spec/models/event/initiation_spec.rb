require 'rails_helper'

RSpec.describe Event::Initiation, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:creator) { create_user }

  def next_saturday_at_10_15
    today = Date.today
    days_until_saturday = (6 - today.wday) % 7
    days_until_saturday = 7 if days_until_saturday == 0 && Time.current.hour >= 10
    (today + days_until_saturday.days).beginning_of_day + 10.hours + 15.minutes
  end

  describe 'validations' do
    it 'is valid with default attributes' do
      initiation = build(:event_initiation, creator_user: creator)
      expect(initiation).to be_valid
    end

    # Les validations spécifiques sur saison / jour / heure / lieu ont été
    # simplifiées dans le modèle. On vérifie encore la cohérence métier minimale.
    it 'requires max_participants > 0' do
      initiation = build(:event_initiation, creator_user: creator, max_participants: 0)
      expect(initiation).to be_invalid
      expect(initiation.errors[:max_participants]).to be_present
    end
  end

  describe '#full?' do
    it 'returns true when no places available' do
      initiation = create(:event_initiation, creator_user: creator, max_participants: 2)
      # créer des participants adhérents pour respecter les validations Attendance
      2.times do
        participant = create_user
        create(:membership, user: participant, status: :active, season: '2025-2026')
        create(:attendance, event: initiation, user: participant, is_volunteer: false, status: 'registered')
      end
      expect(initiation.full?).to be true
    end

    it 'returns false when places available' do
      initiation = create(:event_initiation, creator_user: creator, max_participants: 30)
      10.times do
        participant = create_user
        create(:membership, user: participant, status: :active, season: '2025-2026')
        create(:attendance, event: initiation, user: participant, is_volunteer: false, status: 'registered')
      end
      expect(initiation.full?).to be false
    end

    it 'does not count volunteers' do
      initiation = create(:event_initiation, creator_user: creator, max_participants: 1)
      volunteer = create_user
      create(:attendance, event: initiation, user: volunteer, is_volunteer: true, status: 'registered')
      participant = create_user
      create(:membership, user: participant, status: :active, season: '2025-2026')
      create(:attendance, event: initiation, user: participant, is_volunteer: false, status: 'registered')
      expect(initiation.full?).to be true
    end
  end

  describe '#available_places' do
    it 'calculates correctly' do
      initiation = create(:event_initiation, creator_user: creator, max_participants: 30)
      5.times do
        participant = create_user
        create(:membership, user: participant, status: :active, season: '2025-2026')
        create(:attendance, event: initiation, user: participant, is_volunteer: false, status: 'registered')
      end
      expect(initiation.available_places).to eq(25)
    end

    it 'does not count volunteers' do
      initiation = create(:event_initiation, creator_user: creator, max_participants: 10)
      3.times do
        volunteer = create_user
        create(:attendance, event: initiation, user: volunteer, is_volunteer: true, status: 'registered')
      end
      5.times do
        participant = create_user
        create(:membership, user: participant, status: :active, season: '2025-2026')
        create(:attendance, event: initiation, user: participant, is_volunteer: false, status: 'registered')
      end
      expect(initiation.available_places).to eq(5) # 10 - 5 = 5
    end
  end

  describe '#participants_count' do
    it 'counts only non-volunteer attendances' do
      initiation = create(:event_initiation, creator_user: creator)
      3.times do
        participant = create_user
        create(:membership, user: participant, status: :active, season: '2025-2026')
        create(:attendance, event: initiation, user: participant, is_volunteer: false, status: 'registered')
      end
      2.times do
        volunteer = create_user
        create(:attendance, event: initiation, user: volunteer, is_volunteer: true, status: 'registered')
      end
      expect(initiation.participants_count).to eq(3)
    end

    it 'counts only registered and present status' do
      initiation = create(:event_initiation, creator_user: creator)
      %w[registered present canceled].each do |status|
        participant = create_user
        create(:membership, user: participant, status: :active, season: '2025-2026')
        create(:attendance, event: initiation, user: participant, is_volunteer: false, status: status)
      end
      expect(initiation.participants_count).to eq(2)
    end
  end

  describe '#volunteers_count' do
    it 'counts only volunteer attendances' do
      initiation = create(:event_initiation, creator_user: creator)
      3.times do
        volunteer = create_user
        create(:attendance, event: initiation, user: volunteer, is_volunteer: true, status: 'registered')
      end
      2.times do
        participant = create_user
        create(:membership, user: participant, status: :active, season: '2025-2026')
        create(:attendance, event: initiation, user: participant, is_volunteer: false, status: 'registered')
      end
      expect(initiation.volunteers_count).to eq(3)
    end
  end

  describe '#unlimited?' do
    it 'always returns false for initiations' do
      initiation = create(:event_initiation, creator_user: creator)
      expect(initiation.unlimited?).to be false
    end
  end

  describe 'scopes' do
    describe '.by_season' do
      it 'filters by season' do
        initiation_2025 = create(:event_initiation, creator_user: creator, season: '2025-2026')
        initiation_2026 = create(:event_initiation, creator_user: creator, season: '2026-2027')

        expect(Event::Initiation.by_season('2025-2026')).to contain_exactly(initiation_2025)
      end
    end

    describe '.upcoming_initiations' do
      it 'returns only future initiations' do
        future = create(:event_initiation, creator_user: creator, start_at: 1.week.from_now)
        past = create(:event_initiation, creator_user: creator, start_at: 1.week.ago)

        expect(Event::Initiation.upcoming_initiations).to include(future)
        expect(Event::Initiation.upcoming_initiations).not_to include(past)
      end
    end
  end
end
