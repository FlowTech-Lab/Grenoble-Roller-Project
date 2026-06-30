# frozen_string_literal: true

require "rails_helper"

RSpec.describe Checkout do
  describe "associations" do
    it "belongs to user and optional payment, has many checkout_lines" do
      checkout = create(:checkout)
      expect(checkout.user).to be_present
      expect(checkout).to respond_to(:payment)
      expect(checkout.checkout_lines).to be_a(ActiveRecord::Associations::CollectionProxy)
    end
  end

  describe "validations" do
    it "validates total_cents equals subtotal_cents plus donation_cents" do
      checkout = build(:checkout, subtotal_cents: 1000, donation_cents: 200, total_cents: 1500)
      expect(checkout).not_to be_valid
      expect(checkout.errors[:total_cents]).to be_present

      checkout.total_cents = 1200
      expect(checkout).to be_valid
    end
  end

  describe "enum status" do
    it "defines pending processing paid failed abandoned" do
      expect(described_class.statuses.keys).to contain_exactly(
        "pending", "processing", "paid", "failed", "abandoned"
      )
    end
  end
end
