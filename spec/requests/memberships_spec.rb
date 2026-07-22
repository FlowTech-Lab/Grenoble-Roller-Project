require 'rails_helper'

RSpec.describe "Memberships", type: :request do
  include RequestAuthenticationHelper
  include TestDataHelper
  include ActiveSupport::Testing::TimeHelpers

  let!(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
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

      it "adds membership to cart for pending membership with complete questionnaire" do
        login_user(user)

        post membership_payments_path(membership_with_questionnaire)

        expect(response).to redirect_to(cart_path)
        expect(CartLine.where(user: user, reference: membership_with_questionnaire)).to exist
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

        # Compter les adhésions avant la tentative
        initial_count = Membership.count

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
        # Aucune nouvelle adhésion créée
        expect(Membership.count).to eq(initial_count)
      end

      it "blocks creation if questionnaire is empty for child" do
        login_user(user_with_dob)

        # Compter les adhésions avant la tentative
        initial_count = Membership.count

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
        # Aucune nouvelle adhésion créée
        expect(Membership.count).to eq(initial_count)
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

  describe "POST /memberships/:id/renew - Renouvellement adhésion enfant" do
    let(:current_season) { Membership.sale_season_name }
    # Dates pour une adhésion expirée (saison 2023-2024, clairement expirée en décembre 2025)
    let(:old_start_date) { Date.new(2023, 9, 1) }
    let(:old_end_date) { Date.new(2024, 8, 31) }
    let(:expired_start_date) { old_start_date }
    let(:expired_end_date) { old_end_date }

    context "avec adhésion enfant expirée" do
      let(:expired_child_membership) do
        create(:membership,
          :child,
          :with_health_questionnaire,
          user: user,
          status: :expired,
          season: '2024-2025',
          start_date: expired_start_date,
          end_date: expired_end_date,
          child_first_name: 'Léa',
          child_last_name: 'Astier',
          child_date_of_birth: Date.new(2012, 7, 22),
          category: 'standard'
        )
      end

      it "redirige vers le formulaire de renouvellement avec les informations pré-remplies" do
        login_user(user)
        post renew_membership_path(expired_child_membership)

        expect(response).to redirect_to(new_membership_path(type: 'child', renew_from: expired_child_membership.id))
      end

      context "lorsque l'enfant a déjà une adhésion pour la saison courante" do
        let!(:current_child_membership) do
          create(:membership,
            :child,
            :with_health_questionnaire,
            user: user,
            status: :active,
            season: current_season,
            child_first_name: 'Léa',
            child_last_name: 'Astier',
            child_date_of_birth: Date.new(2012, 7, 22),
            category: 'standard'
          )
        end

        it "bloque le renouvellement et redirige vers l'adhésion existante" do
          login_user(user)
          # S'assurer que les deux adhésions existent avant de compter (expired + current saison)
          expired_child_membership.id
          current_child_membership.id

          expect do
            post memberships_path, params: {
              renew_from: expired_child_membership.id,
              membership: {
                category: 'standard',
                is_child_membership: 'true',
                child_first_name: expired_child_membership.child_first_name,
                child_last_name: expired_child_membership.child_last_name,
                child_date_of_birth: expired_child_membership.child_date_of_birth
              }
            }
          end.not_to change(Membership, :count)

          expect(response).to redirect_to(membership_path(current_child_membership))
          expect(flash[:notice]).to include("Une adhésion existe déjà")
        end
      end

      context "lors de la soumission du formulaire de renouvellement" do
        it "crée une nouvelle adhésion avec les informations de l'ancienne" do
          login_user(user)
          # Simuler le formulaire de renouvellement avec choix de catégorie
          membership_params = {
            category: 'standard',
            is_child_membership: 'true',
            child_first_name: expired_child_membership.child_first_name,
            child_last_name: expired_child_membership.child_last_name,
            child_date_of_birth: expired_child_membership.child_date_of_birth,
            parent_authorization: '1',
            rgpd_consent: '1',
            legal_notices_accepted: '1'
          }

          # Ajouter les réponses du questionnaire de santé
          (1..9).each do |i|
            membership_params["health_question_#{i}"] = "no"
          end

          expect do
            post memberships_path, params: {
              renew_from: expired_child_membership.id,
              membership: membership_params
            }
          end.to change { Membership.count }.by(1)

          new_membership = Membership.last
          expect(new_membership.status).to eq('pending')
          expect(new_membership.season).to eq(current_season)
          expect(new_membership.child_first_name).to eq(expired_child_membership.child_first_name)
          expect(new_membership.child_last_name).to eq(expired_child_membership.child_last_name)
          expect(new_membership.category).to eq('standard')
        end

        it "permet de changer de catégorie lors du renouvellement" do
          login_user(user)
          membership_params = {
            category: 'with_ffrs', # Changement de catégorie
            is_child_membership: 'true',
            child_first_name: expired_child_membership.child_first_name,
            child_last_name: expired_child_membership.child_last_name,
            child_date_of_birth: expired_child_membership.child_date_of_birth,
            parent_authorization: '1',
            rgpd_consent: '1',
            legal_notices_accepted: '1',
            ffrs_data_sharing_consent: '1'
          }

          (1..9).each do |i|
            membership_params["health_question_#{i}"] = "no"
          end

          post memberships_path, params: {
            renew_from: expired_child_membership.id,
            membership: membership_params
          }

          new_membership = Membership.last
          expect(new_membership.category).to eq('with_ffrs')
          expect(new_membership.amount_cents).to eq(5655) # Prix FFRS
        end
      end

      context "si l'enfant a maintenant 18 ans ou plus" do
        let(:expired_child_membership_18) do
          create(:membership,
            :child,
            :with_health_questionnaire,
            user: user,
            status: :expired,
            season: '2024-2025',
            start_date: expired_start_date,
            end_date: expired_end_date,
            child_first_name: 'Adulte',
            child_last_name: 'Test',
            child_date_of_birth: Date.new(2000, 1, 1),
            category: 'standard'
          )
        end

        it "bloque le renouvellement et affiche un message d'erreur" do
          login_user(user)

          # S'assurer que l'enfant a bien 18 ans ou plus
          expect(expired_child_membership_18.child_age).to be >= 18

          expect do
            post memberships_path, params: {
              renew_from: expired_child_membership_18.id,
              membership: {
                category: 'standard',
                is_child_membership: 'true',
                child_first_name: expired_child_membership_18.child_first_name,
                child_last_name: expired_child_membership_18.child_last_name,
                child_date_of_birth: expired_child_membership_18.child_date_of_birth,
                # Ajouter les réponses du questionnaire (nécessaires pour que la création passe normalement)
                health_question_1: 'no',
                health_question_2: 'no',
                health_question_3: 'no',
                health_question_4: 'no',
                health_question_5: 'no',
                health_question_6: 'no',
                health_question_7: 'no',
                health_question_8: 'no',
                health_question_9: 'no',
                parent_authorization: '1',
                rgpd_consent: '1',
                legal_notices_accepted: '1'
              }
            }
          end.not_to change { Membership.count }

          expect(response).to redirect_to(memberships_path)
          expect(flash[:alert]).to include("18 ans ou plus")
        end
      end
    end
  end

  describe "POST /memberships/:id/upgrade - Conversion essai gratuit en adhésion payante" do
    let(:trial_membership) do
      create(:membership,
        :child,
        :with_health_questionnaire,
        user: user,
        status: :trial,
        season: Membership.sale_season_name,
        category: 'standard',
        amount_cents: 1000
      )
    end

    it "convertit l'essai gratuit en adhésion pending" do
      login_user(user)

      patch upgrade_membership_path(trial_membership)

      trial_membership.reload
      expect(trial_membership.status).to eq('pending')
      expect(trial_membership.amount_cents).to eq(1000) # Montant déjà défini
      expect(response).to redirect_to(cart_path)
      expect(CartLine.where(user: user, reference: trial_membership)).to exist
    end

    context "si l'adhésion n'est pas un essai gratuit" do
      let(:active_membership) do
        create(:membership,
          :child,
          :with_health_questionnaire,
          user: user,
          status: :active,
          season: Membership.sale_season_name
        )
      end

      it "bloque la conversion" do
        login_user(user)

        patch upgrade_membership_path(active_membership)

        expect(response).to redirect_to(memberships_path)
        expect(flash[:alert]).to include("ne peut pas être convertie")
      end
    end
  end

  describe "GET /memberships - Affichage bouton Réadhérer" do
    let(:current_season) { Membership.sale_season_name }
    let(:expired_season) { '2024-2025' }

    context "avec adhésion enfant expirée sans adhésion courante" do
      let!(:expired_child_membership) do
        create(:membership,
          :child,
          user: user,
          status: :expired,
          season: expired_season,
          start_date: Date.new(2024, 9, 1),
          end_date: Date.new(2025, 8, 31),
          child_first_name: 'Léa',
          child_last_name: 'Astier',
          child_date_of_birth: Date.new(2012, 7, 22)
        )
      end

      it "affiche le bouton Réadhérer" do
        login_user(user)
        get memberships_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Réadhérer")
      end
    end

    context "avec adhésion enfant expirée ET adhésion courante" do
      let!(:expired_child_membership) do
        create(:membership,
          :child,
          user: user,
          status: :expired,
          season: expired_season,
          start_date: Date.new(2024, 9, 1),
          end_date: Date.new(2025, 8, 31),
          child_first_name: 'Léa',
          child_last_name: 'Astier',
          child_date_of_birth: Date.new(2012, 7, 22)
        )
      end

      let!(:current_child_membership) do
        create(:membership,
          :child,
          user: user,
          status: :active,
          season: current_season,
          child_first_name: 'Léa',
          child_last_name: 'Astier',
          child_date_of_birth: Date.new(2012, 7, 22)
        )
      end

      it "n'affiche PAS le bouton Réadhérer" do
        login_user(user)
        get memberships_path

        expect(response).to have_http_status(:success)
        # Vérifier que le bouton Réadhérer n'apparaît pas pour cette adhésion expirée
        # (il peut y avoir d'autres boutons Réadhérer pour d'autres enfants, mais pas pour celui-ci)
        expect(response.body).not_to match(/Réadhérer.*Léa Astier|Léa Astier.*Réadhérer/)
      end
    end
  end

  describe "GET /memberships/new?type=child - Affichage message essai gratuit" do
    # Profil parent complet requis pour GET new type=child (ensure_parent_profile_complete_for_child)
    let(:user_with_complete_profile) do
      create_user(
        first_name: 'Alex',
        last_name: 'Rider',
        phone: '0612345678',
        address: '1 rue Test',
        postal_code: '38000',
        city: 'Grenoble',
        date_of_birth: Date.new(1985, 5, 15)
      )
    end

    context "quand l'enfant a déjà utilisé son essai gratuit" do
      let(:trial_membership) do
        create(:membership,
          :child,
          :with_health_questionnaire,
          user: user_with_complete_profile,
          status: :trial,
          season: Membership.sale_season_name,
          child_first_name: 'Enfant',
          child_last_name: 'Test',
          child_date_of_birth: Date.new(2015, 1, 1)
        )
      end

      let!(:attendance_with_trial) do
        create(:attendance,
          user: user_with_complete_profile,
          child_membership_id: trial_membership.id,
          free_trial_used: true
        )
      end

      it "n'affiche PAS le message d'essai gratuit" do
        login_user(user_with_complete_profile)
        # Simuler un renouvellement avec @old_membership (expirée = end_date dans le passé)
        old_membership = create(:membership,
          :child,
          user: user_with_complete_profile,
          status: :expired,
          season: '2024-2025',
          start_date: Date.new(2024, 9, 1),
          end_date: Date.new(2025, 8, 31),
          child_first_name: trial_membership.child_first_name,
          child_last_name: trial_membership.child_last_name,
          child_date_of_birth: trial_membership.child_date_of_birth
        )

        get new_membership_path(type: 'child', renew_from: old_membership.id)

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include("Votre enfant a droit à un essai gratuit")
      end
    end

    context "quand l'enfant n'a pas encore utilisé son essai gratuit" do
      let(:trial_membership) do
        create(:membership,
          :child,
          :with_health_questionnaire,
          user: user_with_complete_profile,
          status: :trial,
          season: Membership.sale_season_name,
          child_first_name: 'Enfant',
          child_last_name: 'Nouveau',
          child_date_of_birth: Date.new(2016, 1, 1)
        )
      end

      it "affiche le message d'essai gratuit" do
        login_user(user_with_complete_profile)
        old_membership = create(:membership,
          :child,
          user: user_with_complete_profile,
          status: :expired,
          season: '2024-2025',
          start_date: Date.new(2024, 9, 1),
          end_date: Date.new(2025, 8, 31),
          child_first_name: trial_membership.child_first_name,
          child_last_name: trial_membership.child_last_name,
          child_date_of_birth: trial_membership.child_date_of_birth
        )

        get new_membership_path(type: 'child', renew_from: old_membership.id)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Votre enfant a droit à un essai gratuit")
      end
    end
  end

  describe "GET /memberships/:id/edit and PATCH /memberships/:id" do
    let(:child_dob) { Date.new(2015, 6, 15) }
    let(:pending_child) do
      create(:membership,
        :child,
        :pending,
        :with_health_questionnaire,
        user: user,
        child_first_name: "Léo",
        child_last_name: "Martin",
        child_date_of_birth: child_dob,
        category: "standard",
        rgpd_consent: true,
        legal_notices_accepted: true,
        parent_authorization: true
      )
    end

    def child_update_params(overrides = {})
      base = {
        category: "standard",
        child_first_name: "Léo",
        child_last_name: "Martin",
        child_date_of_birth: child_dob.to_s,
        child_date_of_birth_day: child_dob.day.to_s,
        child_date_of_birth_month: child_dob.month.to_s,
        child_date_of_birth_year: child_dob.year.to_s,
        parent_authorization: "1",
        rgpd_consent: "1",
        legal_notices_accepted: "1",
        ffrs_data_sharing_consent: "0"
      }
      (1..9).each { |i| base["health_question_#{i}"] = "no" }
      base.merge(overrides)
    end

    it "requires authentication for edit" do
      get edit_membership_path(pending_child)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "renders the full health questionnaire on edit" do
      login_user(user)
      get edit_membership_path(pending_child)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Q1 :")
      expect(response.body).to include("Q9 :")
      expect(response.body).not_to include('name="membership[has_health_issues]"')
    end

    it "updates a pending child membership when health answers are submitted" do
      login_user(user)

      patch membership_path(pending_child), params: {
        membership: child_update_params(child_first_name: "Léonie")
      }

      expect(response).to redirect_to(memberships_path)
      expect(flash[:notice]).to include("mise à jour")
      expect(pending_child.reload.child_first_name).to eq("Léonie")
      expect(pending_child.health_questionnaire_complete?).to be(true)
    end

    it "preserves existing health answers when they are omitted from the request" do
      login_user(user)
      params_without_health = child_update_params.except(*(1..9).map { |i| "health_question_#{i}" })

      patch membership_path(pending_child), params: { membership: params_without_health }

      expect(response).to redirect_to(memberships_path)
      expect(pending_child.reload.health_questionnaire_complete?).to be(true)
    end

    it "blocks update when health questionnaire was never completed" do
      login_user(user)
      incomplete_child = create(:membership, :child, :pending, user: user,
        child_first_name: "Noé",
        child_last_name: "Test",
        child_date_of_birth: child_dob,
        parent_authorization: true,
        rgpd_consent: true,
        legal_notices_accepted: true)

      patch membership_path(incomplete_child), params: {
        membership: child_update_params.except(*(1..9).map { |i| "health_question_#{i}" })
          .merge(child_first_name: "Noé", child_last_name: "Test")
      }

      expect(response).to redirect_to(edit_membership_path(incomplete_child))
      expect(flash[:alert]).to include("questionnaire de santé")
    end

    it "rejects edit for non-pending memberships" do
      login_user(user)
      active_child = create(:membership, :child, :with_health_questionnaire, user: user)

      get edit_membership_path(active_child)

      expect(response).to redirect_to(membership_path(active_child))
      expect(flash[:alert]).to include("ne peut pas être modifiée")
    end
  end

  describe "unified cart membership flows" do
    let(:user_with_dob) do
      create_user(
        role: role,
        date_of_birth: Date.new(1990, 1, 1),
        address: "1 rue Test",
        postal_code: "38000",
        city: "Grenoble",
        phone: "0612345678"
      )
    end

    def adult_membership_params
      params = {
        category: "standard",
        first_name: "Jean",
        last_name: "Dupont",
        date_of_birth: Date.new(1990, 1, 1),
        phone: "0612345678",
        address: "1 rue Test",
        postal_code: "38000",
        city: "Grenoble"
      }
      (1..9).each { |i| params["health_question_#{i}"] = "no" }
      params
    end

    describe "POST /memberships" do
      context "adult membership with online pay" do
        it "creates pending membership and cart line" do
          login_user(user_with_dob)
          expect do
            post memberships_path, params: { membership: adult_membership_params }
          end.to change(Membership, :count).by(1)
            .and change { user_with_dob.cart_lines.membership.count }.by(1)

          membership = Membership.last
          expect(membership.status).to eq("pending")
          expect(CartLineService.membership_in_cart?(user_with_dob, membership)).to be(true)
        end

        it "does not redirect to HelloAsso" do
          login_user(user_with_dob)
          allow(HelloassoService).to receive(:membership_checkout_redirect_url)

          post memberships_path, params: { membership: adult_membership_params }

          expect(response).to redirect_to(cart_path)
          expect(HelloassoService).not_to have_received(:membership_checkout_redirect_url)
        end

        it "redirects with adhesion added to cart flash" do
          login_user(user_with_dob)
          post memberships_path, params: { membership: adult_membership_params }
          expect(flash[:notice]).to include("Adhésion ajoutée au panier")
        end

        it "assigns sale season (not next season before 15 August)" do
          travel_to Date.new(2026, 6, 5) do
            login_user(user_with_dob)

            post memberships_path, params: { membership: adult_membership_params }

            membership = Membership.last
            expect(membership.season).to eq("2025-2026")
            expect(membership.start_date).to eq(Date.new(2025, 9, 1))
            expect(membership.end_date).to eq(Date.new(2026, 8, 31))
            line = user_with_dob.cart_lines.membership.find_by(reference: membership)
            expect(line.label).to include("2025-2026")
          end
        end
      end

      context "when health questionnaire is incomplete" do
        it "blocks add to cart at create or checkout validation" do
          login_user(user_with_dob)
          params = adult_membership_params.except(*((1..9).map { |i| "health_question_#{i}" }))
          expect do
            post memberships_path, params: { membership: params }
          end.not_to change { user_with_dob.cart_lines.membership.count }
          expect(response.location).to include(new_membership_path)
        end
      end

      context "multi-child" do
        it "creates one cart line per child membership" do
          login_user(user_with_dob)
          child_params_base = {
            category: "standard",
            is_child_membership: "true",
            parent_authorization: "1",
            rgpd_consent: "1",
            legal_notices_accepted: "1"
          }
          (1..9).each { |i| child_params_base["health_question_#{i}"] = "no" }

          child1 = child_params_base.merge(
            child_first_name: "Alice",
            child_last_name: "Test",
            child_date_of_birth: Date.new(2015, 3, 1)
          )
          child2 = child_params_base.merge(
            child_first_name: "Bob",
            child_last_name: "Test",
            child_date_of_birth: Date.new(2016, 5, 1)
          )

          post memberships_path, params: { membership: child1 }
          post memberships_path, params: { membership: child2 }

          expect(user_with_dob.cart_lines.membership.count).to eq(2)
        end
      end
    end

    describe "POST /memberships/create_without_payment" do
      it "does not create cart line for cash/check path" do
        login_user(user_with_dob)
        expect do
          post memberships_path, params: {
            payment_method: "cash_check",
            membership: adult_membership_params
          }
        end.to change(Membership, :count).by(1)
          .and change { user_with_dob.cart_lines.membership.count }.by(0)
      end
    end

    describe "PATCH /memberships/:id/upgrade" do
      let(:trial_membership) do
        create(:membership,
          :child,
          :with_health_questionnaire,
          user: user_with_dob,
          status: :trial,
          season: Membership.sale_season_name,
          category: "standard",
          amount_cents: 1000)
      end

      it "converts trial to pending and adds membership to cart" do
        login_user(user_with_dob)

        patch upgrade_membership_path(trial_membership)

        trial_membership.reload
        expect(trial_membership.status).to eq("pending")
        expect(response).to redirect_to(cart_path)
        expect(CartLineService.membership_in_cart?(user_with_dob, trial_membership)).to be(true)
      end
    end
  end
end
