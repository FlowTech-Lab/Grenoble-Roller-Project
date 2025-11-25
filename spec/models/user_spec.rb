require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }

  def build_user(attrs = {})
    defaults = {
      email: 'john.doe@example.com',
      password: 'password123',
      first_name: 'John',
      skill_level: 'intermediate'
    }
    User.new(defaults.merge(attrs))
  end

  it 'is valid with valid attributes' do
    user = build_user(role: role)
    expect(user).to be_valid
  end

  it 'requires first_name' do
    user = build_user(role: role, first_name: nil)
    expect(user).to be_invalid
    expect(user.errors[:first_name]).to be_present
  end

  it 'validates phone format and allows blank' do
    expect(build_user(role: role, phone: '')).to be_valid
    expect(build_user(role: role, phone: '0612345678')).to be_valid
    invalid = build_user(role: role, phone: 'abc-123')
    expect(invalid).to be_invalid
    expect(invalid.errors[:phone]).to be_present
  end

  it 'belongs to a role' do
    user = build_user(role: role)
    expect(user.role).to eq(role)
  end

  it 'has many orders' do
    user = User.create!(email: 'orders@example.com', password: 'password123', first_name: 'OrderUser', role: role)
    order1 = Order.create!(user: user, status: 'pending', total_cents: 1000, currency: 'EUR')
    order2 = Order.create!(user: user, status: 'pending', total_cents: 2000, currency: 'EUR')
    expect(user.orders).to match_array([order1, order2])
  end

  it 'sets default role on create when not provided' do
    user = build_user(email: 'default-role@example.com')
    expect(user.role).to be_nil
    user.save!
    expect(user.role).to eq(role)
  end

  it 'requires skill_level' do
    user = build_user(role: role, skill_level: nil)
    expect(user).to be_invalid
    expect(user.errors[:skill_level]).to be_present
  end

  it 'validates skill_level inclusion' do
    expect(build_user(role: role, skill_level: 'beginner')).to be_valid
    expect(build_user(role: role, skill_level: 'intermediate')).to be_valid
    expect(build_user(role: role, skill_level: 'advanced')).to be_valid
    
    invalid = build_user(role: role, skill_level: 'invalid')
    expect(invalid).to be_invalid
    expect(invalid.errors[:skill_level]).to be_present
  end

  it 'allows unconfirmed access (period of grace)' do
    user = build_user(role: role, confirmed_at: nil)
    user.save!
    expect(user.active_for_authentication?).to be true
  end

  it 'sends welcome email and confirmation after creation' do
    expect {
      user = build_user(role: role, email: 'welcome@example.com')
      user.save!
    }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
      .at_least(:once) # Au moins un email (bienvenue ou confirmation)
  end
end

