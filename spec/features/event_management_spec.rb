require 'rails_helper'

RSpec.describe 'Event Management', type: :system do
  let!(:organizer) { create(:user, :organizer) }
  let!(:member) { create(:user) }
  let!(:admin) { create(:user, :admin) }
  let!(:route) { create(:route) }

  describe 'Création d\'un événement' do
    context 'quand l\'utilisateur est organizer' do
      before do
        login_as organizer
      end

      it 'affiche le bouton "Créer un événement" dans la navbar' do
        visit root_path
        expect(page).to have_link('Créer un événement')
      end

      it 'permet de créer un événement via le formulaire' do
        visit new_event_path
        
        fill_in 'Titre', with: 'Sortie nocturne Grenoble'
        select 'Published', from: 'Statut'
        select route.name, from: 'Parcours associé'
        fill_in 'Date et heure de début', with: 3.days.from_now.strftime('%Y-%m-%dT%H:%M')
        fill_in 'Durée (minutes)', with: '90'
        fill_in 'Nombre maximum de participants', with: '20'
        fill_in 'Prix (centimes)', with: '0'
        fill_in 'Devise', with: 'EUR'
        fill_in 'Lieu / point de rendez-vous', with: 'Parc Paul Mistral, Grenoble'
        fill_in 'Description détaillée', with: 'Une belle sortie nocturne dans les rues de Grenoble avec tous les participants.'
        
        click_button 'Créer l\'événement'
        
        # Vérifier la redirection vers la page de l'événement
        expect(page).to have_content('Sortie nocturne Grenoble')
        expect(Event.last.title).to eq('Sortie nocturne Grenoble')
        expect(Event.last.max_participants).to eq(20)
      end

      it 'permet de créer un événement avec max_participants = 0 (illimité)' do
        visit new_event_path
        
        fill_in 'Titre', with: 'Sortie illimitée'
        select 'Published', from: 'Statut'
        fill_in 'Date et heure de début', with: 3.days.from_now.strftime('%Y-%m-%dT%H:%M')
        fill_in 'Durée (minutes)', with: '60'
        fill_in 'Nombre maximum de participants', with: '0'
        fill_in 'Prix (centimes)', with: '0'
        fill_in 'Devise', with: 'EUR'
        fill_in 'Lieu / point de rendez-vous', with: 'Grenoble'
        fill_in 'Description détaillée', with: 'Une sortie sans limite de participants.'
        
        click_button 'Créer l\'événement'
        
        expect(Event.last.max_participants).to eq(0)
        expect(Event.last.unlimited?).to be true
      end

      it 'affiche des erreurs de validation si le formulaire est incomplet' do
        visit new_event_path
        click_button 'Créer l\'événement'
        
        # Le formulaire affiche les erreurs de validation
        # Vérifier qu'on est toujours sur la page du formulaire (pas de redirection)
        expect(page).to have_content('Créer un événement')
        # Vérifier qu'il y a des erreurs affichées (soit le message d'erreur, soit au moins un champ avec erreur)
        has_errors = page.has_content?('empêchent l\'enregistrement') || page.has_content?('erreur') || page.has_css?('.alert-danger')
        expect(has_errors).to be true
      end
    end

    context 'quand l\'utilisateur est un simple membre' do
      before do
        login_as member
      end

      it 'n\'affiche pas le bouton "Créer un événement" dans la navbar' do
        visit root_path
        expect(page).not_to have_link('Créer un événement')
      end

      it 'redirige vers la page d\'accueil si accès direct à new_event_path' do
        visit new_event_path
        expect(page).to have_current_path(root_path)
      end
    end
  end

  describe 'Modification d\'un événement' do
    let!(:event) { create(:event, :published, creator_user: organizer, route: route, max_participants: 10, start_at: 3.days.from_now) }

    context 'quand l\'utilisateur est le créateur' do
      before do
        login_as organizer
      end

      it 'permet de modifier l\'événement' do
        visit event_path(event)
        click_link 'Modifier'
        
        fill_in 'Titre', with: 'Titre modifié'
        fill_in 'Nombre maximum de participants', with: '15'
        click_button 'Mettre à jour l\'événement'
        
        expect(page).to have_content('Titre modifié')
        expect(event.reload.max_participants).to eq(15)
      end

      it 'affiche le formulaire pré-rempli avec les données actuelles' do
        visit edit_event_path(event)
        
        expect(page).to have_field('Titre', with: event.title)
        expect(page).to have_field('Nombre maximum de participants', with: event.max_participants)
      end
    end

    context 'quand l\'utilisateur n\'est pas le créateur' do
      let!(:other_organizer) { create(:user, :organizer) }

      before do
        login_as other_organizer
      end

      it 'n\'affiche pas le bouton Modifier' do
        visit event_path(event)
        expect(page).not_to have_link('Modifier')
      end
    end

    context 'quand l\'utilisateur est admin' do
      before do
        login_as admin
      end

      it 'permet de modifier l\'événement même s\'il n\'est pas le créateur' do
        visit event_path(event)
        expect(page).to have_link('Modifier')
      end
    end
  end

  describe 'Suppression d\'un événement' do
    let!(:event) { create(:event, :published, creator_user: organizer, route: route, start_at: 3.days.from_now) }

    context 'quand l\'utilisateur est le créateur' do
      before do
        login_as organizer
      end

      it 'permet de supprimer l\'événement avec confirmation', js: true do
        visit event_path(event)
        
        # Cliquer sur le bouton de suppression qui ouvre le modal
        click_button 'Supprimer'
        
        # Attendre que le modal soit visible
        expect(page).to have_content('Supprimer l\'événement')
        
        # Confirmer dans le modal
        within('#confirmDeleteModalShow') do
          click_button 'Oui, supprimer'
        end
        
        # Attendre la redirection
        expect(page).to have_current_path(events_path)
        expect(Event.find_by(id: event.id)).to be_nil
      end

      it 'annule la suppression si l\'utilisateur clique sur Annuler dans le modal', js: true do
        visit event_path(event)
        
        click_button 'Supprimer'
        
        # Attendre que le modal soit visible
        expect(page).to have_content('Supprimer l\'événement')
        
        # Annuler dans le modal
        within('#confirmDeleteModalShow') do
          click_button 'Annuler'
        end
        
        # Attendre que le modal soit fermé
        sleep 0.5
        
        # Vérifier que l'événement existe toujours
        expect(Event.find_by(id: event.id)).to be_present
      end
    end

    context 'quand l\'utilisateur est admin' do
      before do
        login_as admin
      end

      it 'permet de supprimer l\'événement même s\'il n\'est pas le créateur' do
        visit event_path(event)
        expect(page).to have_button('Supprimer')
      end
    end

    context 'quand l\'utilisateur n\'a pas les permissions' do
      before do
        login_as member
      end

      it 'n\'affiche pas le bouton Supprimer' do
        visit event_path(event)
        expect(page).not_to have_button('Supprimer')
      end
    end
  end

  describe 'Affichage de la liste des événements' do
    let!(:upcoming_event) { create(:event, :published, creator_user: organizer, start_at: 2.days.from_now, route: route) }
    let!(:past_event) { create(:event, :published, creator_user: organizer, start_at: 2.days.ago, route: route) }

    it 'affiche les événements à venir' do
      visit events_path
      
      expect(page).to have_content(upcoming_event.title)
      # Vérifier qu'il y a une section pour les événements à venir
      expect(page).to have_content('À venir')
    end

    it 'affiche les événements passés' do
      visit events_path
      
      expect(page).to have_content(past_event.title)
      # Vérifier qu'il y a une section pour les événements passés
      expect(page).to have_content('Événements passés')
    end

    it 'affiche le prochain événement en vedette' do
      visit events_path
      
      expect(page).to have_content('Prochain rendez-vous')
      expect(page).to have_content(upcoming_event.title)
    end
  end
end

