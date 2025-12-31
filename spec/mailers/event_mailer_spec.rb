require 'rails_helper'

RSpec.describe EventMailer, type: :mailer do
  let!(:user_role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let!(:organizer_role) { ensure_role(code: 'ORGANIZER', name: 'Organisateur', level: 40) }

  describe '#attendance_confirmed' do
    let(:user) { create(:user, first_name: 'John', email: 'john@example.com', role: user_role) }
    let(:organizer) { create(:user, role: organizer_role) }
    # Créer une adhésion active pour l'utilisateur (requis pour les événements normaux)
    let!(:user_membership) { create(:membership, user: user, status: :active, season: '2025-2026') }
    let(:event) { create(:event, :published, :upcoming, title: 'Sortie Roller', location_text: 'Parc Paul Mistral', creator_user: organizer) }
    let(:attendance) { create(:attendance, user: user, event: event) }
    let(:mail) { EventMailer.attendance_confirmed(attendance) }

    it 'sends to user email' do
      expect(mail.to).to eq([ user.email ])
    end

    it 'includes event title in subject' do
      expect(mail.subject).to include(event.title)
      expect(mail.subject).to include('Inscription confirmée')
    end

    it 'includes event details in body' do
      expect(mail.body.encoded).to include(event.location_text)
      expect(mail.body.encoded).to include(event.title)
    end

    it 'includes user first name in body' do
      expect(mail.body.encoded).to include(user.first_name)
    end

    it 'includes event date in body' do
      # Vérifier que la date est présente (format peut varier)
      # On vérifie que l'année est présente et qu'il y a des chiffres (jour/mois)
      expect(mail.body.encoded).to include(event.start_at.strftime('%Y'))
      expect(mail.body.encoded).to match(/\d+/)
    end

    it 'includes event URL in body' do
      # Le body est encodé, donc on décode pour chercher l'URL
      # event_url génère une URL absolue, on cherche le hashid dans le body décodé
      decoded_body = mail.body.parts.any? ? mail.body.parts.map(&:decoded).join : mail.body.decoded
      expect(decoded_body).to include(event.hashid).or include("/events/#{event.hashid}")
    end

    context 'when event has a route' do
      let(:route) { create(:route, name: 'Parcours du Lac') }
      let(:event) { create(:event, :published, :upcoming, route: route, creator_user: organizer) }
      let(:attendance) { create(:attendance, user: user, event: event) }
      let(:mail) { EventMailer.attendance_confirmed(attendance) }

      it 'includes route name in body' do
        expect(mail.body.encoded).to include(route.name)
      end
    end

    context 'when event has a price' do
      let(:event) { create(:event, :published, :upcoming, price_cents: 1000, creator_user: organizer) }
      let(:attendance) { create(:attendance, user: user, event: event) }
      let(:mail) { EventMailer.attendance_confirmed(attendance) }

      it 'includes price in body' do
        # Vérifier que le prix est présent (format peut varier selon locale)
        # On vérifie que "10" est présent (peut être "10,00", "10.00", "10€", etc.)
        expect(mail.body.encoded).to include('10')
      end
    end

    context 'when event has max_participants' do
      let(:event) { create(:event, :published, :upcoming, max_participants: 20, creator_user: organizer) }
      let(:attendance) { create(:attendance, user: user, event: event, status: 'registered') }
      let(:mail) { EventMailer.attendance_confirmed(attendance) }

      it 'includes participants count in body' do
        # active_attendances_count compte uniquement les inscriptions actives
        expect(mail.body.encoded).to include('1 / 20')
      end
    end
  end

  describe '#attendance_cancelled' do
    let(:organizer) { create_user(role: organizer_role) }
    let(:user) { create_user(first_name: 'Jane', email: 'jane@example.com', role: user_role) }
    let(:event) { create_event(status: 'published', title: 'Sortie Roller', location_text: 'Parc Paul Mistral', creator_user: organizer, start_at: 3.days.from_now) }
    let(:mail) { EventMailer.attendance_cancelled(user, event) }

    it 'sends to user email' do
      expect(mail.to).to eq([ user.email ])
    end

    it 'includes event title in subject' do
      expect(mail.subject).to include(event.title)
      expect(mail.subject).to include('Désinscription confirmée')
    end

    it 'includes event details in body' do
      # Le body peut être multipart (HTML + texte), on vérifie le HTML décodé
      html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
      body_content = html_part ? html_part.decoded : mail.body.decoded
      expect(body_content).to include(event.location_text)
      expect(body_content).to include(event.title)
    end

    it 'includes user first name in body' do
      expect(mail.body.encoded).to include(user.first_name)
    end

    it 'includes event date in body' do
      # Le body peut être multipart (HTML + texte), on vérifie le HTML décodé
      html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
      body_content = html_part ? html_part.decoded : mail.body.decoded
      # Vérifier que la date est présente (format peut varier)
      # On vérifie que l'année est présente et qu'il y a des chiffres (jour/mois)
      expect(body_content).to include(event.start_at.strftime('%Y'))
      expect(body_content).to match(/\d+/)
    end

    it 'includes event URL in body' do
      # Le body est encodé, donc on décode pour chercher l'URL
      # event_url génère une URL absolue, on cherche le hashid dans le body décodé
      decoded_body = mail.body.parts.any? ? mail.body.parts.map(&:decoded).join : mail.body.decoded
      expect(decoded_body).to include(event.hashid).or include("/events/#{event.hashid}")
    end
  end

  describe '#event_reminder' do
    let(:organizer) { create_user(role: organizer_role) }
    let(:user) { create_user(first_name: 'Bob', email: 'bob@example.com', role: user_role) }
    # Créer une adhésion active pour l'utilisateur (requis pour les événements normaux)
    let!(:user_membership) { create(:membership, user: user, status: :active, season: '2025-2026') }
    let(:event) { create_event(status: 'published', title: 'Sortie Roller', location_text: 'Parc Paul Mistral', creator_user: organizer, start_at: 3.days.from_now) }
    let(:attendance) { create_attendance(user: user, event: event) }
    let(:attendances) { [attendance] }
    let(:mail) { EventMailer.event_reminder(user, event, attendances) }

    it 'sends to user email' do
      expect(mail.to).to eq([ user.email ])
    end

    it 'includes event title in subject' do
      expect(mail.subject).to include(event.title)
      expect(mail.subject).to include('Rappel')
    end

    it 'includes event details in body' do
      expect(mail.body.encoded).to include(event.location_text)
      expect(mail.body.encoded).to include(event.title)
    end

    it 'includes user first name in body' do
      expect(mail.body.encoded).to include(user.first_name)
    end

    context 'with multiple attendances (parent + children)' do
      let(:child_membership1) { create(:membership, :child, user: user, status: :active, season: '2025-2026', child_first_name: 'Enfant1') }
      let(:child_membership2) { create(:membership, :child, user: user, status: :active, season: '2025-2026', child_first_name: 'Enfant2') }
      let(:attendance_parent) { create_attendance(user: user, event: event) }
      let(:attendance_child1) { create_attendance(user: user, event: event, child_membership: child_membership1) }
      let(:attendance_child2) { create_attendance(user: user, event: event, child_membership: child_membership2) }
      let(:attendances) { [attendance_parent, attendance_child1, attendance_child2] }
      let(:mail) { EventMailer.event_reminder(user, event, attendances) }

      it 'sends one email with multiple participants' do
        expect(mail.to).to eq([ user.email ])
      end

      it 'includes participant count in subject when multiple' do
        expect(mail.subject).to include('3 participants')
      end

      it 'includes all participant names in body' do
        body = mail.body.parts.any? ? mail.body.parts.map(&:decoded).join : mail.body.decoded
        expect(body).to include(attendance_parent.participant_name)
        expect(body).to include(attendance_child1.participant_name)
        expect(body).to include(attendance_child2.participant_name)
      end
    end
  end
end
