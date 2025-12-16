require 'rails_helper'

RSpec.describe OrganizerApplication, type: :model do
  let(:applicant) { create_user }
  let(:reviewer_role) { ensure_role(code: 'ADMIN', name: 'Administrator', level: 60) }
  let(:reviewer) { create_user(role: reviewer_role, email: 'admin@example.com') }

  describe 'validations' do
    it 'is valid with a pending status and motivation' do
      application = OrganizerApplication.new(user: applicant, status: 'pending', motivation: 'I love organizing events.')
      expect(application).to be_valid
    end

    it 'requires a motivation when status is pending' do
      application = OrganizerApplication.new(user: applicant, status: 'pending')
      expect(application).to be_invalid
      # En français, on vérifie simplement qu'une erreur est présente (i18n)
      expect(application.errors[:motivation]).to be_present
    end

    it 'allows blank motivation when status is approved' do
      application = OrganizerApplication.new(user: applicant, status: 'approved', reviewed_by: reviewer, reviewed_at: Time.current)
      expect(application).to be_valid
    end

    it 'requires a status value' do
      application = OrganizerApplication.new(user: applicant, status: nil)
      expect(application).to be_invalid
      # En français, on vérifie simplement qu'une erreur est présente (i18n)
      expect(application.errors[:status]).to be_present
    end
  end

  describe 'associations' do
    it 'allows attaching a reviewer' do
      application = OrganizerApplication.create!(
        user: applicant,
        status: 'approved',
        reviewed_by: reviewer,
        reviewed_at: Time.current,
        motivation: 'Ready to help.'
      )

      expect(application.reviewed_by).to eq(reviewer)
    end
  end
end
