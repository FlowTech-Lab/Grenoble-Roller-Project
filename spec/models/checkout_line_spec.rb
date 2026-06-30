# frozen_string_literal: true

require "rails_helper"

RSpec.describe CheckoutLine do
  let(:checkout) { create(:checkout) }

  it "stores immutable snapshot fields at creation" do
    variant = create(:product_variant)
    line = create(
      :checkout_line,
      checkout: checkout,
      line_type: :product_variant,
      reference: variant,
      amount_cents: 2500,
      label: "Snapshot label",
      quantity: 2,
      metadata: { "sku" => "ABC" }
    )

    expect(line.amount_cents).to eq(2500)
    expect(line.label).to eq("Snapshot label")
    expect(line.quantity).to eq(2)
    expect(line.metadata["sku"]).to eq("ABC")
  end

  it "does not allow updates after checkout is paid" do
    paid_checkout = create(:checkout, :paid)
    membership = create(:membership, :pending, :with_health_questionnaire)
    line = create(:checkout_line, checkout: paid_checkout, line_type: :membership, reference: membership)

    expect(line.update(label: "Changed")).to be(false)
    expect(line.errors[:base]).to include("cannot modify checkout line after checkout is paid")
  end
end
