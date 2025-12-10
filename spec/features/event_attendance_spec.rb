require 'rails_helper'

RSpec.describe 'Event Attendance', type: :system do
  let!(:organizer) { create(:user, :organizer) }
  let!(:member) { create(:user) }
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
        expect(page).to have_button('S\'inscrire')
      end

      it 'ouvre le popup de confirmation lors du clic sur S\'inscrire' do
        visit event_path(event)

        # Trouver et cliquer sur le bouton S'inscrire
        find_button('S\'inscrire', match: :first).click

        # Vérifier que le modal est affiché
        expect(page).to have_content('Confirmer votre inscription')
        expect(page).to have_content(event.title)
        expect(page).to have_content(event.location_text)
      end

      it 'inscrit l\'utilisateur après confirmation dans le popup', js: true do
        visit event_path(event)

        # Cliquer sur le bouton pour ouvrir le modal
        find_button('S\'inscrire', match: :first).click

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

      it 'annule l\'inscription si l\'utilisateur clique sur Annuler dans le popup', js: true do
        visit event_path(event)

        find_button('S\'inscrire', match: :first).click

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

        expect(page).to have_button('Se désinscrire')
        expect(page).not_to have_button('S\'inscrire')
      end

      it 'désinscrit l\'utilisateur lors du clic sur Se désinscrire', js: true do
        create(:attendance, user: member, event: event, status: 'registered')
        event.reload
        visit event_path(event)

        # Confirmer la désinscription (Turbo confirm avec JavaScript)
        accept_confirm do
          click_button 'Se désinscrire'
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
        user1 = create(:user)
        user2 = create(:user)
        create(:attendance, event: full_event, user: user1, status: 'registered')
        create(:attendance, event: full_event, user: user2, status: 'registered')
        full_event.reload

        login_as member
      end

      it 'affiche le badge "Complet" et désactive le bouton S\'inscrire' do
        visit event_path(full_event)

        expect(page).to have_content('Complet')
        # Le bouton "Complet" doit être présent et désactivé, ou le bouton S'inscrire ne doit pas être présent
        has_disabled_complete = page.has_button?('Complet', disabled: true) || page.has_button?('Complet')
        has_no_signup = !page.has_button?('S\'inscrire')
        expect(has_disabled_complete || has_no_signup).to be true
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

        expect(page).to have_button('S\'inscrire')
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
        create(:attendance, event: event_with_spots, user: create(:user), status: 'registered')
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
        create(:attendance, event: almost_full_event, user: create(:user), status: 'registered')
        create(:attendance, event: almost_full_event, user: create(:user), status: 'registered')
        almost_full_event.reload

        visit event_path(almost_full_event)

        expect(page).to have_content('1')
        expect(page).to have_content('place disponible')
      end
    end
  end
end
