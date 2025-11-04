# db/seeds.rb

# Nettoyage
VariantOptionValue.delete_all
OptionValue.delete_all
OptionType.delete_all
ProductVariant.delete_all
Product.delete_all
ProductCategory.delete_all
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

puts "🌱 Seed terminé avec succès !"
