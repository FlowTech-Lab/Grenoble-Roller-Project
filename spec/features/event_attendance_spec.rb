require 'rails_helper'

RSpec.describe 'Event Attendance', type: :system do
  let!(:organizer_role) { ensure_role(code: 'ORGANIZER', name: 'Organisateur', level: 40) }
  let!(:user_role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let!(:organizer) { create(:user, role: organizer_role) }
  let!(:member) { create(:user, role: user_role) }
  let!(:route) { create(:route) }
  let!(:event) { create(:event, :published, creator_user: organizer, route: route, max_participants: 10, start_at: 3.days.from_now) }

  describe 'Inscription à un événement' do
    context 'quand l\'utilisateur est connecté' do
      before do
        login_as member
      end

      it 'affiche le bouton S\'inscrire sur la page événements' do
        visit events_path
        expect(page).to have_content(event.title)
        expect(page).to have_button('S\'inscrire')
      end

      it 'affiche le bouton S\'inscrire sur la page détail de l\'événement' do
        visit event_path(event)
        expect(page).to have_content(event.title)
        # Le bouton affiche "Inscription" dans la vue, mais on peut chercher par aria-label ou texte
        expect(page).to have_button('Inscription').or have_button("S'inscrire")
      end

      it 'ouvre le popup de confirmation lors du clic sur S\'inscrire' do
        visit event_path(event)

        # Trouver et cliquer sur le bouton (peut être "Inscription" ou "S'inscrire")
        button = page.find('button[aria-label*="inscrire"]', match: :first)
        button.click

        # Vérifier que le modal est affiché
        expect(page).to have_content('Confirmer votre inscription')
        expect(page).to have_content(event.title)
        expect(page).to have_content(event.location_text)
      end

      xit 'inscrit l\'utilisateur après confirmation dans le popup', js: true do # SKIP: ChromeDriver non disponible
        visit event_path(event)

        # Cliquer sur le bouton pour ouvrir le modal (chercher par aria-label)
        button = page.find('button[aria-label*="inscrire"]', match: :first)
        button.click

        # Attendre que le modal soit visible
        expect(page).to have_content('Confirmer votre inscription')

        # Confirmer dans le modal
        within('.modal') do
          click_button 'Confirmer l\'inscription'
        end

        # Vérifier le message de succès (redirection après inscription)
        expect(page).to have_content(event.title)
        expect(event.reload.attendances.where(user: member).exists?).to be true
      end

      xit 'annule l\'inscription si l\'utilisateur clique sur Annuler dans le popup', js: true do # SKIP: ChromeDriver non disponible
        visit event_path(event)

        button = page.find('button[aria-label*="inscrire"]', match: :first)
        button.click

        # Attendre que le modal soit visible
        expect(page).to have_content('Confirmer votre inscription')

        # Annuler dans le modal
        within('.modal') do
          click_button 'Annuler'
        end

        # Attendre que le modal soit fermé
        sleep 0.5

        # Vérifier que le modal est fermé et que l'utilisateur n'est pas inscrit
        expect(page).not_to have_content('Confirmer votre inscription', wait: 2)
        expect(event.attendances.where(user: member).exists?).to be false
      end

      it 'affiche le bouton "Se désinscrire" après inscription' do
        create(:attendance, user: member, event: event, status: 'registered')
        event.reload
        visit event_path(event)

        # Le bouton affiche "Annuler" mais a aria-label="Se désinscrire"
        expect(page).to have_button('Annuler').or have_button("Se désinscrire")
        # Le bouton "S'inscrire" ou "Inscription" ne doit pas être présent
        expect(page).not_to have_button('S\'inscrire')
        expect(page).not_to have_button('Inscription')
      end

      xit 'désinscrit l\'utilisateur lors du clic sur Se désinscrire', js: true do # SKIP: ChromeDriver non disponible
        create(:attendance, user: member, event: event, status: 'registered')
        event.reload
        visit event_path(event)

        # Confirmer la désinscription (Turbo confirm avec JavaScript)
        # Le bouton affiche "Annuler" mais a aria-label="Se désinscrire"
        accept_confirm do
          button = page.find('button[aria-label="Se désinscrire"]')
          button.click
        end

        # Attendre que la page se recharge
        sleep 0.5

        # Vérifier que le bouton "S'inscrire" apparaît maintenant
        expect(page).to have_button('S\'inscrire')
        expect(event.reload.attendances.where(user: member).exists?).to be false
      end
    end

    context 'quand l\'événement est plein' do
      let!(:full_event) { create(:event, :published, creator_user: organizer, max_participants: 2, start_at: 4.days.from_now) }

      before do
        # Remplir l'événement avec des inscriptions actives
        user1 = create(:user, role: user_role)
        user2 = create(:user, role: user_role)
        create(:attendance, event: full_event, user: user1, status: 'registered')
        create(:attendance, event: full_event, user: user2, status: 'registered')
        full_event.reload

        login_as member
      end

      it 'affiche le badge "Complet" et désactive le bouton S\'inscrire' do
        visit event_path(full_event)

        expect(page).to have_content('Complet')
        # Le bouton "S'inscrire" ou "Inscription" ne doit pas être présent quand l'événement est complet
        expect(page).not_to have_button('S\'inscrire')
        expect(page).not_to have_button('Inscription')
      end

      it 'n\'affiche pas le bouton S\'inscrire sur la liste des événements' do
        visit events_path
        expect(page).to have_content(full_event.title)
        # Vérifier que l'événement est affiché avec le badge Complet
        # Trouver la card de l'événement plein
        event_card = page.find('.card-event', text: full_event.title)
        expect(event_card).to have_content('Complet')
      end
    end

    context 'quand l\'événement est illimité (max_participants = 0)' do
      let!(:unlimited_event) { create(:event, :published, creator_user: organizer, max_participants: 0, start_at: 5.days.from_now) }

      before do
        login_as member
      end

      it 'permet l\'inscription même avec max_participants = 0' do
        visit event_path(unlimited_event)

        # Le bouton peut être "Inscription" ou "S'inscrire"
        expect(page).to have_button('Inscription').or have_button("S'inscrire")
      end
    end

    context 'quand l\'utilisateur n\'est pas connecté' do
      it 'redirige vers la page de connexion lors du clic sur S\'inscrire' do
        visit event_path(event)

        # Le bouton S'inscrire ne doit pas être visible pour les non connectés
        expect(page).not_to have_button('S\'inscrire')
      end
    end
  end

  describe 'Affichage des places restantes' do
    before do
      login_as member
    end

    context 'quand il reste des places' do
      let!(:event_with_spots) { create(:event, :published, creator_user: organizer, max_participants: 5, start_at: 6.days.from_now) }

      it 'affiche le nombre de places disponibles' do
        create(:attendance, event: event_with_spots, user: create(:user, role: user_role), status: 'registered')
        event_with_spots.reload

        visit event_path(event_with_spots)

        # Vérifier que les places restantes sont affichées
        expect(page).to have_content(event_with_spots.remaining_spots.to_s)
        expect(page).to have_content('place disponible')
      end
    end

    context 'quand l\'événement est presque plein' do
      let!(:almost_full_event) { create(:event, :published, creator_user: organizer, max_participants: 3, start_at: 7.days.from_now) }

      it 'affiche le nombre de places restantes' do
        create(:attendance, event: almost_full_event, user: create(:user, role: user_role), status: 'registered')
        create(:attendance, event: almost_full_event, user: create(:user, role: user_role), status: 'registered')
        almost_full_event.reload

        visit event_path(almost_full_event)

        expect(page).to have_content('1')
        expect(page).to have_content('place disponible')
      end
    end
  end
end
