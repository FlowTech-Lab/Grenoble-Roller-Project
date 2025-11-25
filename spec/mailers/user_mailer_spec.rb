require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  describe '#welcome_email' do
    let(:user) { create(:user, first_name: 'Jean', email: 'jean@example.com', skill_level: 'intermediate') }
    let(:mail) { UserMailer.welcome_email(user) }

    it 'sends to user email' do
      expect(mail.to).to eq([ user.email ])
    end

    it 'has correct subject' do
      expect(mail.subject).to include('Bienvenue')
      expect(mail.subject).to include('Grenoble Roller')
    end

    it 'includes user first name in body' do
      expect(mail.body.encoded).to include(user.first_name)
    end

    it 'includes link to events' do
      expect(mail.body.encoded).to include(events_url)
    end

    it 'has HTML content' do
      expect(mail.html_part).to be_present
      expect(mail.html_part.body.encoded).to include(user.first_name)
    end

    it 'has text content as fallback' do
      expect(mail.text_part).to be_present
      expect(mail.text_part.body.encoded).to include(user.first_name)
    end

    it 'includes welcome message' do
      expect(mail.body.encoded).to match(/bienvenue/i)
    end
  end
end
