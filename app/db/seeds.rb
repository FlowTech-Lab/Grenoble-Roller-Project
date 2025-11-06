# db/seeds.rb

require "securerandom"

# 🧹 Nettoyage (dans l'ordre pour éviter les erreurs FK)
OrderItem.destroy_all
Order.destroy_all
Payment.destroy_all
VariantOptionValue.delete_all
OptionValue.delete_all
OptionType.delete_all
ProductVariant.delete_all
Product.delete_all
ProductCategory.delete_all
User.destroy_all
Role.destroy_all

puts "🌪️ Seed supprimé !"

# 🎭 Création des rôles (code/level conformes au schéma)
roles_seed = [
  { code: "USER",        name: "Utilisateur", level: 10 },
  { code: "REGISTERED",  name: "Inscrit",     level: 20 },
  { code: "INITIATION",  name: "Initiation",  level: 30 },
  { code: "ORGANIZER",   name: "Organisateur",level: 40 },
  { code: "MODERATOR",   name: "Modérateur",  level: 50 },
  { code: "ADMIN",       name: "Admin",       level: 60 },
  { code: "SUPERADMIN",  name: "Super Admin", level: 70 }
]

roles_seed.each do |attrs|
  Role.create!(attrs)
end

admin_role = Role.find_by!(code: "ADMIN")
user_role  = Role.find_by!(code: "USER")
superadmin_role = Role.find_by!(code: "SUPERADMIN")

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

# 👨‍💻 Florian (SUPERADMIN)
florian = User.create!(
  email: "T3rorX@hotmail.fr",
  password: "T3rorX123",
  password_confirmation: "T3rorX123",
  first_name: "Florian",
  last_name: "Astier",
  bio: "Développeur fullstack passionné par les nouvelles technologies",
  phone: "0652556832",
  role: superadmin_role
)
puts "👨‍💻 Utilisateur Florian (SUPERADMIN) créé !"

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


#On crée 4 paiements “manuels” : 1 stripe réussi / 1 paypal en attente / 1 stripe échoué / 1 mollie réussi
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

# On veut autant de paiements que de commandes (ici 5).
# Les paiements ajoutés ici sont “aléatoires”
TARGET_ORDERS = 5
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

# Chaque order dépend donc d’un paiement existant et d’un utilisateur.
# On récupère les 5 paiements les plus récents.

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

# 🛒 Création des OrderItems (APRÈS la création des variants)
#Création des catégories - Lucas
categories = [
  { name: "Rollers", slug: "rollers" },
  { name: "Protections", slug: "protections" },
  { name: "Accessoires", slug: "accessoires" }
].map { |attrs| ProductCategory.create!(attrs) 
}
puts "🖼️ Catégories créées!"

#Création produits test - Lucas
products = [
  {
    name: "Roller Quad Street 3000",
    slug: "roller-quad-street-3000",
    category: categories[0],
    description: "Un roller quad idéal pour le freestyle et les balades urbaines.",
    price_cents: 129_00,
    stock_qty: 10,
    currency: "EUR",
    is_active: true
  },
  {
    name: "Casque de protection ProX",
    slug: "casque-prox",
    category: categories[1],
    description: "Casque ultra-léger et certifié pour la pratique du roller.",
    price_cents: 45_00,
    stock_qty: 25,
    currency: "EUR",
    is_active: true
  },
  {
    name: "Sac de transport RollerBag 50L",
    slug: "sac-rollerbag-50l",
    category: categories[2],
    description: "Grand sac de transport renforcé, parfait pour tout ton équipement.",
    price_cents: 65_00,
    stock_qty: 15,
    currency: "EUR",
    is_active: true
  }
].map { |attrs| Product.create!(attrs) 
}

puts "🛼 Produits créés!"

#Création variants produits test - Lucas
variants = [
  # Variantes du roller quad
  {
    product: products[0],
    sku: "ROLL-STREET-37",
    price_cents: 129_00,
    stock_qty: 3,
    currency: "EUR",
    is_active: true
  },
  {
    product: products[0],
    sku: "ROLL-STREET-39",
    price_cents: 129_00,
    stock_qty: 4,
    currency: "EUR",
    is_active: true
  },
  {
    product: products[0],
    sku: "ROLL-STREET-41",
    price_cents: 129_00,
    stock_qty: 3,
    currency: "EUR",
    is_active: true
  },

  # Variantes du casque
  {
    product: products[1],
    sku: "CASQ-PROX-S",
    price_cents: 45_00,
    stock_qty: 10,
    currency: "EUR",
    is_active: true
  },
  {
    product: products[1],
    sku: "CASQ-PROX-M",
    price_cents: 45_00,
    stock_qty: 10,
    currency: "EUR",
    is_active: true
  },
  {
    product: products[1],
    sku: "CASQ-PROX-L",
    price_cents: 45_00,
    stock_qty: 5,
    currency: "EUR",
    is_active: true
  }
].map { |attrs| ProductVariant.create!(attrs) 
}
puts "🎨 Variants produits créés!"


puts "🎨 Création des types d'options..."
option_types = [
  { name: "size", presentation: "Taille" },
  { name: "color", presentation: "Couleur" }
].map { |attrs| OptionType.create!(attrs) 
}


puts "🎯 Création des valeurs d'options..."
sizes = [
  { option_type: option_types[0], value: "37", presentation: "Taille 37" },
  { option_type: option_types[0], value: "39", presentation: "Taille 39" },
  { option_type: option_types[0], value: "41", presentation: "Taille 41" }
].map { |attrs| OptionValue.create!(attrs) 
}

colors = [
  { option_type: option_types[1], value: "Red", presentation: "Rouge" },
  { option_type: option_types[1], value: "Blue", presentation: "Bleu" },
  { option_type: option_types[1], value: "Black", presentation: "Noir" }
].map { |attrs| OptionValue.create!(attrs) 
}


puts "🔗 Association des options aux variantes..."
# Exemple : les rollers ont des tailles, les casques ont des tailles aussi
ProductVariant.all.each do |variant|
  product = variant.product

  if product.name.include?("Roller")
    size_value = sizes.sample
    VariantOptionValue.create!(variant:, option_value: size_value)
  elsif product.name.include?("Casque")
    size_value = sizes.sample
    VariantOptionValue.create!(variant:, option_value: size_value)
  end
end

# 🛒 Création des OrderItems (APRÈS la création des variants)
puts "Création des articles de commande..."

orders = Order.all
variant_ids = ProductVariant.ids

if variant_ids.empty?
  puts "⚠️ Aucun variant trouvé, les OrderItems ne seront pas créés."
else
  orders.each do |order|
    rand(1..3).times do
      unit_price = rand(500..5000)
      quantity = rand(1..3)
      OrderItem.create!(
        order: order,
        variant_id: variant_ids.sample,
        quantity: quantity,
        unit_price_cents: unit_price,
        created_at: order.created_at + rand(0..3).hours
      )
    end
  end

  puts "✅ #{OrderItem.count} articles de commande créés avec succès."
end

puts "🌱 Seed terminé avec succès !"
