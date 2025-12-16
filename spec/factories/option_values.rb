# frozen_string_literal: true

FactoryBot.define do
  factory :option_value do
    association :option_type
    value { 'Medium' }
  end

  trait :small_size do
    association :option_type, factory: [ :option_type, :size ]
    value { 'Small' }
  end

  trait :medium_size do
    association :option_type, factory: [ :option_type, :size ]
    value { 'Medium' }
  end

  trait :large_size do
    association :option_type, factory: [ :option_type, :size ]
    value { 'Large' }
  end

  trait :red_color do
    association :option_type, factory: [ :option_type, :color ]
    value { 'Red' }
  end

  trait :blue_color do
    association :option_type, factory: [ :option_type, :color ]
    value { 'Blue' }
  end
end
