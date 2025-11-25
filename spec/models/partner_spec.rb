require 'rails_helper'

RSpec.describe Partner, type: :model do
  describe 'validations' do
    it 'is valid with default attributes' do
      partner = Partner.new(name: 'Roller Shop', url: 'https://rollershop.example', is_active: true)
      expect(partner).to be_valid
    end

    it 'requires a name' do
      partner = Partner.new(url: 'https://example.com', is_active: true)
      expect(partner).to be_invalid
      expect(partner.errors[:name]).to include("can't be blank")
    end

    it 'validates URL format when provided' do
      partner = Partner.new(name: 'Invalid URL', url: 'ftp://example.com', is_active: true)
      expect(partner).to be_invalid
      expect(partner.errors[:url]).to include('is invalid')
    end

    it 'requires is_active to be a boolean' do
      partner = Partner.new(name: 'Boolean Check', is_active: nil)
      expect(partner).to be_invalid
      expect(partner.errors[:is_active]).to include('is not included in the list')
    end
  end

  describe 'scopes' do
    it 'returns active partners for the active scope' do
      active = Partner.create!(name: 'Active Partner', url: 'https://active.example', is_active: true)
      Partner.create!(name: 'Inactive Partner', url: 'https://inactive.example', is_active: false)

      expect(Partner.active).to contain_exactly(active)
    end

    it 'returns inactive partners for the inactive scope' do
      inactive = Partner.create!(name: 'Inactive Partner', url: 'https://inactive.example', is_active: false)
      Partner.create!(name: 'Active Partner', url: 'https://active.example', is_active: true)

      expect(Partner.inactive).to contain_exactly(inactive)
    end
  end
end
