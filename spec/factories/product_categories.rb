# frozen_string_literal: true

FactoryBot.define do
  factory :product_category do
    name { 'Rollers' }
    slug { "rollers-#{SecureRandom.hex(4)}" }
  end
end

