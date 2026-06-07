# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Unified cart UX", type: :request do
  include RequestAuthenticationHelper

  let(:role) { ensure_role(code: "USER", name: "Utilisateur", level: 10) }
  let!(:user) do
    u = build(:user, role: role)
    u.skip_confirmation!
    u.save!
    u
  end
  let!(:category) { create(:product_category) }
  let!(:product) { create(:product, category: category) }
  let!(:variant) { create(:product_variant, product: product, stock_qty: 10, is_active: true) }
  let(:organizer) { create_user(role: ensure_role(code: "ORGANIZER", name: "Organisateur", level: 40)) }

  around do |example|
    with_unified_cart_enabled { example.run }
  end

  it "shows expiring event warning on cart when under 5 minutes" do
    event = create_event(
      creator_user: organizer,
      status: "published",
      payment_required: true,
      price_cents: 500,
      max_participants: 20,
      start_at: 1.week.from_now
    )
    attendance = create(:attendance, user: user, event: event, status: :pending, payment_expires_at: 3.minutes.from_now)
    create(:cart_line, :event_registration, user: user, reference: attendance, expires_at: 3.minutes.from_now)
    login_user(user)

    get cart_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("expire bientôt")
    expect(response.body).to include("payez avant")
  end

  it "shows pending payment banner on mes sorties" do
    event = create_event(
      creator_user: organizer,
      status: "published",
      payment_required: true,
      price_cents: 500,
      max_participants: 20,
      start_at: 1.week.from_now
    )
    create(:attendance, user: user, event: event, status: :pending, payment_expires_at: 10.minutes.from_now)
    login_user(user)

    get attendances_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("En attente de paiement")
    expect(response.body).to include("Aller au panier")
  end

  it "shows empty state sections on cart" do
    login_user(user)

    get cart_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Votre panier est vide")
    expect(response.body).to include("Voir la boutique")
    expect(response.body).to include("Voir les événements")
    expect(response.body).to include("Adhérer")
  end
end
