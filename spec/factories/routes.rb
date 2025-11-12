FactoryBot.define do
  factory :route do
    sequence(:name) { |n| "Route #{n}" }
    difficulty { 'easy' }
    distance_km { 12.5 }
    elevation_m { 150 }
    description { 'Boucle urbaine pour tous niveaux.' }
  end
end

