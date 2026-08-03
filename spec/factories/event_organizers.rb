# frozen_string_literal: true

FactoryBot.define do
  factory :event_organizer do
    sequence(:name) { |n| "Association roller #{n}" }
    sequence(:url) { |n| "https://association#{n}.example.com" }
    is_active { true }

    trait :inactive do
      is_active { false }
    end
  end
end
