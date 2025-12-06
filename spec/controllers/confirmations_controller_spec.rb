require 'rails_helper'

RSpec.describe ConfirmationsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  let!(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let(:unconfirmed_user) do
    create(:user,
           email: 'unconfirmed@example.com',
           confirmed_at: nil,
           role: role)
  end
  let(:confirmed_user) do
    create(:user,
           email: 'confirmed@example.com',
           confirmed_at: Time.current,
           role: role)
  end

  describe 'POST #create (resend confirmation)' do
    context 'with valid email' do
      it 'sends confirmation email' do
        expect {
          post :create, params: { user: { email: unconfirmed_user.email } }
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it 'shows success message' do
        post :create, params: { user: { email: unconfirmed_user.email } }
        expect(flash[:notice] || assigns(:notice)).to be_present
      end
    end

    context 'with already confirmed email' do
      it 'redirects with notice' do
        post :create, params: { user: { email: confirmed_user.email } }
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include('déjà confirmé')
      end
    end

    context 'with non-existent email (enumeration protection)' do
      it 'shows same success message' do
        post :create, params: { user: { email: 'nonexistent@example.com' } }
        expect(flash[:notice] || assigns(:notice)).to be_present
        # Même message pour protéger contre énumération
      end
    end

    context 'with rate limiting' do
      before do
        # Simuler 6 demandes précédentes
        6.times do
          Rails.cache.increment("resend_confirmation:#{unconfirmed_user.email}:#{Time.current.hour}", 1, expires_in: 1.hour)
        end
      end

      it 'returns rate limit error' do
        post :create, params: { user: { email: unconfirmed_user.email } }
        expect(flash[:alert]).to include('Trop de demandes')
      end
    end
  end

  describe 'GET #show (confirmation link)' do
    context 'with valid token' do
      it 'confirms user' do
        token = unconfirmed_user.confirmation_token
        get :show, params: { confirmation_token: token }
        unconfirmed_user.reload
        expect(unconfirmed_user.confirmed_at).to be_present
      end

      it 'signs in user and redirects' do
        token = unconfirmed_user.confirmation_token
        get :show, params: { confirmation_token: token }
        expect(subject.current_user).to eq(unconfirmed_user)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'with invalid token' do
      it 'redirects with error' do
        get :show, params: { confirmation_token: 'invalid_token' }
        expect(response).to redirect_to(new_user_confirmation_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
