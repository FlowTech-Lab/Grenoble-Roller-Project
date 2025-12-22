require 'rails_helper'

RSpec.describe AdminPanel::Event::InitiationPolicy do
  subject(:policy) { described_class.new(user, initiation) }

  let(:initiation) { create(:event_initiation) }
  let(:initiation_role) { create(:role, :initiation) }
  let(:organizer_role) { create(:role, :organizer) }
  let(:moderator_role) { create(:role, :moderator) }
  let(:admin_role) { create(:role, :admin) }
  let(:superadmin_role) { create(:role, :superadmin) }

  describe '#index?' do
    context 'when user is initiation (level 30)' do
      let(:user) { create(:user, role: initiation_role) }

      it { expect(policy.index?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.index?).to be(true) }
    end

    context 'when user is moderator (level 50)' do
      let(:user) { create(:user, role: moderator_role) }

      it { expect(policy.index?).to be(true) }
    end

    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.index?).to be(true) }
    end

    context 'when user is superadmin (level 70)' do
      let(:user) { create(:user, role: superadmin_role) }

      it { expect(policy.index?).to be(true) }
    end

    context 'when user level is below 30' do
      let(:user) { create(:user) } # level 10 par défaut

      it { expect(policy.index?).to be(false) }
    end

    context 'when user is nil' do
      let(:user) { nil }

      it { expect(policy.index?).to be(false) }
    end
  end

  describe '#show?' do
    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.show?).to be(true) }
    end

    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.show?).to be(true) }
    end

    context 'when user level is below 30' do
      let(:user) { create(:user) }

      it { expect(policy.show?).to be(false) }
    end
  end

  describe '#create?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.create?).to be(true) }
    end

    context 'when user is superadmin (level 70)' do
      let(:user) { create(:user, role: superadmin_role) }

      it { expect(policy.create?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.create?).to be(false) }
    end

    context 'when user is initiation (level 30)' do
      let(:user) { create(:user, role: initiation_role) }

      it { expect(policy.create?).to be(false) }
    end
  end

  describe '#update?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.update?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.update?).to be(false) }
    end
  end

  describe '#destroy?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.destroy?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.destroy?).to be(false) }
    end
  end

  describe '#presences?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.presences?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.presences?).to be(false) }
    end
  end

  describe '#update_presences?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.update_presences?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.update_presences?).to be(false) }
    end
  end

  describe '#convert_waitlist?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.convert_waitlist?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.convert_waitlist?).to be(false) }
    end
  end

  describe '#notify_waitlist?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.notify_waitlist?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.notify_waitlist?).to be(false) }
    end
  end

  describe '#toggle_volunteer?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.toggle_volunteer?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.toggle_volunteer?).to be(false) }
    end
  end
end
