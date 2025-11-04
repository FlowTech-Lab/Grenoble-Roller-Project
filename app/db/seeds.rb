# db/seeds.rb

require "securerandom"

# 🧹 Nettoyage (dans l'ordre pour éviter les erreurs FK)
Order.destroy_all
Payment.destroy_all
User.destroy_all
Role.destroy_all
puts "🌪️ Seed supprimé !"

# 🎭 Création des rôles
admin_role = Role.create!(name: "admin")
user_role  = Role.create!(name: "user")
puts "✅ #{Role.count} rôles créés avec succès !"

# 👑 Admin principal
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

# 👩‍💻 Johanna
User.create!(
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

# 👨‍💻 Florian
User.create!(
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

# 👥 Utilisateurs de test
5.times do |i|
  User.create!(
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

# 💸 Paiements
puts "🧾 Création des paiements..."

payments_data = [
  {
    provider: "stripe",
    provider_payment_id: "pi_#{SecureRandom.hex(6)}",
    amount_cents: 2500,
    currency: "EUR",
    status: "succeeded",
    created_at: Time.now - 3.days
  },
  {
    provider: "paypal",
    provider_payment_id: "pay_#{SecureRandom.hex(6)}",
    amount_cents: 4999,
    currency: "EUR",
    status: "pending",
    created_at: Time.now - 2.days
  },
  {
    provider: "stripe",
    provider_payment_id: "pi_#{SecureRandom.hex(6)}",
    amount_cents: 1500,
    currency: "EUR",
    status: "failed",
    created_at: Time.now - 1.day
  },
  {
    provider: "mollie",
    provider_payment_id: "mol_#{SecureRandom.hex(6)}",
    amount_cents: 10000,
    currency: "EUR",
    status: "succeeded",
    created_at: Time.now
  }
]

payments_data.each { |attrs| Payment.create!(attrs) }
puts "✅ #{Payment.count} paiements créés !"

# on complète jusqu’à 20 paiements
TARGET_ORDERS = 20
if Payment.count < TARGET_ORDERS
  (TARGET_ORDERS - Payment.count).times do
    Payment.create!(
      provider: %w[stripe paypal mollie].sample,
      provider_payment_id: "gen_#{SecureRandom.hex(6)}",
      amount_cents: [1500, 2500, 4999, 10000, 1299, 7999].sample,
      currency: "EUR",
      status: %w[succeeded pending failed].sample,
      created_at: Time.now - rand(0..5).days
    )
  end
  puts "➕ Paiements complétés à #{Payment.count}"
end

# 🧾 Commandes
puts "Création des commandes..."
users = User.all
payments = Payment.order(:created_at).limit(TARGET_ORDERS)

if users.empty?
  puts "⚠️ Aucun user trouvé, crée d'abord des utilisateurs avant de seed les orders."
else
  payments.each do |pay|
    order_status =
      case pay.status
      when "succeeded" then %w[paid shipped].sample
      when "pending"   then "pending"
      else "cancelled"
      end

    Order.create!(
      user: users.sample,
      payment: pay,
      status: order_status,
      total_cents: pay.amount_cents,
      currency: pay.currency,
      created_at: pay.created_at + rand(0..6).hours,
      updated_at: Time.now
    )
  end

  puts "✅ #{payments.size} commandes créées avec succès."
end

puts "🌱 Seed terminé avec succès !"
