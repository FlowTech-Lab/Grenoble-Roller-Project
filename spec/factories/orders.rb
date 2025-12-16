# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    association :user
    status { 'pending' }
    total_cents { 0 }
    currency { 'EUR' }
    payment { nil } # Optionnel

    trait :paid do
      status { 'paid' }
    end

    trait :cancelled do
      status { 'cancelled' }
    end

    trait :with_items do
      after(:create) do |order|
        # Créer un produit et variant pour les items
        category = ProductCategory.first || create(:product_category)
        product = create(:product, category: category)
        variant = create(:product_variant, product: product)
        
        # Créer un order_item
        create(:order_item, order: order, variant: variant, quantity: 1)
        
        # Mettre à jour le total
        order.update_column(:total_cents, order.order_items.sum { |item| item.unit_price_cents * item.quantity })
      end
    end
  end
end

