FactoryBot.define do
  factory :waitlist_entry do
    user { nil }
    event { nil }
    child_membership { nil }
    position { 1 }
    notified_at { "2025-12-12 15:52:17" }
    status { "MyString" }
  end
end
