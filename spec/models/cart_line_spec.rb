# frozen_string_literal: true

require "rails_helper"

RSpec.describe CartLine do
  describe "associations" do
    it "belongs to user" do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it "belongs to reference" do
      expect(described_class.reflect_on_association(:reference).macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "requires label" do
      line = build(:cart_line, label: nil)
      expect(line).not_to be_valid
      expect(line.errors[:label]).to be_present
    end

    it "requires non-negative amount_cents" do
      line = build(:cart_line, amount_cents: -1)
      expect(line).not_to be_valid
      expect(line.errors[:amount_cents]).to be_present
    end

    it "requires quantity at least 1" do
      line = build(:cart_line, quantity: 0)
      expect(line).not_to be_valid
      expect(line.errors[:quantity]).to be_present
    end

    it "prevents duplicate product_variant line for same user and variant" do
      user = create(:user)
      variant = create(:product_variant, is_active: true)
      create(:cart_line, user: user, reference: variant, line_type: :product_variant)

      duplicate = build(:cart_line, user: user, reference: variant, line_type: :product_variant)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:reference_id]).to be_present
    end
  end

  describe "#expired?" do
    context "when expires_at is in the past" do
      it "returns true" do
        line = build(:cart_line, expires_at: 1.minute.ago)
        expect(line.expired?).to be(true)
      end
    end

    context "when expires_at is nil" do
      it "returns false" do
        line = build(:cart_line, expires_at: nil)
        expect(line.expired?).to be(false)
      end
    end

    context "when expires_at is in the future" do
      it "returns false" do
        line = build(:cart_line, expires_at: 10.minutes.from_now)
        expect(line.expired?).to be(false)
      end
    end
  end

  describe "#subtotal_cents" do
    it "returns amount_cents multiplied by quantity" do
      line = build(:cart_line, amount_cents: 1500, quantity: 3)
      expect(line.subtotal_cents).to eq(4500)
    end
  end

  describe "scopes" do
    describe ".active" do
      it "excludes expired lines" do
        user = create(:user)
        active_line = create(:cart_line, user: user, expires_at: 10.minutes.from_now)
        create(:cart_line, user: user, expires_at: 1.minute.ago)

        expect(described_class.active).to contain_exactly(active_line)
      end
    end
  end
end
