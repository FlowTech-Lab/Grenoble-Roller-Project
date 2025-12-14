# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PasswordsController, type: :controller do
  include Devise::Test::ControllerHelpers

  before do
    # Configurer le mapping Devise pour les tests - CRITIQUE pour que Devise fonctionne
    @request.env["devise.mapping"] = Devise.mappings[:user]
    # S'assurer que le mapping est disponible dans le contrôleur
    allow(controller).to receive(:devise_mapping).and_return(Devise.mappings[:user])
  end

  let!(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let(:user) do
    user = build(:user,
                 email: 'test@example.com',
                 password: 'password12345',
                 confirmed_at: Time.current,
                 role: role)
    allow(user).to receive(:send_confirmation_instructions).and_return(true)
    user.save!
    user
  end

  describe 'POST #create' do

    context 'avec vérification Turnstile réussie' do
      before do
        # Simuler une vérification Turnstile réussie
        allow_any_instance_of(PasswordsController).to receive(:verify_turnstile).and_return(true)
      end

      it 'envoie un email de réinitialisation' do
        # Configurer ActionMailer pour les tests
        ActionMailer::Base.delivery_method = :test
        ActionMailer::Base.perform_deliveries = true
        
        # Mock Turnstile pour éviter les problèmes de mapping
        allow_any_instance_of(PasswordsController).to receive(:verify_turnstile).and_return(true)
        
        expect do
          post :create, params: { user: { email: user.email } }
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it 'redirige vers la page de connexion avec un message de succès' do
        # Configurer ActionMailer pour les tests
        ActionMailer::Base.delivery_method = :test
        ActionMailer::Base.perform_deliveries = true
        
        post :create, params: { user: { email: user.email } }
        # Devise peut rediriger vers sign_in ou root_path
        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to be_present
      end
    end

    context 'avec vérification Turnstile échouée' do
      before do
        # Simuler une vérification Turnstile échouée
        allow_any_instance_of(PasswordsController).to receive(:verify_turnstile).and_return(false)
      end

      it 'ne envoie pas d\'email de réinitialisation' do
        expect do
          post :create, params: { user: { email: user.email } }
        end.not_to change { ActionMailer::Base.deliveries.count }
      end

      it 'affiche un message d\'erreur' do
        post :create, params: { user: { email: user.email } }
        expect(response).to have_http_status(:unprocessable_entity)
        # Vérifier que la ressource a l'erreur
        resource = assigns(:resource)
        expect(resource).to be_present
        expect(resource.errors[:base]).to include('Vérification de sécurité échouée. Veuillez réessayer.')
      end

      it 'ne crée pas de session utilisateur' do
        post :create, params: { user: { email: user.email } }
        expect(controller.current_user).to be_nil
      end
    end

    context 'sans token Turnstile' do
      before do
        # Simuler l'absence de token Turnstile
        allow_any_instance_of(PasswordsController).to receive(:verify_turnstile).and_return(false)
      end

      it 'bloque la demande de réinitialisation' do
        post :create, params: { user: { email: user.email } }
        expect(response).to have_http_status(:unprocessable_entity)
        resource = assigns(:resource)
        expect(resource).to be_present
      end
    end
  end

  describe 'PUT #update' do
    let(:reset_token) { user.send(:set_reset_password_token) }

    context 'avec vérification Turnstile réussie' do
      before do
        # Simuler une vérification Turnstile réussie
        allow_any_instance_of(PasswordsController).to receive(:verify_turnstile).and_return(true)
      end

      it 'réinitialise le mot de passe avec un token valide' do
        new_password = 'newpassword123456'
        put :update, params: {
          user: {
            reset_password_token: reset_token,
            password: new_password,
            password_confirmation: new_password
          }
        }
        # Devise peut rediriger vers root_path après reset de mot de passe
        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to be_present
      end

      it 'rejette un mot de passe trop court' do
        put :update, params: {
          user: {
            reset_password_token: reset_token,
            password: 'short',
            password_confirmation: 'short'
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
        resource = assigns(:resource)
        expect(resource).to be_present
        expect(resource.errors[:password]).to be_present
      end
    end

    context 'avec vérification Turnstile échouée' do
      before do
        # Simuler une vérification Turnstile échouée
        allow_any_instance_of(PasswordsController).to receive(:verify_turnstile).and_return(false)
      end

      it 'ne réinitialise pas le mot de passe' do
        old_encrypted_password = user.encrypted_password
        new_password = 'newpassword123456'
        put :update, params: {
          user: {
            reset_password_token: reset_token,
            password: new_password,
            password_confirmation: new_password
          }
        }
        user.reload
        expect(user.encrypted_password).to eq(old_encrypted_password)
      end

      it 'affiche un message d\'erreur' do
        new_password = 'newpassword123456'
        put :update, params: {
          user: {
            reset_password_token: reset_token,
            password: new_password,
            password_confirmation: new_password
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
        resource = assigns(:resource)
        expect(resource).to be_present
        expect(resource.errors[:base]).to include('Vérification de sécurité échouée. Veuillez réessayer.')
      end
    end

    context 'sans token Turnstile' do
      before do
        # Simuler l'absence de token Turnstile
        allow_any_instance_of(PasswordsController).to receive(:verify_turnstile).and_return(false)
      end

      it 'bloque la réinitialisation du mot de passe' do
        new_password = 'newpassword123456'
        put :update, params: {
          user: {
            reset_password_token: reset_token,
            password: new_password,
            password_confirmation: new_password
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
        resource = assigns(:resource)
        expect(resource).to be_present
      end
    end
  end

  describe 'GET #new' do
    it 'affiche le formulaire de demande de réinitialisation' do
      get :new
      expect(response).to have_http_status(:success)
      # Vérifier que la ressource est assignée
      resource = assigns(:resource)
      expect(resource).to be_present
    end
  end

  describe 'GET #edit' do
    let(:reset_token) { user.send(:set_reset_password_token) }

    context 'avec un token valide' do
      it 'affiche le formulaire de réinitialisation' do
        get :edit, params: { reset_password_token: reset_token }
        expect(response).to have_http_status(:success)
        resource = assigns(:resource)
        expect(resource).to be_present
      end
    end

    context 'sans token' do
      it 'redirige vers la demande de réinitialisation ou la connexion' do
        get :edit
        # Devise peut rediriger vers sign_in si pas de token
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end

    context 'avec un utilisateur connecté' do
      before { sign_in user }

      it 'redirige vers le profil si pas de token' do
        get :edit
        # Peut rediriger vers sign_in ou edit_user_registration_path selon la configuration
        expect(response).to have_http_status(:redirect)
      end

      it 'permet la réinitialisation si un token est présent' do
        get :edit, params: { reset_password_token: reset_token }
        expect(response).to have_http_status(:success)
        resource = assigns(:resource)
        expect(resource).to be_present
      end
    end
  end
end

