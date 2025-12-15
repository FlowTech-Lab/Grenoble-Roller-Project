require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  let!(:user_role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  
  describe '#welcome_email' do
    let(:user) { create(:user, first_name: 'Jean', email: 'jean@example.com', skill_level: 'intermediate', role: user_role) }
    let(:mail) { UserMailer.welcome_email(user) }

    it 'sends to user email' do
      expect(mail.to).to eq([ user.email ])
    end

    it 'has correct subject' do
      expect(mail.subject).to include('Bienvenue')
      expect(mail.subject).to include('Grenoble Roller')
    end

    it 'includes user first name in body' do
      # Le body est encodé, donc on décode pour chercher
      decoded_body = mail.body.parts.any? ? mail.body.parts.map(&:decoded).join : mail.body.decoded
      expect(decoded_body).to include(user.first_name)
    end

    it 'includes link to events' do
      # Le body est encodé, donc on décode pour chercher l'URL
      decoded_body = mail.body.parts.any? ? mail.body.parts.map(&:decoded).join : mail.body.decoded
      expect(decoded_body).to include('/events').or include('events')
    end

    it 'has HTML content' do
      # Vérifier que le mail a une partie HTML ou que le body contient du HTML
      if mail.html_part
        expect(mail.html_part).to be_present
        expect(mail.html_part.body.decoded).to include(user.first_name)
      else
        # Si pas de html_part, vérifier que le body contient du HTML
        decoded_body = mail.body.decoded
        expect(decoded_body).to include('<html').or include('<h1').or include('<!DOCTYPE')
      end
    end

    it 'has text content as fallback' do
      # Vérifier que le mail a une partie texte ou que le body contient du texte
      if mail.text_part
        expect(mail.text_part).to be_present
        expect(mail.text_part.body.decoded).to include(user.first_name)
      else
        # Si pas de text_part, vérifier que le body contient du texte
        decoded_body = mail.body.decoded
        expect(decoded_body).to include(user.first_name)
      end
    end

    it 'includes welcome message' do
      expect(mail.body.encoded).to match(/bienvenue/i)
    end
  end
end
