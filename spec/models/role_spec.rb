require 'rails_helper'

RSpec.describe Role, type: :model do
  let(:valid_attributes) { { name: 'Utilisateur', code: 'ROLE_SPEC', level: 1 } }

  it 'is valid with valid attributes' do
    role = Role.new(valid_attributes)
    expect(role).to be_valid
  end

  it 'requires name, code and level' do
    role = Role.new
    expect(role).to be_invalid
    expect(role.errors[:name]).to be_present
    expect(role.errors[:code]).to be_present
    expect(role.errors[:level]).to be_present
  end

  it 'enforces uniqueness on code and name' do
    Role.create!(valid_attributes)
    dup_code = Role.new(valid_attributes.merge(name: 'Autre'))
    dup_name = Role.new(valid_attributes.merge(code: 'OTHER', level: 2))
    expect(dup_code).to be_invalid
    expect(dup_name).to be_invalid
  end

  it 'requires level to be a positive integer' do
    role = Role.new(name: 'Test', code: 'ROLE_NEG', level: 0)
    expect(role).to be_invalid
    expect(role.errors[:level]).to be_present
  end

  it 'has many users' do
    role = Role.create!(valid_attributes)
    User.create!(email: 'a@example.com', password: 'password123', first_name: 'A', role: role)
    User.create!(email: 'b@example.com', password: 'password123', first_name: 'B', role: role)
    expect(role.users.count).to eq(2)
  end
end

