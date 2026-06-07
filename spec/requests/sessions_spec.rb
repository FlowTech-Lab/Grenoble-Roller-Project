# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user, password: "password12345") }
  let(:category) { create(:product_category) }
  let(:product) { create(:product, category: category) }
  let(:variant) do
    create(:product_variant, product: product, stock_qty: 10, price_cents: 2000, is_active: true).tap do |v|
      v.inventory || Inventory.create!(product_variant: v, stock_qty: 10, reserved_qty: 0)
    end
  end

  context "when UNIFIED_CART_ENABLED is true" do
    around do |example|
      previous = ENV["UNIFIED_CART_ENABLED"]
      ENV["UNIFIED_CART_ENABLED"] = "true"
      example.run
    ensure
      ENV["UNIFIED_CART_ENABLED"] = previous
    end

    before do
      allow_any_instance_of(SessionsController).to receive(:verify_turnstile).and_return(true)
    end

    describe "POST /users/sign_in" do
      it "merges session cart into DB cart on sign in" do
        post add_item_cart_path, params: { variant_id: variant.id, quantity: 2 }
        expect(session[:cart][variant.id.to_s]).to eq(2)

        post user_session_path, params: {
          user: { email: user.email, password: "password12345" }
        }

        expect(response).to redirect_to(root_path)
        line = CartLine.find_by(user: user, reference: variant)
        expect(line).to be_present
        expect(line.quantity).to eq(2)
        expect(session[:cart]).to eq({})
      end
    end
  end
end
