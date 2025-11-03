# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
User.destroy_all
Role.destroy_all
puts "Seed Supprimé !"

admin_role = Role.create!(name: "admin")
user_role = Role.create!(name: "user")

puts "✅ #{Role.count} rôles créés avec succès !"

admin = User.create!(
  email: "admin@roller.com",
  password: "admin123",
  password_confirmation: "admin123",
  first_name: "Admin",
  last_name: "Roller",
  bio: "Administrateur du site Grenoble Roller",
  phone: "0698765432",
  role: admin_role
)

johanna = User.create!(
  email: "johannadelfieux@gmail.com",
  password: "jobee123", 
  password_confirmation: "jobee123",
  first_name: "Johanna",
  last_name: "Delfieux",
  bio: "Développeuse fullstack passionnée par les nouvelles technologies",
  phone: "0686699836",
  role: user_role 
)

5.times do |i|
  user = User.create!(
    email: "client#{i + 1}@example.com",
    password: "password123",
    password_confirmation: "password123",
    first_name: "Client",
    last_name: "Test #{i + 1}",
    bio: "Client de test numéro #{i + 1}",
    phone: "06#{rand(10000000..99999999)}",
    role: user_role,
    created_at: Time.now - rand(1..30).days,
    updated_at: Time.now
  )
end

puts "Admin crée !"
puts "Utilisateur Johanna crée !" 