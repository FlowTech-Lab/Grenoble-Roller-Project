require 'rails_helper'

RSpec.describe EventPolicy do
  subject(:policy) { described_class.new(user, event) }

  let(:event) { create(:event, creator_user: owner) }
  let(:owner) { create(:user, :organizer) }
  let(:user) { owner }

  describe '#show?' do
    context 'when event is published' do
      let(:event) { create(:event, :published, creator_user: owner) }

      it 'allows a guest' do
        user = nil
        expect(described_class.new(user, event).show?).to be(true)
      end
    end

    context 'when event is draft' do
      it 'denies a guest' do
        user = nil
        expect(described_class.new(user, event).show?).to be(false)
      end

      it 'allows the organizer-owner' do
        expect(described_class.new(owner, event).show?).to be(true)
      end
    end
  end

  describe '#create?' do
    it 'allows an organizer' do
      organizer = create(:user, :organizer)
      new_event = build(:event, creator_user: organizer)

      expect(described_class.new(organizer, new_event).create?).to be(true)
    end

    it 'denies a regular member' do
      member = create(:user)
      new_event = build(:event, creator_user: member)

      expect(described_class.new(member, new_event).create?).to be(false)
    end
  end

  describe '#update?' do
    it 'allows the organizer-owner' do
      expect(policy.update?).to be(true)
    end

    it 'denies an organizer who is not the owner' do
      other = create(:user, :organizer)
      expect(described_class.new(other, event).update?).to be(false)
    end

    it 'allows an admin' do
      admin = create(:user, :admin)
      expect(described_class.new(admin, event).update?).to be(true)
    end
  end

  describe '#destroy?' do
    it 'allows the owner' do
      expect(policy.destroy?).to be(true)
    end

    it 'allows an admin' do
      admin = create(:user, :admin)
      expect(described_class.new(admin, event).destroy?).to be(true)
    end

    it 'denies a regular member' do
      member = create(:user)
      expect(described_class.new(member, event).destroy?).to be(false)
    end
  end

  describe '#attend?' do
    it 'allows any signed-in user when event has available spots' do
      member = create(:user)
      event = create(:event, :published, max_participants: 10)
      expect(described_class.new(member, event).attend?).to be(true)
    end

    it 'allows any signed-in user when event is unlimited' do
      member = create(:user)
      event = create(:event, :published, max_participants: 0)
      expect(described_class.new(member, event).attend?).to be(true)
    end

    it 'denies when event is full' do
      member = create(:user)
      event = create(:event, :published, max_participants: 2)
      # Fill the event
      create(:attendance, event: event, user: create(:user), status: 'registered')
      create(:attendance, event: event, user: create(:user), status: 'registered')
      event.reload
      expect(described_class.new(member, event).attend?).to be(false)
    end

    it 'denies guests' do
      expect(described_class.new(nil, event).attend?).to be(false)
    end
  end

  describe '#can_attend?' do
    let(:member) { create(:user) }
    let(:event) { create(:event, :published, max_participants: 10) }

    it 'returns true when user can attend and is not already registered' do
      expect(described_class.new(member, event).can_attend?).to be(true)
    end

    it 'returns false when user is already registered' do
      create(:attendance, event: event, user: member, status: 'registered')
      event.reload
      expect(described_class.new(member, event).can_attend?).to be(false)
    end

    it 'returns false when event is full' do
      event = create(:event, :published, max_participants: 1)
      create(:attendance, event: event, user: create(:user), status: 'registered')
      event.reload
      expect(described_class.new(member, event).can_attend?).to be(false)
    end
  end

  describe '#user_has_attendance?' do
    let(:member) { create(:user) }
    let(:event) { create(:event, :published) }

    it 'returns true when user has an attendance' do
      create(:attendance, event: event, user: member, status: 'registered')
      event.reload
      expect(described_class.new(member, event).user_has_attendance?).to be(true)
    end

    it 'returns false when user does not have an attendance' do
      expect(described_class.new(member, event).user_has_attendance?).to be(false)
    end

    it 'returns false when user is nil' do
      expect(described_class.new(nil, event).user_has_attendance?).to be(false)
    end
  end

  describe 'Scope' do
    let!(:published_event) { create(:event, :published) }
    let!(:draft_event) { create(:event, status: 'draft', creator_user: owner) }

    it 'returns only published events for guests' do
      scope = described_class::Scope.new(nil, Event.all).resolve

      expect(scope).to contain_exactly(published_event)
    end

    it 'returns published + own events for a member' do
      member = create(:user)
      scope = described_class::Scope.new(member, Event.all).resolve

      expect(scope).to include(published_event)
      expect(scope).not_to include(draft_event)
    end

    it 'returns published + own events for organizer' do
      organizer = owner
      scope = described_class::Scope.new(organizer, Event.all).resolve

      expect(scope).to include(published_event, draft_event)
    end

    it 'returns all events for admin' do
      admin = create(:user, :admin)
      scope = described_class::Scope.new(admin, Event.all).resolve

      expect(scope).to include(published_event, draft_event)
    end
  end
end
