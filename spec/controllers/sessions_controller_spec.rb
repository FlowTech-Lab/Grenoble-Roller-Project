require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  include Devise::Test::ControllerHelpers

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  let!(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let(:confirmed_user) do
    user = build(:user,
                 email: 'confirmed@example.com',
                 password: 'password12345',
                 confirmed_at: Time.current,
                 role: role)
    allow(user).to receive(:send_confirmation_instructions).and_return(true)
    user.save!
    user
  end
  let(:unconfirmed_user) do
    user = build(:user,
                 email: 'unconfirmed@example.com',
                 password: 'password12345',
                 confirmed_at: nil,
                 confirmation_sent_at: 1.day.ago,
                 role: role)
    allow(user).to receive(:send_confirmation_instructions).and_return(true)
    user.save!
    user
  end
  let(:expired_user) do
    user = build(:user,
                 email: 'expired@example.com',
                 password: 'password12345',
                 confirmed_at: nil,
                 confirmation_sent_at: 4.days.ago, # Expiré (au-delà de 2 jours de grâce)
                 role: role)
    allow(user).to receive(:send_confirmation_instructions).and_return(true)
    user.save!
    user
  end

  describe '#handle_confirmed_or_unconfirmed' do
    context 'with confirmed email' do
      it 'sets welcome message' do
        # Tester directement la méthode privée
        controller.send(:handle_confirmed_or_unconfirmed, confirmed_user)
        expect(flash[:notice]).to include('Bienvenue')
      end
    end

    context 'with unconfirmed email (grace period)' do
      before { sign_in unconfirmed_user, scope: :user }

      it 'signs in user with warning message' do
        controller.send(:handle_confirmed_or_unconfirmed, unconfirmed_user)
        expect(flash[:warning]).to include('email n\'est pas encore confirmé')
        expect(flash[:warning]).to include('Renvoyer')
      end
    end

    context 'with unconfirmed email (grace period expired)' do
      before { sign_in expired_user, scope: :user }

      it 'signs out user and sets alert' do
        # Vérifier que expired_user n'est pas confirmé
        expect(expired_user.confirmed?).to be false
        # Vérifier que confirmation_sent_at existe et est dans le passé (expiré)
        expect(expired_user.confirmation_sent_at).to be_present
        expect(expired_user.confirmation_sent_at).to be < Time.current
        
        # S'assurer que sign_out sera appelé
        sign_out_called = false
        allow(controller).to receive(:sign_out) do |*args|
          sign_out_called = true
        end
        
        # S'assurer que redirect_to sera appelé
        redirect_called = false
        allow(controller).to receive(:redirect_to) do |*args|
          redirect_called = true
          # À ce moment, le flash devrait être défini
          expect(controller.flash[:alert]).to include('période de confirmation est expirée')
        end
        
        # Appeler la méthode qui devrait signer out et définir le flash
        controller.send(:handle_confirmed_or_unconfirmed, expired_user)
        
        # Vérifier que sign_out a été appelé
        expect(sign_out_called).to be true
        # Vérifier que redirect_to a été appelé
        expect(redirect_called).to be true
      end
    end
  end
end
