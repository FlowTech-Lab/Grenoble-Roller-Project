# db/seeds_production.rb
# Seed minimaliste pour la production
# Contient uniquement les données essentielles : rôles + compte superadmin

# Désactiver l'envoi d'emails pendant le seed (évite erreurs SMTP)
ActionMailer::Base.perform_deliveries = false
ActionMailer::Base.delivery_method = :test

# Désactiver temporairement le callback d'envoi d'email
User.skip_callback(:create, :after, :send_welcome_email_and_confirmation)

puts "🌱 Seed production - Données minimales essentielles"
puts ""

# 🎭 Création des rôles (OBLIGATOIRE - User.belongs_to :role)
puts "📋 Création des rôles..."
roles_seed = [
  { code: "USER",        name: "Utilisateur", level: 10 },
  { code: "REGISTERED",  name: "Inscrit",     level: 20 },
  { code: "INITIATION",  name: "Initiation",  level: 30 },
  { code: "ORGANIZER",   name: "Organisateur", level: 40 },
  { code: "MODERATOR",   name: "Modérateur",  level: 50 },
  { code: "ADMIN",       name: "Admin",       level: 60 },
  { code: "SUPERADMIN",  name: "Super Admin", level: 70 }
]

roles_seed.each do |attrs|
  Role.find_or_create_by!(code: attrs[:code]) do |role|
    role.assign_attributes(attrs)
  end
end

puts "✅ #{Role.count} rôles créés/vérifiés"

# 👨‍💻 Compte SuperAdmin (OBLIGATOIRE - pour administrer le site)
puts ""
puts "👤 Création du compte SuperAdmin..."

superadmin_role = Role.find_by!(code: "SUPERADMIN")

superadmin = User.find_or_create_by!(email: "T3rorX@hotmail.fr") do |user|
  user.password = "T3rorX12345678"  # Minimum 12 caractères requis
  user.password_confirmation = "T3rorX12345678"
  user.first_name = "Florian"
  user.last_name = "Astier"
  user.bio = "Développeur fullstack passionné par les nouvelles technologies"
  user.phone = "0652556832"
  user.role = superadmin_role
  user.skill_level = "advanced"
  user.confirmed_at = Time.now
end

# Si l'utilisateur existe déjà, s'assurer qu'il a le bon rôle
unless superadmin.role.code == "SUPERADMIN"
  superadmin.update!(role: superadmin_role)
  puts "  ⚠️  Rôle mis à jour vers SUPERADMIN"
end

superadmin.skip_confirmation_notification!
superadmin.save!

puts "✅ Compte SuperAdmin créé/vérifié"
puts "   📧 Email: #{superadmin.email}"
puts "   🆔 ID: #{superadmin.id}"
puts "   🔑 Rôle: #{superadmin.role.code}"

# Réactiver le callback d'envoi d'email
User.set_callback(:create, :after, :send_welcome_email_and_confirmation)

# Réactiver l'envoi d'emails
ActionMailer::Base.perform_deliveries = true

puts ""
puts "✅ Seed production terminé avec succès !"
puts "   - Rôles : #{Role.count}"
puts "   - Utilisateurs : #{User.count}"
