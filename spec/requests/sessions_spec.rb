# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user, password: "password12345") }

  before do
    allow_any_instance_of(SessionsController).to receive(:verify_turnstile).and_return(true)
  end

  describe "POST /users/sign_in" do
    it "signs in confirmed user and redirects to root" do
      post user_session_path, params: {
        user: { email: user.email, password: "password12345" },
        "cf-turnstile-response" => "test-token"
      }

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response).to have_http_status(:success)
    end
  end
end
