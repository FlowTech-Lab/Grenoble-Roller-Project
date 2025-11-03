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
puts "Admin crée !"

user = User.create!(
  email: "johannadelfieux@gmail.com",
  password: "jobee123", 
  password_confirmation: "jobee123",
  first_name: "Johanna",
  last_name: "Delfieux",
  bio: "Développeur fullstack passionné par les nouvelles technologies",
  phone: "0686699836",
  role: user_role,
  created_at: Time.now,
  updated_at: Time.now
)
puts "Utilisateur Johanna crée !"

user = User.create!(
  email: "T3rorX@gmail.com",
  password: "T3rorX123", 
  password_confirmation: "T3rorX123",
  first_name: "florian",
  last_name: "Astier",
  bio: "Développeur fullstack passionné par les nouvelles technologies",
  phone: "0652556832",
  role: admin_role,
  created_at: Time.now,
  updated_at: Time.now
)
puts "Utilisateur Florian crée !"
