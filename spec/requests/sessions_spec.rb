# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user, password: "password12345") }

  context "when UNIFIED_CART_ENABLED is true" do
    around do |example|
      previous = ENV["UNIFIED_CART_ENABLED"]
      ENV["UNIFIED_CART_ENABLED"] = "true"
      example.run
    ensure
      if previous.nil?
        ENV.delete("UNIFIED_CART_ENABLED")
      else
        ENV["UNIFIED_CART_ENABLED"] = previous
      end
    end

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
end
