// Schéma DB – Users + Boutique (MVP)
// dbdiagram.io – PostgreSQL – Grenoble Roller

Table roles {
  id integer [pk, increment]
  code varchar(50) [not null, unique]
  name varchar(100) [not null]
  level smallint [not null]
  created_at timestamp
}

Table users {
  id integer [pk, increment]
  email varchar(255) [not null, unique]
  encrypted_password varchar(255) [not null, default: ""]
  first_name varchar(255)
  last_name varchar(255)
  bio text
  phone varchar(30)
  avatar_url varchar(255)
  email_verified boolean [not null, default: false]
  role_id integer [not null]
  created_at timestamp
  updated_at timestamp
  Indexes {
    role_id
  }
}

// Boutique minimaliste (listing + commandes)
Table product_categories {
  id integer [pk, increment]
  name varchar(100) [not null]
  slug varchar(120) [not null, unique]
  created_at timestamp
}

Table products {
  id integer [pk, increment]
  category_id integer
  name varchar(140) [not null]
  slug varchar(160) [not null, unique]
  description text
  price_cents integer [not null]
  currency char(3) [not null, default: "EUR"]
  stock_qty integer [not null, default: 0]
  is_active boolean [not null, default: true]
  image_url varchar(255)
  created_at timestamp
  updated_at timestamp
  Indexes {
    category_id
    (is_active, slug)
  }
}

// Variantes produits (ex: taille/couleur)
Table option_types {
  id integer [pk, increment]
  name varchar(50) [not null, unique]       // size, color
  presentation varchar(100)                 // "Taille", "Couleur"
}

Table option_values {
  id integer [pk, increment]
  option_type_id integer [not null]
  value varchar(50) [not null]              // M, L, Red
  presentation varchar(100)
  Indexes { option_type_id }
}

Table product_variants {
  id integer [pk, increment]
  product_id integer [not null]
  sku varchar(80) [not null, unique]
  price_cents integer [not null]            // peut surcharger product.price_cents
  currency char(3) [not null, default: "EUR"]
  stock_qty integer [not null, default: 0]
  is_active boolean [not null, default: true]
  created_at timestamp
  updated_at timestamp
  Indexes { product_id }
}

Table variant_option_values {
  id integer [pk, increment]
  variant_id integer [not null]
  option_value_id integer [not null]
  Indexes { (variant_id, option_value_id) [unique] }
}

Table payments {
  id integer [pk, increment]
  provider varchar(20) [not null]         // stripe, helloasso, free
  provider_payment_id varchar(255)
  amount_cents integer [not null, default: 0]
  currency char(3) [not null, default: "EUR"]
  status varchar(20) [not null, default: "succeeded"]
  created_at timestamp
}

Table orders {
  id integer [pk, increment]
  user_id integer [not null]
  status varchar(20) [not null, default: "pending"] // pending, paid, canceled, shipped
  total_cents integer [not null, default: 0]
  currency char(3) [not null, default: "EUR"]
  payment_id integer
  created_at timestamp
  updated_at timestamp
  Indexes {
    user_id
    payment_id
  }
}

Table order_items {
  id integer [pk, increment]
  order_id integer [not null]
  variant_id integer [not null]
  quantity integer [not null, default: 1]
  unit_price_cents integer [not null]
  created_at timestamp
  Indexes {
    order_id
    variant_id
  }
}

// Partenaires & Contact (site)
Table partners {
  id integer [pk, increment]
  name varchar(140) [not null]
  url varchar(255)
  logo_url varchar(255)
  description text
  is_active boolean [not null, default: true]
  created_at timestamp
}

Table contact_messages {
  id integer [pk, increment]
  name varchar(140) [not null]
  email varchar(255) [not null]
  subject varchar(140) [not null]
  message text [not null]
  created_at timestamp
}

// Journalisation d'actions d'admin/modo (optionnel)
Table audit_logs {
  id integer [pk, increment]
  actor_user_id integer [not null]
  action varchar(80) [not null]
  target_type varchar(50) [not null]
  target_id integer [not null]
  metadata jsonb
  created_at timestamp
  Indexes {
    actor_user_id
    (target_type, target_id)
  }
}

// Références
Ref: users.role_id > roles.id
Ref: products.category_id > product_categories.id
Ref: orders.user_id > users.id
Ref: orders.payment_id > payments.id
Ref: order_items.order_id > orders.id
Ref: order_items.variant_id > product_variants.id
Ref: product_variants.product_id > products.id
Ref: option_values.option_type_id > option_types.id
Ref: variant_option_values.variant_id > product_variants.id
Ref: variant_option_values.option_value_id > option_values.id
Ref: audit_logs.actor_user_id > users.id


