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
                 confirmation_sent_at: 3.days.ago,
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
        controller.send(:handle_confirmed_or_unconfirmed, expired_user)
        # Devrait déconnecter et rediriger
        expect(flash[:alert]).to include('période de confirmation est expirée')
      end
    end
  end
end
