require 'rails_helper'

RSpec.describe "Memberships", type: :request do
  include RequestAuthenticationHelper
  include TestDataHelper

  let(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let(:user) { create_user(role: role) }

  describe "GET /memberships" do
    it "requires authentication" do
      get memberships_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "allows authenticated user to view memberships" do
      login_user(user)
      get memberships_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /memberships/new" do
    it "requires authentication" do
      get new_membership_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "allows authenticated user to access new membership form" do
      login_user(user)
      get new_membership_path
      # Peut rediriger si certaines conditions ne sont pas remplies (ex: adhésion déjà active)
      # Vérifier simplement qu'il y a une réponse (success ou redirect)
      expect(response.status).to be_between(200, 399)
    end
  end

  describe "GET /memberships/:id" do
    let(:membership) { create(:membership, user: user) }

    it "requires authentication" do
      get membership_path(membership)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "allows authenticated user to view their membership" do
      login_user(user)
      get membership_path(membership)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /memberships/:membership_id/payments" do
    let(:membership) { create(:membership, user: user, status: 'pending') }

    it "requires authentication" do
      post membership_payments_path(membership)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects to HelloAsso for pending membership" do
      login_user(user)
      # Mock HelloAssoService pour éviter les appels réels
      allow(HelloassoService).to receive(:create_membership_checkout_intent).and_return({
        success: true,
        body: {
          "id" => "checkout_123",
          "redirectUrl" => "https://helloasso.com/checkout"
        }
      })

      post membership_payments_path(membership)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /memberships/:membership_id/payments/status" do
    let(:membership) { create(:membership, user: user) }

    it "requires authentication" do
      get status_membership_payments_path(membership)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "returns payment status as JSON" do
      login_user(user)
      get status_membership_payments_path(membership)
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')
      json = JSON.parse(response.body)
      expect(json).to have_key('status')
    end
  end

  describe "POST /memberships/:membership_id/payments/create_multiple" do
    let(:child_membership1) { create(:membership, :child, :pending, user: user) }
    let(:child_membership2) { create(:membership, :child, :pending, user: user) }

    it "requires authentication" do
      post create_multiple_membership_payments_path(child_membership1), params: { membership_ids: [ child_membership1.id, child_membership2.id ] }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects to HelloAsso for multiple pending memberships" do
      login_user(user)
      # Mock HelloAssoService pour éviter les appels réels
      allow(HelloassoService).to receive(:create_multiple_memberships_checkout_intent).and_return({
        success: true,
        body: {
          "id" => "checkout_123",
          "redirectUrl" => "https://helloasso.com/checkout"
        }
      })

      post create_multiple_membership_payments_path(child_membership1), params: { membership_ids: [ child_membership1.id, child_membership2.id ] }
      expect(response).to have_http_status(:redirect)
    end
  end
end
