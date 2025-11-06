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

puts "🛼 Création des produits..."


puts "🎨 Création des types d'options..."
option_types = [
  { name: "size", presentation: "Taille" },
  { name: "color", presentation: "Couleur" }
].map { |attrs| OptionType.create!(attrs) 
}


puts "🎯 Création des valeurs d'options..."
# Tailles chaussures
shoe_sizes = [
  { option_type: option_types[0], value: "37", presentation: "Taille 37" },
  { option_type: option_types[0], value: "39", presentation: "Taille 39" },
  { option_type: option_types[0], value: "41", presentation: "Taille 41" }
].map { |attrs| OptionValue.create!(attrs) }

# Tailles textile
apparel_sizes = %w[S M L].map { |sz| OptionValue.create!(option_type: option_types[0], value: sz, presentation: "Taille #{sz}") }

# Couleurs
colors = [
  { option_type: option_types[1], value: "Red", presentation: "Rouge" },
  { option_type: option_types[1], value: "Blue", presentation: "Bleu" },
  { option_type: option_types[1], value: "Black", presentation: "Noir" },
  { option_type: option_types[1], value: "White", presentation: "Blanc" },
  { option_type: option_types[1], value: "Violet", presentation: "Violet" }
].map { |attrs| OptionValue.create!(attrs) }

# Références pour faciliter l'accès
color_black = OptionValue.find_by!(option_type: option_types[1], value: "Black")
color_blue = OptionValue.find_by!(option_type: option_types[1], value: "Blue")
color_white = OptionValue.find_by!(option_type: option_types[1], value: "White")
color_red = OptionValue.find_by!(option_type: option_types[1], value: "Red")
color_violet = OptionValue.find_by!(option_type: option_types[1], value: "Violet")


# ---------------------------
# 1. CASQUE LED - 3 tailles (S, M, L)
# ---------------------------
casque_led = Product.create!(
  name: "Casque LED Grenoble Roller",
  slug: "casque-led",
  category: categories[1],
  description: "Casque de protection avec éclairage LED intégré pour une visibilité optimale.",
  price_cents: 55_00,
  stock_qty: 0,
  currency: "EUR",
  is_active: true,
  image_url: "produits/casque led.png"
)

apparel_sizes.each do |size_ov|
  variant = ProductVariant.create!(
    product: casque_led,
    sku: "CASQ-LED-#{size_ov.value}",
    price_cents: 55_00,
    stock_qty: [5, 8, 3][apparel_sizes.index(size_ov)],
    currency: "EUR",
    is_active: true
  )
  VariantOptionValue.create!(variant:, option_value: size_ov)
end

# ---------------------------
# 2. CASQUETTE - Taille unique, blanche
# ---------------------------
casquette = Product.create!(
  name: "Casquette Grenoble Roller",
  slug: "casquette-grenoble-roller",
  category: categories[2],
  description: "Casquette blanche avec logo Grenoble Roller.",
  price_cents: 15_00,
  stock_qty: 20,
  currency: "EUR",
  is_active: true,
  image_url: "produits/casquette.png"
)

variant_casquette = ProductVariant.create!(
  product: casquette,
  sku: "CASQ-UNIQUE",
  price_cents: 15_00,
  stock_qty: 20,
  currency: "EUR",
  is_active: true
)
VariantOptionValue.create!(variant: variant_casquette, option_value: color_white)

# ---------------------------
# 3. SAC À DOS + ROLLER - 4 couleurs (noir/rouge/violet/bleu) - même image
# ---------------------------
sac_couleurs = [
  { color: color_black, name: "Sac à dos + Roller - Noir", slug: "sac-dos-roller-noir" },
  { color: color_red, name: "Sac à dos + Roller - Rouge", slug: "sac-dos-roller-rouge" },
  { color: color_violet, name: "Sac à dos + Roller - Violet", slug: "sac-dos-roller-violet" },
  { color: color_blue, name: "Sac à dos + Roller - Bleu", slug: "sac-dos-roller-bleu" }
]

sac_couleurs.each do |sac|
  product = Product.create!(
    name: sac[:name],
    slug: sac[:slug],
    category: categories[2],
    description: "Sac à dos pratique avec compartiment dédié pour transporter vos rollers.",
    price_cents: 45_00,
    stock_qty: 0,
    currency: "EUR",
    is_active: true,
    image_url: "produits/Sac a dos roller.png"
  )
  
  variant = ProductVariant.create!(
    product: product,
    sku: "SAC-DOS-#{sac[:color].value.upcase}",
    price_cents: 45_00,
    stock_qty: 10,
    currency: "EUR",
    is_active: true
  )
  VariantOptionValue.create!(variant:, option_value: sac[:color])
end

# ---------------------------
# 4. SAC ROLLER SIMPLE - Taille et couleur uniques
# ---------------------------
sac_simple = Product.create!(
  name: "Sac Roller Simple",
  slug: "sac-roller-simple",
  category: categories[2],
  description: "Sac simple et pratique pour transporter vos rollers.",
  price_cents: 25_00,
  stock_qty: 15,
  currency: "EUR",
  is_active: true,
  image_url: "produits/Sac roller simple.png"
)

variant_sac_simple = ProductVariant.create!(
  product: sac_simple,
  sku: "SAC-SIMPLE",
  price_cents: 25_00,
  stock_qty: 15,
  currency: "EUR",
  is_active: true
)

# ---------------------------
# 5. T-SHIRT - Clair et plusieurs tailles
# ---------------------------
tshirt = Product.create!(
  name: "T-shirt Grenoble Roller",
  slug: "tshirt-grenoble-roller",
  category: categories[2],
  description: "T-shirt clair confortable avec logo Grenoble Roller.",
  price_cents: 20_00,
  stock_qty: 0,
  currency: "EUR",
  is_active: true,
  image_url: "produits/tshirt.PNG"
)

apparel_sizes.each do |size_ov|
  variant = ProductVariant.create!(
    product: tshirt,
    sku: "TSHIRT-#{size_ov.value}",
    price_cents: 20_00,
    stock_qty: [8, 12, 6][apparel_sizes.index(size_ov)],
    currency: "EUR",
    is_active: true
  )
  VariantOptionValue.create!(variant:, option_value: size_ov)
end

# ---------------------------
# 6. VESTE - 3 couleurs (noir/bleu/blanc), plusieurs tailles, 3 images différentes
# ---------------------------
vestes = [
  { color: color_black, name: "Veste Grenoble Roller - Noir", slug: "veste-grenoble-roller-noir", image: "produits/veste noir.avif" },
  { color: color_blue, name: "Veste Grenoble Roller - Bleu", slug: "veste-grenoble-roller-bleu", image: "produits/veste bleu.avif" },
  { color: color_white, name: "Veste Grenoble Roller - Blanc", slug: "veste-grenoble-roller-blanc", image: "produits/veste.png" }
]

vestes.each do |v|
  product = Product.create!(
    name: v[:name],
    slug: v[:slug],
    category: categories[2],
    description: "Veste Grenoble Roller, coupe unisexe, confortable et résistante.",
    price_cents: 40_00,
    stock_qty: 0,
    currency: "EUR",
    is_active: true,
    image_url: v[:image]
  )

  apparel_sizes.each_with_index do |size_ov, idx|
    variant = ProductVariant.create!(
      product: product,
      sku: "VESTE-#{v[:color].value.upcase}-#{size_ov.value}",
      price_cents: 40_00,
      stock_qty: [5, 10, 7][idx],
      currency: "EUR",
      is_active: true
    )
    VariantOptionValue.create!(variant:, option_value: size_ov)
    VariantOptionValue.create!(variant:, option_value: v[:color])
  end
end

puts "✅ Produits créés avec leurs variantes et options !"

# Produit désactivé (pour tests)
disabled_product = Product.create!(
  name: "Gourde Grenoble Roller (désactivée)",
  slug: "gourde-gr-desactivee",
  category: categories[2],
  description: "Produit temporairement indisponible.",
  price_cents: 12_00,
  stock_qty: 0,
  currency: "EUR",
  is_active: false,
  image_url: "produits/Sac roller simple.png"
)
ProductVariant.create!(
  product: disabled_product,
  sku: "GOURDE-STD",
  price_cents: 12_00,
  stock_qty: 0,
  currency: "EUR",
  is_active: false
)

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
