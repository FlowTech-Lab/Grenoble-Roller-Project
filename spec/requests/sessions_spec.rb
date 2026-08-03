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

    it "returns to the stored membership renewal URL after login" do
      renewal_path = new_membership_path(type: "adult", renew_from: 42)

      get renewal_path
      expect(response).to redirect_to(new_user_session_path)

      post user_session_path, params: {
        user: { email: user.email, password: "password12345" },
        "cf-turnstile-response" => "test-token"
      }

      expect(response).to redirect_to(renewal_path)
    end
  end

  describe "GET /users/sign_in" do
    it "shows a renewal hint when returning from a membership URL" do
      get new_membership_path(type: "adult", renew_from: 42)
      follow_redirect!

      expect(response.body).to include("Connectez-vous pour renouveler votre adhésion")
    end
  end
end
