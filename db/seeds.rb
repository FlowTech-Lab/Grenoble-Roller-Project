# db/seeds.rb

require "securerandom"

# Désactiver l'envoi d'emails pendant le seed (évite erreurs SMTP)
ActionMailer::Base.perform_deliveries = false
ActionMailer::Base.delivery_method = :test

# Désactiver temporairement le callback d'envoi d'email pour tout le seed
User.skip_callback(:create, :after, :send_welcome_email_and_confirmation)

# 🧹 Nettoyage (dans l'ordre pour éviter les erreurs FK)
# Phase 2 - Events
Attendance.destroy_all
Event.destroy_all
Route.destroy_all
OrganizerApplication.destroy_all
AuditLog.destroy_all
ContactMessage.destroy_all
Partner.destroy_all
# Phase 1 - E-commerce
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
  { code: "ORGANIZER",   name: "Organisateur", level: 40 },
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
admin = User.new(
  email: "admin@roller.com",
  password: "admin12345678",  # Minimum 12 caractères requis
  password_confirmation: "admin12345678",
  first_name: "Admin",
  last_name: "Roller",
  bio: "Administrateur du site Grenoble Roller",
  phone: "0698765432",
  role: admin_role,
  skill_level: "advanced",
  confirmed_at: Time.now  # Confirmation automatique pour admin
)
admin.skip_confirmation_notification!
admin.save!
puts "👑 Admin créé !"

# 👨‍💻 Florian (SUPERADMIN)
florian = User.new(
  email: "T3rorX@hotmail.fr",
  password: "T3rorX12345678",  # Minimum 12 caractères requis
  password_confirmation: "T3rorX12345678",
  first_name: "Florian",
  last_name: "Astier",
  bio: "Développeur fullstack passionné par les nouvelles technologies",
  phone: "0652556832",
  role: superadmin_role,
  skill_level: "advanced",
  confirmed_at: Time.now  # Confirmation automatique pour superadmin
)
florian.skip_confirmation_notification!
florian.save!
# Recharger pour s'assurer qu'il est bien en base
florian.reload
puts "👨‍💻 Utilisateur Florian (SUPERADMIN) créé !"
puts "   📧 Email: #{florian.email}"
puts "   🆔 ID: #{florian.id}"

# 👥 Utilisateurs de test
skill_levels = [ "beginner", "intermediate", "advanced" ]
20.times do |i|
  confirmed = rand > 0.2  # 80% des utilisateurs confirmés
  user = User.new(
    email: "client#{i + 1}@example.com",
    password: "password12345678",  # Minimum 12 caractères requis
    password_confirmation: "password12345678",
    first_name: [ "Alice", "Bob", "Charlie", "Diana", "Eve", "Frank", "Grace", "Henry", "Iris", "Jack", "Kate", "Leo", "Mia", "Noah", "Olivia", "Paul", "Quinn", "Ruby", "Sam", "Tina" ][i],
    last_name: [ "Martin", "Bernard", "Dubois", "Thomas", "Robert", "Petit", "Durand", "Leroy", "Moreau", "Simon", "Laurent", "Lefebvre", "Michel", "Garcia", "David", "Bertrand", "Roux", "Vincent", "Fournier", "Morel" ][i],
    bio: "Membre passionné de la communauté roller grenobloise",
    phone: "06#{rand(10000000..99999999)}",
    role: user_role,
    skill_level: skill_levels.sample,
    confirmed_at: confirmed ? (Time.now - rand(0..7).days) : nil,  # Confirmation à des dates variées
    created_at: Time.now - rand(1..30).days,
    updated_at: Time.now
  )
  user.skip_confirmation_notification!
  user.save!
  puts "👤 Utilisateur client #{i + 1} créé !"
end

# 💸 Paiements
puts "🧾 Création des paiements..."


# On crée 4 paiements “manuels” : 1 stripe réussi / 1 paypal en attente / 1 stripe échoué / 1 mollie réussi
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
      amount_cents: [ 1500, 2500, 4999, 10000, 1299, 7999 ].sample,
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
      donation_cents: rand(0..500),  # Don optionnelle entre 0 et 5€
      created_at: pay.created_at + rand(0..6).hours,
      updated_at: Time.now
    )
  end

  puts "✅ #{payments.size} commandes créées avec succès."
end

# 🛒 Création des OrderItems (APRÈS la création des variants)
# Création des catégories - Lucas
categories = [
  { name: "Rollers", slug: "rollers" },
  { name: "Protections", slug: "protections" },
  { name: "Accessoires", slug: "accessoires" }
].map { |attrs| ProductCategory.create!(attrs) }
puts "🖼️ Catégories créées!"

puts "🛼 Création des produits..."


puts "🎨 Création des types d'options..."
option_types = [
  { name: "size", presentation: "Taille" },
  { name: "color", presentation: "Couleur" }
].map { |attrs| OptionType.create!(attrs) }


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
    stock_qty: [ 5, 8, 3 ][apparel_sizes.index(size_ov)],
    currency: "EUR",
    is_active: true,
    image_url: casque_led.image_url
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
  is_active: true,
  image_url: casquette.image_url
)
VariantOptionValue.create!(variant: variant_casquette, option_value: color_white)

# ---------------------------
# 3. SAC À DOS + ROLLER - 1 produit, 4 variantes couleur
# ---------------------------
sac_roller = Product.create!(
  name: "Sac à dos + Roller",
  slug: "sac-dos-roller",
  category: categories[2],
  description: "Sac à dos pratique avec compartiment dédié pour transporter vos rollers.",
  price_cents: 45_00,
  stock_qty: 0,
  currency: "EUR",
  is_active: true,
  image_url: "produits/Sac a dos roller.png"
)

# Pour le sac à dos, on utilise l'image principale pour toutes les couleurs
# (pas d'images spécifiques par couleur disponibles)
[
  color_black,
  color_red,
  color_violet,
  color_blue
].each do |color_ov|
  variant = ProductVariant.create!(
    product: sac_roller,
    sku: "SAC-DOS-#{color_ov.value.upcase}",
    price_cents: 45_00,
    stock_qty: 10,
    currency: "EUR",
    is_active: true,
    image_url: sac_roller.image_url # Image principale pour toutes les couleurs
  )
  VariantOptionValue.create!(variant:, option_value: color_ov)
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
  is_active: true,
  image_url: sac_simple.image_url
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
    stock_qty: [ 8, 12, 6 ][apparel_sizes.index(size_ov)],
    currency: "EUR",
    is_active: true,
    image_url: tshirt.image_url
  )
  VariantOptionValue.create!(variant:, option_value: size_ov)
end

# ---------------------------
# 6. VESTE - 1 produit, 3 couleurs x plusieurs tailles
#    (1 image principale commune pour l'instant)
# ---------------------------
veste_product = Product.create!(
  name: "Veste Grenoble Roller",
  slug: "veste-grenoble-roller",
  category: categories[2],
  description: "Veste Grenoble Roller, coupe unisexe, confortable et résistante.",
  price_cents: 40_00,
  stock_qty: 0,
  currency: "EUR",
  is_active: true,
  image_url: "produits/veste.png"
)

# Mapping couleur -> image pour la veste (utilise les images .avif existantes)
veste_images = {
  "Black" => "produits/veste noir.avif",
  "Blue" => "produits/veste bleu.avif",
  "White" => "produits/veste.png" # Pas d'image spécifique pour blanc, utilise l'image principale
}

vestes_colors = [
  color_black,
  color_blue,
  color_white
]

vestes_colors.each do |color_ov|
  apparel_sizes.each_with_index do |size_ov, idx|
    variant = ProductVariant.create!(
      product: veste_product,
      sku: "VESTE-#{color_ov.value.upcase}-#{size_ov.value}",
      price_cents: 40_00,
      stock_qty: [ 5, 10, 7 ][idx],
      currency: "EUR",
      is_active: true,
      image_url: veste_images[color_ov.value] || veste_product.image_url
    )
    VariantOptionValue.create!(variant:, option_value: size_ov)
    VariantOptionValue.create!(variant:, option_value: color_ov)
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
  is_active: false,
  image_url: disabled_product.image_url
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

# ========================================
# 🌟 PHASE 2 - EVENTS & ADMIN
# ========================================

puts "\n🌟 Création des données Phase 2 (Events & Admin)..."

# 🗺️ Routes (parcours prédéfinis)
puts "🗺️ Création des routes..."
routes_data = [
  {
    name: "Boucle de la Bastille",
    description: "Parcours urbain avec vue panoramique sur Grenoble. Idéal pour débutants.",
    distance_km: 8.5,
    elevation_m: 120,
    difficulty: "easy",
    safety_notes: "Attention aux voitures dans les descentes. Port du casque obligatoire."
  },
  {
    name: "Tour du Vercors",
    description: "Randonnée longue distance à travers le massif du Vercors. Parcours technique.",
    distance_km: 45.0,
    elevation_m: 850,
    difficulty: "hard",
    safety_notes: "Parcours réservé aux skateurs confirmés. Vérifier la météo avant de partir."
  },
  {
    name: "Bord de l'Isère",
    description: "Parcours plat le long de l'Isère. Parfait pour l'entraînement.",
    distance_km: 12.0,
    elevation_m: 50,
    difficulty: "easy",
    safety_notes: "Piste cyclable partagée. Respecter les piétons."
  },
  {
    name: "Montée vers Chamrousse",
    description: "Ascension vers la station de ski. Défi pour les experts.",
    distance_km: 22.0,
    elevation_m: 1200,
    difficulty: "hard",
    safety_notes: "Route de montagne avec circulation. Équipement de sécurité recommandé."
  },
  {
    name: "Parcours du Polygone",
    description: "Parcours mixte entre ville et nature. Niveau intermédiaire.",
    distance_km: 15.5,
    elevation_m: 200,
    difficulty: "medium",
    safety_notes: "Quelques passages techniques. Vérifier l'état du terrain."
  }
]

routes = routes_data.map { |attrs| Route.create!(attrs) }
puts "✅ #{Route.count} routes créées !"

# 👥 Récupération des utilisateurs et rôles pour Phase 2
organizer_role = Role.find_by(code: "ORGANIZER")
admin_role = Role.find_by(code: "ADMIN")
users = User.all
florian = User.find_by(email: "T3rorX@hotmail.fr")
admin_user = User.find_by(email: "admin@roller.com")

# 🎪 Events (événements)
puts "🎪 Création des événements..."
# Helper pour mapper la difficulté de la route vers le niveau de l'événement
def map_route_difficulty_to_level(route)
  return 'all_levels' unless route

  case route.difficulty
  when 'easy'
    'beginner'
  when 'medium'
    'intermediate'
  when 'hard'
    'advanced'
  else
    'all_levels'
  end
end

events_data = [
  {
    creator_user: florian || admin_user,
    route: routes[0],
    status: "published",
    start_at: 1.week.from_now + 2.days,
    duration_min: 90,
    title: "Rando du vendredi soir - Boucle Bastille",
    description: "Randonnée conviviale du vendredi soir sur le parcours de la Bastille. Départ à 19h30, retour vers 21h. Niveau débutant accepté. N'oubliez pas vos protections !",
    price_cents: 0,
    currency: "EUR",
    location_text: "Place de la Bastille, Grenoble",
    meeting_lat: 45.1917,
    meeting_lng: 5.7278,
    cover_image_url: "events/bastille.jpg",
    level: map_route_difficulty_to_level(routes[0]),
    distance_km: routes[0]&.distance_km || 8.5,
    max_participants: 0
  },
  {
    creator_user: florian || admin_user,
    route: routes[1],
    status: "published",
    start_at: 2.weeks.from_now,
    duration_min: 240,
    title: "Challenge Vercors - Tour complet",
    description: "Événement exceptionnel : tour complet du Vercors en roller. Parcours de 45km avec dénivelé important. Réservé aux skateurs confirmés. Inscription obligatoire. Pique-nique prévu au retour.",
    price_cents: 1000,
    currency: "EUR",
    location_text: "Parking du Vercors, Villard-de-Lans",
    meeting_lat: 45.0736,
    meeting_lng: 5.5536,
    cover_image_url: "events/vercors.jpg",
    level: map_route_difficulty_to_level(routes[1]),
    distance_km: routes[1]&.distance_km || 45.0,
    max_participants: 20
  },
  {
    creator_user: admin_user || florian,
    route: routes[2],
    status: "published",
    start_at: 3.days.from_now,
    duration_min: 60,
    title: "Sortie détente - Bord de l'Isère",
    description: "Sortie détente le long de l'Isère. Parfait pour découvrir le roller ou se remettre en jambe. Tous niveaux bienvenus. Ambiance conviviale garantie !",
    price_cents: 0,
    currency: "EUR",
    location_text: "Parc Paul Mistral, Grenoble",
    meeting_lat: 45.1885,
    meeting_lng: 5.7245,
    cover_image_url: "events/isere.jpg",
    level: 'all_levels',
    distance_km: routes[2]&.distance_km || 12.0,
    max_participants: 0
  },
  {
    creator_user: florian || admin_user,
    route: routes[3],
    status: "draft",
    start_at: 1.month.from_now,
    duration_min: 180,
    title: "Montée Chamrousse - À venir",
    description: "Événement en préparation. Ascension vers Chamrousse pour les plus courageux. Détails à venir.",
    price_cents: 1500,
    currency: "EUR",
    location_text: "Départ Grenoble centre",
    meeting_lat: 45.1885,
    meeting_lng: 5.7245,
    cover_image_url: nil,
    level: map_route_difficulty_to_level(routes[3]),
    distance_km: routes[3]&.distance_km || 22.0,
    max_participants: 15
  },
  {
    creator_user: admin_user || florian,
    route: routes[4],
    status: "published",
    start_at: 5.days.from_now,
    duration_min: 120,
    title: "Rando Polygone - Niveau intermédiaire",
    description: "Randonnée sur le parcours du Polygone. Parfait pour les skateurs de niveau intermédiaire souhaitant progresser. Passage par des chemins variés avec quelques défis techniques.",
    price_cents: 500,
    currency: "EUR",
    location_text: "Parking Polygone, Grenoble",
    meeting_lat: 45.1789,
    meeting_lng: 5.7123,
    cover_image_url: "events/polygone.jpg",
    level: map_route_difficulty_to_level(routes[4]),
    distance_km: routes[4]&.distance_km || 15.5,
    max_participants: 0
  },
  {
    creator_user: florian || admin_user,
    route: routes[0],
    status: "published",
    start_at: 1.week.from_now + 5.days,
    duration_min: 90,
    title: "Rando du samedi matin - Bastille",
    description: "Randonnée populaire du samedi matin sur le parcours de la Bastille. Parfait pour commencer le week-end en douceur. Places limitées.",
    price_cents: 0,
    currency: "EUR",
    location_text: "Place de la Bastille, Grenoble",
    meeting_lat: 45.1917,
    meeting_lng: 5.7278,
    cover_image_url: "events/bastille.jpg",
    level: map_route_difficulty_to_level(routes[0]),
    distance_km: routes[0]&.distance_km || 8.5,
    max_participants: 10  # Limité à 10 participants pour créer un événement complet
  },
  {
    creator_user: florian || admin_user,
    route: routes[0],
    status: "canceled",
    start_at: 2.days.ago,
    duration_min: 90,
    title: "Rando annulée - Mauvais temps",
    description: "Événement annulé à cause des conditions météorologiques défavorables.",
    price_cents: 0,
    currency: "EUR",
    location_text: "Place de la Bastille, Grenoble",
    meeting_lat: 45.1917,
    meeting_lng: 5.7278,
    cover_image_url: nil,
    level: map_route_difficulty_to_level(routes[0]),
    distance_km: routes[0]&.distance_km || 8.5,
    max_participants: 0
  }
]

events = events_data.map { |attrs| Event.create!(attrs) }
puts "✅ #{Event.count} événements créés !"

# 📝 Attendances (inscriptions aux événements)
puts "📝 Création des inscriptions..."
published_events = Event.where(status: "published")
regular_users = users.where.not(email: [ "T3rorX@hotmail.fr", "admin@roller.com" ])

if published_events.any? && regular_users.any?
  published_events.each do |event|
    # Pour l'événement avec max_participants limité, on le remplit complètement
    if event.max_participants > 0 && event.max_participants <= regular_users.count
      # Inscrire exactement le nombre maximum de participants pour rendre l'événement complet
      subscribers = regular_users.sample(event.max_participants)
      subscribers.each do |user|
        Attendance.create!(
          user: user,
          event: event,
          status: event.price_cents > 0 ? "registered" : "registered",
          created_at: event.created_at + rand(1..5).hours
        )
      end
      puts "  ✅ Événement '#{event.title}' : #{event.max_participants} participants (COMPLET)"
    else
      # Pour les autres événements, inscription de quelques utilisateurs
      num_subscribers = (event.max_participants == 0) ? rand(3..8) : [ rand(2..6), event.max_participants ].min
      subscribers = regular_users.sample(num_subscribers)
      subscribers.each do |user|
        Attendance.create!(
          user: user,
          event: event,
          status: event.price_cents > 0 ? "registered" : "registered",
          created_at: event.created_at + rand(1..5).hours
        )
      end
    end
  end

  # Quelques inscriptions payées
  paid_event = published_events.find { |e| e.price_cents > 0 }
  if paid_event && regular_users.any?
    payment = Payment.where(status: "succeeded").first
    attendance = paid_event.attendances.first
    if attendance && payment
      attendance.update!(
        status: "paid",
        payment: payment
      )
    end
  end
end

puts "✅ #{Attendance.count} inscriptions créées !"

# 📋 OrganizerApplications (candidatures organisateur)
puts "📋 Création des candidatures organisateur..."
regular_users_for_apps = users.where.not(email: [ "T3rorX@hotmail.fr", "admin@roller.com" ]).where(role: user_role).limit(5)
if regular_users_for_apps.any? && (admin_user || florian)
  organizer_apps_data = [
    {
      user: regular_users_for_apps[0],
      motivation: "Passionné de roller depuis 10 ans, j'aimerais organiser des événements réguliers pour la communauté. J'ai de l'expérience dans l'organisation d'événements sportifs.",
      status: "pending"
    }
  ]

  # Ajouter une candidature approuvée si on a assez d'utilisateurs
  if regular_users_for_apps.count >= 2
    organizer_apps_data << {
      user: regular_users_for_apps[1],
      motivation: "Je souhaite devenir organisateur pour proposer des randos adaptées aux débutants et créer une communauté plus inclusive.",
      status: "approved",
      reviewed_by: admin_user || florian,
      reviewed_at: 1.week.ago
    }
  end

  # Ajouter une candidature rejetée si on a assez d'utilisateurs
  if regular_users_for_apps.count >= 3
    organizer_apps_data << {
      user: regular_users_for_apps[2],
      motivation: "Je veux organiser des événements mais je n'ai pas assez d'expérience.",
      status: "rejected",
      reviewed_by: admin_user || florian,
      reviewed_at: 3.days.ago
    }
  end

  organizer_apps_data.each { |attrs| OrganizerApplication.create!(attrs) }
  puts "✅ #{OrganizerApplication.count} candidatures créées !"
end

# 🤝 Partners (partenaires)
puts "🤝 Création des partenaires..."
partners_data = [
  {
    name: "Roller Shop Grenoble",
    url: "https://www.rollershop-grenoble.fr",
    logo_url: "partners/roller-shop.png",
    description: "Magasin spécialisé en rollers et équipements de protection à Grenoble.",
    is_active: true
  },
  {
    name: "Ville de Grenoble",
    url: "https://www.grenoble.fr",
    logo_url: "partners/ville-grenoble.png",
    description: "Partenariat avec la mairie de Grenoble pour l'organisation d'événements sportifs.",
    is_active: true
  },
  {
    name: "FFRS - Fédération Française de Roller et Skateboard",
    url: "https://www.ffroller.fr",
    logo_url: "partners/ffrs.png",
    description: "Fédération officielle du roller en France. Partenaire pour les licences et assurances.",
    is_active: true
  },
  {
    name: "Ancien Partenaire",
    url: "https://www.example.com",
    logo_url: nil,
    description: "Partenaire inactif (pour test).",
    is_active: false
  }
]

partners_data.each { |attrs| Partner.create!(attrs) }
puts "✅ #{Partner.count} partenaires créés !"

# 📧 ContactMessages (messages de contact)
puts "📧 Création des messages de contact..."
contact_messages_data = [
  {
    name: "Jean Dupont",
    email: "jean.dupont@example.com",
    subject: "Question sur les événements",
    message: "Bonjour, je souhaiterais savoir comment m'inscrire aux randos du vendredi soir. Merci !",
    created_at: 5.days.ago
  },
  {
    name: "Marie Martin",
    email: "marie.martin@example.com",
    subject: "Devenir membre",
    message: "Bonjour, j'aimerais devenir membre de l'association. Pouvez-vous me renseigner sur les tarifs et les démarches ?",
    created_at: 3.days.ago
  },
  {
    name: "Pierre Durand",
    email: "pierre.durand@example.com",
    subject: "Suggestion de parcours",
    message: "J'ai découvert un superbe parcours vers le lac de Laffrey. Serait-il possible de l'ajouter à vos routes ?",
    created_at: 1.day.ago
  },
  {
    name: "Sophie Bernard",
    email: "sophie.bernard@example.com",
    subject: "Problème avec ma commande",
    message: "Bonjour, j'ai commandé un casque il y a 5 jours mais je n'ai toujours pas reçu de confirmation. Pouvez-vous vérifier ?",
    created_at: 2.hours.ago
  }
]

contact_messages_data.each { |attrs| ContactMessage.create!(attrs) }
puts "✅ #{ContactMessage.count} messages de contact créés !"

# 📊 AuditLogs (logs d'audit)
puts "📊 Création des logs d'audit..."
if admin_user || florian
  actor = admin_user || florian
  audit_logs_data = [
    {
      actor_user: actor,
      action: "event.publish",
      target_type: "Event",
      target_id: published_events.first&.id || events.first&.id || 1,
      metadata: { status: "published", published_at: 1.week.ago.iso8601 },
      created_at: 1.week.ago
    },
    {
      actor_user: actor,
      action: "organizer_application.approve",
      target_type: "OrganizerApplication",
      target_id: OrganizerApplication.where(status: "approved").first&.id || 1,
      metadata: { reviewed_by: actor.email },
      created_at: 1.week.ago
    },
    {
      actor_user: actor,
      action: "user.promote",
      target_type: "User",
      target_id: regular_users.first&.id || 1,
      metadata: { role: "ORGANIZER", previous_role: "USER" },
      created_at: 5.days.ago
    },
    {
      actor_user: actor,
      action: "event.cancel",
      target_type: "Event",
      target_id: events.find { |e| e.status == "canceled" }&.id || events.first&.id || 1,
      metadata: { reason: "Mauvais temps", canceled_at: 2.days.ago.iso8601 },
      created_at: 2.days.ago
    },
    {
      actor_user: actor,
      action: "product.create",
      target_type: "Product",
      target_id: Product.first&.id || 1,
      metadata: { name: "Casque LED", category: "Protections" },
      created_at: 1.day.ago
    }
  ]

  audit_logs_data.each { |attrs| AuditLog.create!(attrs) }
  puts "✅ #{AuditLog.count} logs d'audit créés !"
end

puts "\n🌱 Seed Phase 2 terminé avec succès !"
puts "📊 Résumé Phase 2 :"
puts "   - Routes : #{Route.count}"
puts "   - Événements : #{Event.count} (#{Event.where(status: 'published').count} publiés)"
puts "   - Inscriptions : #{Attendance.count}"
puts "   - Candidatures organisateur : #{OrganizerApplication.count}"
puts "   - Partenaires : #{Partner.count} (#{Partner.where(is_active: true).count} actifs)"
puts "   - Messages de contact : #{ContactMessage.count}"
puts "   - Logs d'audit : #{AuditLog.count}"

# ========================================
# 👥 ADHÉSIONS
# ========================================

puts "\n👥 Création des adhésions..."

# Calculer les dates de saison
def season_dates_for_year(year)
  start_date = Date.new(year, 9, 1)
  end_date = Date.new(year + 1, 8, 31)
  [ start_date, end_date ]
end

current_year = Date.today.year
current_season_start, current_season_end = season_dates_for_year(current_year >= 9 ? current_year : current_year - 1)
previous_season_start, previous_season_end = season_dates_for_year(current_year >= 9 ? current_year - 1 : current_year - 2)

current_season_name = "#{current_season_start.year}-#{current_season_end.year}"
previous_season_name = "#{previous_season_start.year}-#{previous_season_end.year}"

# Récupérer les utilisateurs réguliers (pas admin)
regular_users = User.where.not(email: [ "T3rorX@hotmail.fr", "admin@roller.com" ]).limit(15)

if regular_users.any?
  # Créer des paiements pour les adhésions
  membership_payments = []
  10.times do
    membership_payments << Payment.create!(
      provider: "helloasso",
      provider_payment_id: "ha_#{SecureRandom.hex(8)}",
      amount_cents: [ 1000, 5655, 2400 ].sample, # 10€ standard, 56.55€ FFRS, 24€ avec T-shirt
      currency: "EUR",
      status: "succeeded",
      created_at: Time.now - rand(1..60).days
    )
  end

  # Adhésions personnelles ACTIVES pour cette année
  puts "  📝 Création d'adhésions personnelles actives..."
  active_users = regular_users.first(5)
  active_users.each_with_index do |user, index|
    payment = membership_payments[index] if index < membership_payments.count
    category = [ :standard, :with_ffrs ].sample

    Membership.create!(
      user: user,
      payment: payment,
      category: category,
      status: :active,
      season: current_season_name,
      start_date: current_season_start,
      end_date: current_season_end,
      amount_cents: Membership.price_for_category(category),
      currency: "EUR",
      is_child_membership: false,
      is_minor: user.is_minor?,
      rgpd_consent: true,
      legal_notices_accepted: true,
      ffrs_data_sharing_consent: category == :with_ffrs,
      health_questionnaire_status: :ok,
      created_at: current_season_start + rand(0..30).days
    )
  end
  puts "    ✅ #{active_users.count} adhésions personnelles actives créées"

  # Adhésions personnelles EXPIRÉES pour l'année précédente
  puts "  📝 Création d'adhésions personnelles expirées..."
  expired_users = regular_users[5..7] || []
  expired_users.each_with_index do |user, index|
    payment = membership_payments[5 + index] if (5 + index) < membership_payments.count
    category = [ :standard, :with_ffrs ].sample

    Membership.create!(
      user: user,
      payment: payment,
      category: category,
      status: :expired,
      season: previous_season_name,
      start_date: previous_season_start,
      end_date: previous_season_end,
      amount_cents: Membership.price_for_category(category),
      currency: "EUR",
      is_child_membership: false,
      is_minor: user.is_minor?,
      rgpd_consent: true,
      legal_notices_accepted: true,
      ffrs_data_sharing_consent: category == :with_ffrs,
      health_questionnaire_status: :ok,
      created_at: previous_season_start + rand(0..30).days
    )
  end
  puts "    ✅ #{expired_users.count} adhésions personnelles expirées créées"

  # Adhésions ENFANTS ACTIVES pour cette année
  puts "  📝 Création d'adhésions enfants actives..."
  users_with_active_children = regular_users[8..10] || []
  users_with_active_children.each_with_index do |user, index|
    payment = membership_payments[8 + index] if (8 + index) < membership_payments.count
    child_age = rand(6..17)
    child_birth_year = current_year - child_age
    child_birth_month = rand(1..12)
    child_birth_day = rand(1..28)

    Membership.create!(
      user: user,
      payment: payment,
      category: :standard,
      status: :active,
      season: current_season_name,
      start_date: current_season_start,
      end_date: current_season_end,
      amount_cents: Membership.price_for_category(:standard),
      currency: "EUR",
      is_child_membership: true,
      is_minor: true,
      child_first_name: [ "Emma", "Lucas", "Sophie", "Max", "Léa", "Tom", "Chloé", "Hugo" ].sample,
      child_last_name: user.last_name || "Dupont",
      child_date_of_birth: Date.new(child_birth_year, child_birth_month, child_birth_day),
      parent_authorization: child_age < 16,
      parent_authorization_date: child_age < 16 ? current_season_start : nil,
      parent_name: "#{user.first_name} #{user.last_name}",
      parent_email: user.email,
      parent_phone: user.phone,
      rgpd_consent: true,
      legal_notices_accepted: true,
      ffrs_data_sharing_consent: false,
      health_questionnaire_status: :ok,
      created_at: current_season_start + rand(0..30).days
    )
  end
  puts "    ✅ #{users_with_active_children.count} adhésions enfants actives créées"

  # Adhésions ENFANTS EXPIRÉES pour l'année précédente
  puts "  📝 Création d'adhésions enfants expirées..."
  users_with_expired_children = regular_users[11..13] || []
  users_with_expired_children.each_with_index do |user, index|
    payment = membership_payments[11 + index] if (11 + index) < membership_payments.count
    child_age_last_year = rand(6..17)
    child_birth_year = previous_season_start.year - child_age_last_year
    child_birth_month = rand(1..12)
    child_birth_day = rand(1..28)

    Membership.create!(
      user: user,
      payment: payment,
      category: :standard,
      status: :expired,
      season: previous_season_name,
      start_date: previous_season_start,
      end_date: previous_season_end,
      amount_cents: Membership.price_for_category(:standard),
      currency: "EUR",
      is_child_membership: true,
      is_minor: true,
      child_first_name: [ "Léo", "Manon", "Nathan", "Inès", "Ethan", "Zoé", "Noah", "Lilou" ].sample,
      child_last_name: user.last_name || "Martin",
      child_date_of_birth: Date.new(child_birth_year, child_birth_month, child_birth_day),
      parent_authorization: child_age_last_year < 16,
      parent_authorization_date: child_age_last_year < 16 ? previous_season_start : nil,
      parent_name: "#{user.first_name} #{user.last_name}",
      parent_email: user.email,
      parent_phone: user.phone,
      rgpd_consent: true,
      legal_notices_accepted: true,
      ffrs_data_sharing_consent: false,
      health_questionnaire_status: :ok,
      created_at: previous_season_start + rand(0..30).days
    )
  end
  puts "    ✅ #{users_with_expired_children.count} adhésions enfants expirées créées"

  # Adhésions EN ATTENTE (pending)
  puts "  📝 Création d'adhésions en attente..."
  pending_user = regular_users[14] || regular_users.first
  if pending_user
    Membership.create!(
      user: pending_user,
      payment: nil,
      category: :standard,
      status: :pending,
      season: current_season_name,
      start_date: current_season_start,
      end_date: current_season_end,
      amount_cents: Membership.price_for_category(:standard),
      currency: "EUR",
      is_child_membership: false,
      is_minor: pending_user.is_minor?,
      rgpd_consent: true,
      legal_notices_accepted: true,
      ffrs_data_sharing_consent: false,
      health_questionnaire_status: :ok,
      created_at: Time.now - 2.days
    )
    puts "    ✅ 1 adhésion personnelle en attente créée"
  end
end

puts "✅ #{Membership.count} adhésions créées au total !"
puts "   - Actives cette année : #{Membership.active_now.count}"
puts "   - Expirées : #{Membership.expired.count}"
puts "   - En attente : #{Membership.pending.count}"
puts "   - Personnelles : #{Membership.personal.count}"
puts "   - Enfants : #{Membership.children.count}"

# ========================================
# 🎯 FLORIAN (T3rorX) - TOUS LES CAS DE FIGURE
# ========================================

puts "\n🎯 Création de tous les cas de figure pour Florian (T3rorX)..."

# Récupérer Florian - utiliser la variable créée au début ou rechercher
# Note: La variable florian créée au début du seed n'est pas accessible ici
# car elle est dans une portée locale, donc on doit la rechercher
florian = User.find_by(email: "T3rorX@hotmail.fr")

# Debug : afficher tous les utilisateurs si pas trouvé
unless florian
  puts "  ⚠️ Utilisateur Florian non trouvé avec email exact 'T3rorX@hotmail.fr'"
  puts "  🔍 Recherche alternative..."
  all_users = User.pluck(:id, :email, :first_name, :last_name)
  puts "  📋 Utilisateurs en base (#{all_users.count}) :"
  all_users.each { |u| puts "     - ID: #{u[0]}, Email: #{u[1]}, Nom: #{u[2]} #{u[3]}" }

  # Essayer différentes variantes
  florian = User.find_by("LOWER(email) = ?", "t3rorx@hotmail.fr") ||
            User.where("email ILIKE ?", "%t3rorx%").first ||
            User.where("email ILIKE ?", "%hotmail%").where("first_name = ?", "Florian").first
end

if florian
  puts "  ✅ Utilisateur Florian trouvé : #{florian.email} (ID: #{florian.id})"
  # Récupérer les variantes de produits pour les commandes
  variant_ids = ProductVariant.ids
  tshirt_variants = ProductVariant.joins(:product).where(products: { slug: "tshirt-grenoble-roller" })

  # ========================================
  # 🛒 COMMANDES BOUTIQUE - TOUS LES CAS
  # ========================================

  puts "  🛒 Création de commandes boutique (tous les statuts)..."

  # 1. Commande PAYÉE et EXPÉDIÉE (avec plusieurs articles)
  payment1 = Payment.create!(
    provider: "stripe",
    provider_payment_id: "stripe_florian_#{SecureRandom.hex(6)}",
    amount_cents: 9500, # 95€
    currency: "EUR",
    status: "succeeded",
    created_at: Time.now - 10.days
  )

  order1 = Order.create!(
    user: florian,
    payment: payment1,
    status: "shipped",
    total_cents: 9500,
    currency: "EUR",
    donation_cents: 0,
    created_at: payment1.created_at + 1.hour
  )

  # Ajouter plusieurs articles à cette commande
  if variant_ids.any?
    OrderItem.create!(
      order: order1,
      variant_id: variant_ids.sample,
      quantity: 2,
      unit_price_cents: 5500,
      created_at: order1.created_at
    )
    OrderItem.create!(
      order: order1,
      variant_id: variant_ids.sample,
      quantity: 1,
      unit_price_cents: 2000,
      created_at: order1.created_at
    )
  end
  puts "    ✅ Commande payée et expédiée créée"

  # 2. Commande PAYÉE mais EN ATTENTE D'EXPÉDITION
  payment2 = Payment.create!(
    provider: "helloasso",
    provider_payment_id: "ha_florian_#{SecureRandom.hex(6)}",
    amount_cents: 4000,
    currency: "EUR",
    status: "succeeded",
    created_at: Time.now - 5.days
  )

  order2 = Order.create!(
    user: florian,
    payment: payment2,
    status: "paid",
    total_cents: 4000,
    currency: "EUR",
    donation_cents: 200,
    created_at: payment2.created_at + 30.minutes
  )

  if variant_ids.any?
    OrderItem.create!(
      order: order2,
      variant_id: variant_ids.sample,
      quantity: 1,
      unit_price_cents: 4000,
      created_at: order2.created_at
    )
  end
  puts "    ✅ Commande payée en attente d'expédition créée"

  # 3. Commande EN ATTENTE DE PAIEMENT
  order3 = Order.create!(
    user: florian,
    payment: nil,
    status: "pending",
    total_cents: 2500,
    currency: "EUR",
    donation_cents: 0,
    created_at: Time.now - 2.days
  )

  if variant_ids.any?
    OrderItem.create!(
      order: order3,
      variant_id: variant_ids.sample,
      quantity: 1,
      unit_price_cents: 2500,
      created_at: order3.created_at
    )
  end
  puts "    ✅ Commande en attente de paiement créée"

  # 4. Commande ANNULÉE
  payment4 = Payment.create!(
    provider: "stripe",
    provider_payment_id: "stripe_florian_cancelled_#{SecureRandom.hex(6)}",
    amount_cents: 1500,
    currency: "EUR",
    status: "failed",
    created_at: Time.now - 7.days
  )

  order4 = Order.create!(
    user: florian,
    payment: payment4,
    status: "cancelled",
    total_cents: 1500,
    currency: "EUR",
    donation_cents: 0,
    created_at: payment4.created_at + 1.hour
  )

  if variant_ids.any?
    OrderItem.create!(
      order: order4,
      variant_id: variant_ids.sample,
      quantity: 1,
      unit_price_cents: 1500,
      created_at: order4.created_at
    )
  end
  puts "    ✅ Commande annulée créée"

  # 5. Commande avec DON
  payment5 = Payment.create!(
    provider: "paypal",
    provider_payment_id: "paypal_florian_#{SecureRandom.hex(6)}",
    amount_cents: 12000,
    currency: "EUR",
    status: "succeeded",
    created_at: Time.now - 3.days
  )

  order5 = Order.create!(
    user: florian,
    payment: payment5,
    status: "paid",
    total_cents: 12000,
    currency: "EUR",
    donation_cents: 500, # 5€ de don
    created_at: payment5.created_at + 15.minutes
  )

  if variant_ids.any?
    OrderItem.create!(
      order: order5,
      variant_id: variant_ids.sample,
      quantity: 1,
      unit_price_cents: 11500,
      created_at: order5.created_at
    )
  end
  puts "    ✅ Commande avec don créée"

  puts "  ✅ #{Order.where(user: florian).count} commandes créées pour Florian"

  # ========================================
  # 👶 ADHÉSIONS ENFANTS - TOUS LES CAS
  # ========================================

  puts "  👶 Création d'adhésions enfants (tous les cas de figure)..."

  # Récupérer une variante T-shirt si disponible
  tshirt_variant = tshirt_variants.first
  tshirt_price = tshirt_variant ? 1400 : nil # 14€ pour le T-shirt

  # 1. ENFANT 1 : Adhésion ACTIVE cette année - Standard SANS T-shirt
  child1_age = 8
  child1_birth = Date.new(current_year - child1_age, rand(1..12), rand(1..28))

  payment_child1 = Payment.create!(
    provider: "helloasso",
    provider_payment_id: "ha_florian_child1_#{SecureRandom.hex(6)}",
    amount_cents: 1000, # 10€ standard
    currency: "EUR",
    status: "succeeded",
    created_at: current_season_start + 5.days
  )

  Membership.create!(
    user: florian,
    payment: payment_child1,
    category: :standard,
    status: :active,
    season: current_season_name,
    start_date: current_season_start,
    end_date: current_season_end,
    amount_cents: 1000,
    currency: "EUR",
    is_child_membership: true,
    is_minor: true,
    child_first_name: "Emma",
    child_last_name: "Astier",
    child_date_of_birth: child1_birth,
    parent_authorization: true,
    parent_authorization_date: current_season_start,
    parent_name: "Florian Astier",
    parent_email: florian.email,
    parent_phone: florian.phone,
    tshirt_variant_id: nil,
    tshirt_price_cents: nil,
    rgpd_consent: true,
    legal_notices_accepted: true,
    ffrs_data_sharing_consent: false,
    health_questionnaire_status: :ok,
    medical_certificate_provided: true,
    created_at: current_season_start + 5.days
  )
  puts "    ✅ Enfant 1 : Adhésion active (Standard, sans T-shirt)"

  # 2. ENFANT 2 : Adhésion ACTIVE cette année - Standard AVEC T-shirt
  child2_age = 12
  child2_birth = Date.new(current_year - child2_age, rand(1..12), rand(1..28))

  payment_child2 = Payment.create!(
    provider: "helloasso",
    provider_payment_id: "ha_florian_child2_#{SecureRandom.hex(6)}",
    amount_cents: 2400, # 10€ + 14€ T-shirt
    currency: "EUR",
    status: "succeeded",
    created_at: current_season_start + 10.days
  )

  Membership.create!(
    user: florian,
    payment: payment_child2,
    category: :standard,
    status: :active,
    season: current_season_name,
    start_date: current_season_start,
    end_date: current_season_end,
    amount_cents: 1000,
    currency: "EUR",
    is_child_membership: true,
    is_minor: true,
    child_first_name: "Lucas",
    child_last_name: "Astier",
    child_date_of_birth: child2_birth,
    parent_authorization: true,
    parent_authorization_date: current_season_start,
    parent_name: "Florian Astier",
    parent_email: florian.email,
    parent_phone: florian.phone,
    tshirt_variant_id: tshirt_variant&.id,
    tshirt_price_cents: tshirt_price,
    rgpd_consent: true,
    legal_notices_accepted: true,
    ffrs_data_sharing_consent: false,
    health_questionnaire_status: :ok,
    medical_certificate_provided: true,
    created_at: current_season_start + 10.days
  )
  puts "    ✅ Enfant 2 : Adhésion active (Standard, avec T-shirt)"

  # 3. ENFANT 3 : Adhésion ACTIVE cette année - FFRS SANS T-shirt
  child3_age = 15
  child3_birth = Date.new(current_year - child3_age, rand(1..12), rand(1..28))

  payment_child3 = Payment.create!(
    provider: "helloasso",
    provider_payment_id: "ha_florian_child3_#{SecureRandom.hex(6)}",
    amount_cents: 5655, # 56.55€ FFRS
    currency: "EUR",
    status: "succeeded",
    created_at: current_season_start + 15.days
  )

  Membership.create!(
    user: florian,
    payment: payment_child3,
    category: :with_ffrs,
    status: :active,
    season: current_season_name,
    start_date: current_season_start,
    end_date: current_season_end,
    amount_cents: 5655,
    currency: "EUR",
    is_child_membership: true,
    is_minor: true,
    child_first_name: "Sophie",
    child_last_name: "Astier",
    child_date_of_birth: child3_birth,
    parent_authorization: true,
    parent_authorization_date: current_season_start,
    parent_name: "Florian Astier",
    parent_email: florian.email,
    parent_phone: florian.phone,
    tshirt_variant_id: nil,
    tshirt_price_cents: nil,
    rgpd_consent: true,
    legal_notices_accepted: true,
    ffrs_data_sharing_consent: true,
    health_questionnaire_status: :ok,
    medical_certificate_provided: true,
    created_at: current_season_start + 15.days
  )
  puts "    ✅ Enfant 3 : Adhésion active (FFRS, sans T-shirt)"

  # 4. ENFANT 4 : Adhésion EXPIRÉE année précédente - Standard
  child4_age_last_year = 7
  child4_birth = Date.new(previous_season_start.year - child4_age_last_year, rand(1..12), rand(1..28))

  payment_child4 = Payment.create!(
    provider: "helloasso",
    provider_payment_id: "ha_florian_child4_#{SecureRandom.hex(6)}",
    amount_cents: 1000,
    currency: "EUR",
    status: "succeeded",
    created_at: previous_season_start + 20.days
  )

  Membership.create!(
    user: florian,
    payment: payment_child4,
    category: :standard,
    status: :expired,
    season: previous_season_name,
    start_date: previous_season_start,
    end_date: previous_season_end,
    amount_cents: 1000,
    currency: "EUR",
    is_child_membership: true,
    is_minor: true,
    child_first_name: "Tom",
    child_last_name: "Astier",
    child_date_of_birth: child4_birth,
    parent_authorization: true,
    parent_authorization_date: previous_season_start,
    parent_name: "Florian Astier",
    parent_email: florian.email,
    parent_phone: florian.phone,
    tshirt_variant_id: nil,
    tshirt_price_cents: nil,
    rgpd_consent: true,
    legal_notices_accepted: true,
    ffrs_data_sharing_consent: false,
    health_questionnaire_status: :ok,
    medical_certificate_provided: true,
    created_at: previous_season_start + 20.days
  )
  puts "    ✅ Enfant 4 : Adhésion expirée (Standard, année précédente)"

  # 5. ENFANT 5 : Adhésion EXPIRÉE année précédente - FFRS AVEC T-shirt
  child5_age_last_year = 11
  child5_birth = Date.new(previous_season_start.year - child5_age_last_year, rand(1..12), rand(1..28))

  payment_child5 = Payment.create!(
    provider: "helloasso",
    provider_payment_id: "ha_florian_child5_#{SecureRandom.hex(6)}",
    amount_cents: 7055, # 56.55€ + 14€ T-shirt
    currency: "EUR",
    status: "succeeded",
    created_at: previous_season_start + 25.days
  )

  Membership.create!(
    user: florian,
    payment: payment_child5,
    category: :with_ffrs,
    status: :expired,
    season: previous_season_name,
    start_date: previous_season_start,
    end_date: previous_season_end,
    amount_cents: 5655,
    currency: "EUR",
    is_child_membership: true,
    is_minor: true,
    child_first_name: "Léa",
    child_last_name: "Astier",
    child_date_of_birth: child5_birth,
    parent_authorization: true,
    parent_authorization_date: previous_season_start,
    parent_name: "Florian Astier",
    parent_email: florian.email,
    parent_phone: florian.phone,
    tshirt_variant_id: tshirt_variant&.id,
    tshirt_price_cents: tshirt_price,
    rgpd_consent: true,
    legal_notices_accepted: true,
    ffrs_data_sharing_consent: true,
    health_questionnaire_status: :ok,
    medical_certificate_provided: true,
    created_at: previous_season_start + 25.days
  )
  puts "    ✅ Enfant 5 : Adhésion expirée (FFRS avec T-shirt, année précédente)"

  # 6. ENFANT 6 : Adhésion EN ATTENTE (pending) - Standard
  child6_age = 9
  child6_birth = Date.new(current_year - child6_age, rand(1..12), rand(1..28))

  Membership.create!(
    user: florian,
    payment: nil,
    category: :standard,
    status: :pending,
    season: current_season_name,
    start_date: current_season_start,
    end_date: current_season_end,
    amount_cents: 1000,
    currency: "EUR",
    is_child_membership: true,
    is_minor: true,
    child_first_name: "Max",
    child_last_name: "Astier",
    child_date_of_birth: child6_birth,
    parent_authorization: true,
    parent_authorization_date: Date.today,
    parent_name: "Florian Astier",
    parent_email: florian.email,
    parent_phone: florian.phone,
    tshirt_variant_id: nil,
    tshirt_price_cents: nil,
    rgpd_consent: true,
    legal_notices_accepted: true,
    ffrs_data_sharing_consent: false,
    health_questionnaire_status: :ok,
    medical_certificate_provided: true,
    created_at: Time.now - 1.day
  )
  puts "    ✅ Enfant 6 : Adhésion en attente (Standard, pending)"

  # 7. ENFANT 7 : Adhésion EN ATTENTE (pending) - FFRS AVEC T-shirt
  child7_age = 13
  child7_birth = Date.new(current_year - child7_age, rand(1..12), rand(1..28))

  Membership.create!(
    user: florian,
    payment: nil,
    category: :with_ffrs,
    status: :pending,
    season: current_season_name,
    start_date: current_season_start,
    end_date: current_season_end,
    amount_cents: 5655,
    currency: "EUR",
    is_child_membership: true,
    is_minor: true,
    child_first_name: "Chloé",
    child_last_name: "Astier",
    child_date_of_birth: child7_birth,
    parent_authorization: true,
    parent_authorization_date: Date.today,
    parent_name: "Florian Astier",
    parent_email: florian.email,
    parent_phone: florian.phone,
    tshirt_variant_id: tshirt_variant&.id,
    tshirt_price_cents: tshirt_price,
    rgpd_consent: true,
    legal_notices_accepted: true,
    ffrs_data_sharing_consent: true,
    health_questionnaire_status: :ok,
    medical_certificate_provided: true,
    created_at: Time.now - 3.days
  )
  puts "    ✅ Enfant 7 : Adhésion en attente (FFRS avec T-shirt, pending)"

  puts "  ✅ #{Membership.where(user: florian, is_child_membership: true).count} adhésions enfants créées pour Florian"
  puts "     - Actives : #{Membership.where(user: florian, is_child_membership: true, status: :active).count}"
  puts "     - Expirées : #{Membership.where(user: florian, is_child_membership: true, status: :expired).count}"
  puts "     - En attente : #{Membership.where(user: florian, is_child_membership: true, status: :pending).count}"

  puts "\n  ✅ Tous les cas de figure créés pour Florian (T3rorX) !"
else
  puts "  ⚠️ Utilisateur Florian (T3rorX) non trouvé, impossible de créer les cas de figure"
end

puts "\n🌱 Seed complet terminé avec succès !"

# Réactiver le callback d'envoi d'email
User.set_callback(:create, :after, :send_welcome_email_and_confirmation)

# Réactiver l'envoi d'emails
ActionMailer::Base.perform_deliveries = true
