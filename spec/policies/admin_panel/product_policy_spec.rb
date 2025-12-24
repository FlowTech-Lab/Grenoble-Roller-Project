require 'rails_helper'

RSpec.describe AdminPanel::ProductPolicy do
  subject(:policy) { described_class.new(user, product) }

  # Pour les tests de policy, on peut utiliser build_stubbed (pas besoin de DB)
  # ou créer un produit avec variante
  let(:product) do
    p = build(:product)
    p.product_variants.build(
      sku: "SKU-#{SecureRandom.hex(4)}",
      price_cents: 5000,
      currency: 'EUR',
      stock_qty: 10,
      is_active: true
    )
    p.save(validate: false) # Skip validation pour les tests de policy
    p
  end
  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }

  describe '#index?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.index?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.index?).to be(false) }
    end
  end

  describe '#show?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.show?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.show?).to be(false) }
    end
  end

  describe '#create?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.create?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

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
end
