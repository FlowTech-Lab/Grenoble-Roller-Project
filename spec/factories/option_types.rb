# frozen_string_literal: true

FactoryBot.define do
  factory :option_type do
    name { 'size' }
  end

  trait :color do
    name { 'color' }
  end

  trait :size do
    name { 'size' }
  end
end

