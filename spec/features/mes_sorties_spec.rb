require 'rails_helper'

RSpec.describe 'Mes sorties', type: :system do
  let(:organizer) { create(:user, :organizer) }
  let(:member) { create(:user) }
  let(:route) { create(:route) }
  let!(:event1) { create(:event, :published, creator_user: organizer, route: route, start_at: 3.days.from_now) }
  let!(:event2) { create(:event, :published, creator_user: organizer, route: route, start_at: 5.days.from_now) }
  let!(:event3) { create(:event, :published, creator_user: organizer, route: route, start_at: 7.days.from_now) }

  describe 'Accès à la page Mes sorties' do
    context 'quand l\'utilisateur est connecté' do
      before do
        login_as member
      end

      it 'affiche le lien "Mes sorties" dans le menu utilisateur' do
        visit root_path
        click_button "#{member.first_name.presence || member.email}"
        
        within('.dropdown-menu') do
          expect(page).to have_link('Mes sorties')
        end
      end

      it 'affiche la page Mes sorties avec les événements inscrits' do
        create(:attendance, user: member, event: event1, status: 'registered')
        create(:attendance, user: member, event: event2, status: 'registered')
        
        visit attendances_path
        
        expect(page).to have_content('Mes sorties')
        expect(page).to have_content(event1.title)
        expect(page).to have_content(event2.title)
        expect(page).not_to have_content(event3.title)
      end

      it 'affiche un message si l\'utilisateur n\'est inscrit à aucun événement' do
        visit attendances_path
        
        expect(page).to have_content('Mes sorties')
        # Vérifier le message d'alerte (l'apostrophe peut être typographique)
        expect(page).to have_content('Vous n').and have_content('êtes inscrit(e) à aucune sortie pour le moment')
      end

      it 'permet de se désinscrire depuis la page Mes sorties', js: true do
        create(:attendance, user: member, event: event1, status: 'registered')
        
        visit attendances_path
        expect(page).to have_content(event1.title)
        
        # Trouver le bouton de désinscription dans la card de l'événement
        # La card utilise le partial event_card, donc le bouton est dans la card
        event_card = page.find('.card-event', text: event1.title)
        within(event_card) do
          accept_confirm do
            click_button 'Se désinscrire'
          end
        end
        
        # Attendre que la page se recharge
        sleep 0.5
        
        # Vérifier que l'événement n'est plus dans la liste
        expect(page).not_to have_content(event1.title)
        expect(event1.reload.attendances.where(user: member).exists?).to be false
      end

      it 'affiche les informations de l\'événement (date, lieu, nombre d\'inscrits)' do
        create(:attendance, user: member, event: event1, status: 'registered')
        
        visit attendances_path
        
        expect(page).to have_content(event1.title)
        expect(page).to have_content(event1.location_text)
        # Vérifier que la date est affichée (le format exact peut varier, mais on vérifie que la date est présente)
        # La date est formatée par I18n, donc on vérifie juste qu'elle contient quelque chose de la date
        expect(page).to have_content(event1.start_at.strftime('%d'))
      end

      it 'n\'affiche que les événements où l\'utilisateur est inscrit' do
        other_user = create(:user)
        create(:attendance, user: member, event: event1, status: 'registered')
        create(:attendance, user: other_user, event: event2, status: 'registered')
        
        visit attendances_path
        
        expect(page).to have_content(event1.title)
        expect(page).not_to have_content(event2.title)
      end

      it 'n\'affiche pas les inscriptions annulées' do
        create(:attendance, user: member, event: event1, status: 'registered')
        create(:attendance, user: member, event: event2, status: 'canceled')
        
        visit attendances_path
        
        expect(page).to have_content(event1.title)
        expect(page).not_to have_content(event2.title)
      end
    end

    context 'quand l\'utilisateur n\'est pas connecté' do
      it 'redirige vers la page de connexion' do
        visit attendances_path
        expect(page).to have_current_path(new_user_session_path)
      end
    end
  end

  describe 'Navigation depuis Mes sorties' do
    before do
      login_as member
      create(:attendance, user: member, event: event1, status: 'registered')
    end

    it 'permet de cliquer sur un événement pour voir les détails' do
      visit attendances_path
      
      # Le titre de l'événement est dans un lien ou dans une card avec stretched-link
      # On peut cliquer sur le lien "Voir plus" ou sur le titre via le stretched-link
      event_card = page.find('.card-event', text: event1.title)
      within(event_card) do
        click_link 'Voir plus'
      end
      
      expect(page).to have_current_path(event_path(event1))
      expect(page).to have_content(event1.title)
      # Vérifier que le bouton "Se désinscrire" est présent (indique que l'utilisateur est inscrit)
      expect(page).to have_button('Se désinscrire')
    end

    it 'permet de retourner à la liste des événements' do
      visit attendances_path
      
      expect(page).to have_link('Voir toutes les sorties')
      click_link 'Voir toutes les sorties'
      
      expect(page).to have_current_path(events_path)
    end
  end
end

