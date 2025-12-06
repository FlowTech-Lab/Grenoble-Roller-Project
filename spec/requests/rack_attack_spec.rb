require 'rails_helper'

RSpec.describe 'Rack::Attack', type: :request do
  include Rack::Test::Methods

  def app
    Rails.application
  end

  before do
    # Réinitialiser le cache pour les tests
    Rails.cache.clear
  end

  describe 'confirmation resend rate limiting' do
    context 'within limits' do
      it 'allows 5 resends per hour per email' do
        5.times do
          post '/users/confirmation',
               params: { user: { email: 'test@example.com' } }
          expect(last_response.status).not_to eq(429)
        end
      end
    end

    context 'exceeds limit' do
      it 'returns 429 after 5 resends' do
        6.times do |i|
          post '/users/confirmation',
               params: { user: { email: 'test@example.com' } }
        end
        expect(last_response.status).to eq(429)
        expect(last_response.body).to include('Trop de demandes')
      end
    end

    context 'rate limiting by IP' do
      it 'allows 10 requests per hour per IP' do
        # Simuler différentes adresses IP pour tester le throttle IP
        # Note: En test, l'IP peut être la même, donc ce test vérifie surtout le fonctionnement
        allow_any_instance_of(ActionDispatch::Request).to receive(:ip).and_return('1.2.3.4')
        10.times do
          post '/users/confirmation',
               params: { user: { email: "test#{SecureRandom.hex(4)}@example.com" } }
          expect(last_response.status).not_to eq(429)
        end
      end
    end
  end
end
