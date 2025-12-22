require 'rails_helper'

RSpec.describe AdminPanel::BasePolicy do
  subject(:policy) { described_class.new(user, resource) }

  let(:resource) { double('Resource') }
  let(:initiation_role) { create(:role, :initiation) }
  let(:organizer_role) { create(:role, :organizer) }
  let(:moderator_role) { create(:role, :moderator) }
  let(:admin_role) { create(:role, :admin) }
  let(:superadmin_role) { create(:role, :superadmin) }

  describe '#index?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.index?).to be(true) }
    end

    context 'when user is superadmin (level 70)' do
      let(:user) { create(:user, role: superadmin_role) }

      it { expect(policy.index?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.index?).to be(false) }
    end

    context 'when user is initiation (level 30)' do
      let(:user) { create(:user, role: initiation_role) }

      it { expect(policy.index?).to be(false) }
    end

    context 'when user is nil' do
      let(:user) { nil }

      it { expect(policy.index?).to be(false) }
    end
  end

  describe '#show?' do
    context 'when user is admin' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.show?).to be(true) }
    end

    context 'when user is organizer' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.show?).to be(false) }
    end
  end

  describe '#create?' do
    context 'when user is admin' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.create?).to be(true) }
    end

    context 'when user is organizer' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.create?).to be(false) }
    end
  end

  describe '#update?' do
    context 'when user is admin' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.update?).to be(true) }
    end

    context 'when user is organizer' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.update?).to be(false) }
    end
  end

  describe '#destroy?' do
    context 'when user is admin' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.destroy?).to be(true) }
    end

    context 'when user is organizer' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.destroy?).to be(false) }
    end
  end

  describe 'Scope' do
    let(:scope) { double('Scope') }
    subject(:policy_scope) { described_class::Scope.new(user, scope) }

    context 'when user is admin' do
      let(:user) { create(:user, role: admin_role) }

      it 'returns the full scope' do
        expect(policy_scope.resolve).to eq(scope)
      end
    end

    context 'when user is organizer' do
      let(:user) { create(:user, role: organizer_role) }

      it 'returns empty scope' do
        expect(policy_scope.resolve).to be_empty
      end
    end
  end
end
