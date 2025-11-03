# db/seeds.rb

# Nettoyage
User.destroy_all
Role.destroy_all
puts "🌪️ Seed supprimé !"

# Création des rôles
admin_role = Role.create!(name: "admin")
user_role = Role.create!(name: "user")
puts "✅ #{Role.count} rôles créés avec succès !"

# Création de l'admin principal
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
puts "👑 Admin créé !"

# Création de Johanna (user)
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
puts "👩‍💻 Utilisatrice Johanna créée !"

# Création de Florian (autre admin)
florian = User.create!(
  email: "T3rorX@gmail.com",
  password: "T3rorX123",
  password_confirmation: "T3rorX123",
  first_name: "Florian",
  last_name: "Astier",
  bio: "Développeur fullstack passionné par les nouvelles technologies",
  phone: "0652556832",
  role: admin_role
)
puts "👨‍💻 Utilisateur Florian créé !"

# Création d’utilisateurs de test
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
  puts "👤 Utilisateur client #{i + 1} créé !"
end

puts "🌱 Seed terminé avec succès !"
