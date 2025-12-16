require 'rails_helper'

RSpec.describe Membership, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe 'season and activity over time' do
    it 'considers memberships inactive after season end via active_now scope' do
      # Créer un utilisateur valide avec un rôle, puis une adhésion active
      role = Role.find_or_create_by!(code: 'USER') { |r| r.name = 'User'; r.level = 10 }
      user = User.create!(
        first_name: 'Season',
        last_name: 'Tester',
        email: 'season.tester@example.com',
        password: 'password12345',
        skill_level: 'intermediate',
        role: role
      )

      membership = Membership.create!(
        user: user,
        status: :active,
        category: :standard,
        start_date: Date.new(2025, 9, 1),
        end_date: Date.new(2026, 8, 31),
        amount_cents: 1000,
        currency: 'EUR',
        season: '2025-2026',
        is_child_membership: false,
        rgpd_consent: true,
        legal_notices_accepted: true
      )

      inside_season_date = membership.start_date + 30.days
      after_season_date  = membership.end_date + 1.day

      travel_to inside_season_date do
        expect(Membership.active_now).to include(membership)
        expect(membership.active?).to be(true)
      end

      # Après la fin de saison, l'adhésion ne doit plus être considérée "active maintenant"
      travel_to after_season_date do
        expect(Membership.active_now).not_to include(membership)
        expect(membership.active?).to be(false)
      end
    end
  end
end
