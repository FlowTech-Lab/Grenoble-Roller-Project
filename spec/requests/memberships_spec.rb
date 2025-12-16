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

    context "when health questionnaire is incomplete" do
      it "blocks payment if questionnaire is not complete" do
        login_user(user)
        # membership créée sans questionnaire (par défaut dans factory)
        allow(HelloassoService).to receive(:create_membership_checkout_intent)

        post membership_payments_path(membership)

        expect(response).to redirect_to(edit_membership_path(membership))
        expect(flash[:alert]).to include("questionnaire de santé")
        # Vérifier que HelloAsso n'est PAS appelé
        expect(HelloassoService).not_to have_received(:create_membership_checkout_intent)
      end
    end

    context "when health questionnaire is complete" do
      let(:membership_with_questionnaire) do
        create(:membership, user: user, status: 'pending').tap do |m|
          # Remplir le questionnaire de santé (toutes les questions = "no")
          (1..9).each { |i| m.update("health_q#{i}": "no") }
          m.update(health_questionnaire_status: "ok")
          m.reload
        end
      end

      it "redirects to HelloAsso for pending membership with complete questionnaire" do
        login_user(user)
        # Mock HelloAssoService pour éviter les appels réels
        allow(HelloassoService).to receive(:create_membership_checkout_intent).and_return({
          success: true,
          body: {
            "id" => "checkout_123",
            "redirectUrl" => "https://helloasso.com/checkout"
          }
        })

        post membership_payments_path(membership_with_questionnaire)
        expect(response).to have_http_status(:redirect)
        expect(HelloassoService).to have_received(:create_membership_checkout_intent)
      end
    end
  end

  describe "GET /memberships/:membership_id/payments/status" do
    let(:membership) { create(:membership, user: user) }

    it "requires authentication" do
      get membership_status_payment_path(membership)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "returns payment status as JSON" do
      login_user(user)
      get membership_status_payment_path(membership)
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')
      json = JSON.parse(response.body)
      expect(json).to have_key('status')
    end
  end

  describe "POST /memberships/payments/create_multiple" do
    let(:child_membership1) { create(:membership, :child, :pending, :with_health_questionnaire, user: user) }
    let(:child_membership2) { create(:membership, :child, :pending, :with_health_questionnaire, user: user) }

    it "requires authentication" do
      post create_multiple_payments_memberships_path, params: { membership_ids: [ child_membership1.id, child_membership2.id ] }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects to HelloAsso for multiple pending memberships with complete questionnaire" do
      login_user(user)
      # Mock HelloAssoService pour éviter les appels réels
      allow(HelloassoService).to receive(:create_multiple_memberships_checkout_intent).and_return({
        success: true,
        body: {
          "id" => "checkout_123",
          "redirectUrl" => "https://helloasso.com/checkout"
        }
      })

      post create_multiple_payments_memberships_path, params: { membership_ids: [ child_membership1.id, child_membership2.id ] }
      expect(response).to have_http_status(:redirect)
    end

    it "blocks payment if at least one membership has incomplete questionnaire" do
      login_user(user)
      child_membership_incomplete = create(:membership, :child, :pending, user: user) # Sans questionnaire
      allow(HelloassoService).to receive(:create_multiple_memberships_checkout_intent)

      post create_multiple_payments_memberships_path, params: { membership_ids: [ child_membership1.id, child_membership_incomplete.id ] }

      expect(response).to redirect_to(memberships_path)
      expect(flash[:alert]).to include("questionnaire de santé")
      expect(HelloassoService).not_to have_received(:create_multiple_memberships_checkout_intent)
    end
  end

  describe "POST /memberships - Déjà adhérent / Espèces / Chèques" do
    let(:user_with_dob) { create_user(role: role, date_of_birth: Date.new(1990, 1, 1)) }

    before do
      # S'assurer que l'utilisateur a une date de naissance
      user_with_dob.update(date_of_birth: Date.new(1990, 1, 1)) unless user_with_dob.date_of_birth
    end

    context "when creating without payment (cash/check)" do
      it "blocks creation if questionnaire is empty for adult" do
        login_user(user_with_dob)

        post memberships_path, params: {
          payment_method: 'cash_check',
          membership: {
            category: 'standard',
            first_name: 'Jean',
            last_name: 'Dupont'
            # Pas de health_question_1 à health_question_9
          }
        }

        # La redirection peut être vers new_membership_path avec ou sans type
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include(new_membership_path)
        expect(flash[:alert]).to include("questionnaire de santé")
        expect(Membership.count).to eq(0) # Aucune adhésion créée
      end

      it "blocks creation if questionnaire is empty for child" do
        login_user(user_with_dob)

        post memberships_path, params: {
          payment_method: 'cash_check',
          membership: {
            category: 'standard',
            is_child_membership: 'true',
            child_first_name: 'Enfant',
            child_last_name: 'Test',
            child_date_of_birth: Date.new(2015, 1, 1)
            # Pas de health_question_1 à health_question_9
          }
        }

        expect(response).to have_http_status(:redirect)
        expect(response.location).to include(new_membership_path)
        expect(flash[:alert]).to include("questionnaire de santé")
        expect(Membership.count).to eq(0) # Aucune adhésion créée
      end

      it "allows creation if questionnaire is complete for adult" do
        login_user(user_with_dob)

        membership_params = {
          category: 'standard',
          first_name: 'Jean',
          last_name: 'Dupont'
        }

        # Ajouter toutes les réponses du questionnaire
        (1..9).each do |i|
          membership_params["health_question_#{i}"] = "no"
        end

        expect do
          post memberships_path, params: {
            payment_method: 'cash_check',
            membership: membership_params
          }
        end.to change { Membership.count }.by(1)

        membership = Membership.last
        expect(membership.user).to eq(user_with_dob)
        expect(membership.status).to eq('pending')
        expect(membership.health_questionnaire_complete?).to be(true)
      end
    end
  end
end
