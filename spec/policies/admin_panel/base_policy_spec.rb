require 'rails_helper'

RSpec.describe AdminPanel::BasePolicy do
  subject(:policy) { described_class.new(user, resource) }

  let(:resource) { double('Resource') }
  let(:initiation_role) { Role.find_or_create_by!(code: 'INITIATION') { |r| r.name = 'Initiation'; r.level = 30 } }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }
  let(:moderator_role) { Role.find_or_create_by!(code: 'MODERATOR') { |r| r.name = 'Modérateur'; r.level = 50 } }
  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:superadmin_role) { Role.find_or_create_by!(code: 'SUPERADMIN') { |r| r.name = 'Super Administrateur'; r.level = 70 } }

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
