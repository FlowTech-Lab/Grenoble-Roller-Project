FactoryBot.define do
  factory :waitlist_entry do
    association :user
    association :event
    child_membership { nil }
    position { 1 }
    notified_at { nil }
    status { 'pending' }
    wants_reminder { false }
    needs_equipment { false }
    roller_size { nil }
    use_free_trial { false }

    trait :notified do
      status { 'notified' }
      notified_at { 1.hour.ago }
    end

    trait :converted do
      status { 'converted' }
      notified_at { 2.hours.ago }
    end

    trait :refused do
      status { 'refused' }
      notified_at { 1.hour.ago }
    end

    trait :cancelled do
      status { 'cancelled' }
    end

    trait :with_equipment do
      needs_equipment { true }
      roller_size { '38' }
    end

    trait :with_reminder do
      wants_reminder { true }
    end
  end
end
