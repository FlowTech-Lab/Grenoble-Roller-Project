require 'rails_helper'

RSpec.describe 'Attendances', type: :request do
  describe 'GET /attendances' do
    context 'when user is authenticated' do
      it 'lists events the user is registered to' do
        user = create(:user)
        event = create(:event, :published, title: 'Sortie du vendredi')
        create(:attendance, user: user, event: event)
        post user_session_path, params: {
          user: {
            email: user.email,
            password: 'password123'
          }
        }

        get attendances_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Sortie du vendredi')
      end
    end

    context 'when user is a guest' do
      it 'redirects to the login page' do
        get attendances_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end

