require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  let!(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let(:confirmed_user) do
    create(:user,
           email: 'confirmed@example.com',
           password: 'password12345',
           confirmed_at: Time.current,
           role: role)
  end
  let(:unconfirmed_user) do
    create(:user,
           email: 'unconfirmed@example.com',
           password: 'password12345',
           confirmed_at: nil,
           confirmation_sent_at: 1.day.ago,
           role: role)
  end
  let(:expired_user) do
    create(:user,
           email: 'expired@example.com',
           password: 'password12345',
           confirmed_at: nil,
           confirmation_sent_at: 3.days.ago,
           role: role)
  end

  describe 'POST #create' do
    context 'with confirmed email' do
      it 'signs in user successfully' do
        post :create, params: {
          user: { email: confirmed_user.email, password: 'password12345' }
        }
        expect(subject.current_user).to eq(confirmed_user)
        expect(flash[:notice]).to include('Bienvenue')
      end
    end

    context 'with unconfirmed email (grace period)' do
      it 'signs in user with warning message' do
        post :create, params: {
          user: { email: unconfirmed_user.email, password: 'password12345' }
        }
        expect(subject.current_user).to eq(unconfirmed_user)
        expect(flash[:warning]).to include('email n\'est pas encore confirmé')
        expect(flash[:warning]).to include('Renvoyer')
      end
    end

    context 'with unconfirmed email (grace period expired)' do
      it 'does not sign in user and redirects to confirmation' do
        post :create, params: {
          user: { email: expired_user.email, password: 'password12345' }
        }
        expect(subject.current_user).to be_nil
        expect(response).to redirect_to(new_user_confirmation_path(email: expired_user.email))
        expect(flash[:alert]).to include('période de confirmation est expirée')
      end
    end
  end
end
