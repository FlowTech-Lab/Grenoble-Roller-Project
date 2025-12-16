require 'rails_helper'

RSpec.describe ContactMessage, type: :model do
  describe 'validations' do
    it 'is valid with default attributes' do
      message = ContactMessage.new(
        name: 'Jane Doe',
        email: 'jane@example.com',
        subject: 'Participation request',
        message: 'Hello! I would like to know more about the upcoming event.'
      )
      expect(message).to be_valid
    end

    it 'requires all mandatory fields' do
      message = ContactMessage.new
      expect(message).to be_invalid
      expect(message.errors[:name]).to be_present
      expect(message.errors[:email]).to be_present
      expect(message.errors[:subject]).to be_present
      expect(message.errors[:message]).to be_present
    end

    it 'validates email format' do
      message = ContactMessage.new(
        name: 'John',
        email: 'invalid-email',
        subject: 'Hello',
        message: 'Long enough message to trigger validation.'
      )
      expect(message).to be_invalid
      expect(message.errors[:email]).to be_present
    end

    it 'requires message length to be at least 10 characters' do
      message = ContactMessage.new(
        name: 'Jane',
        email: 'jane@example.com',
        subject: 'Short message',
        message: 'Too short'
      )
      expect(message).to be_invalid
      expect(message.errors[:message]).to be_present
    end
  end
end
