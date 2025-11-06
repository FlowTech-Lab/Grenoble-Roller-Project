// Schéma DB – dbdiagram.io (PostgreSQL) – Grenoble Roller
// Principes:
// - Roles hiérarchiques: Simple, Inscrit, Initiation, Organisateur, Modérateur, Admin, SuperAdmin
// - Rails 8 + PostgreSQL; montants en _cents, timestamps par défaut, contraintes explicites

Table roles {
  id integer [pk, increment]
  // level permet un contrôle simple par niveau (plus haut = plus de droits)
  code varchar(50) [not null, unique]   // e.g. USER, REGISTERED, INITIATION, ORGANIZER, MODERATOR, ADMIN, SUPERADMIN
  name varchar(100) [not null]
  level smallint [not null]             // 10..70 (USER=10 .. SUPERADMIN=70)
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
  role_id integer [not null]            // rôle principal (hiérarchique)
  created_at timestamp
  updated_at timestamp
  Indexes {
    role_id
  }
}

// Demandes pour devenir organisateur (validation par admin/modo)
Table organizer_applications {
  id integer [pk, increment]
  user_id integer [not null]
  motivation text
  status varchar(20) [not null, default: "pending"] // pending, approved, rejected
  reviewed_by integer                                // users.id de l'admin/modo
  reviewed_at timestamptz
  created_at timestamp
  Indexes {
    user_id
    reviewed_by
  }
}

// Parcours / routes prédéfinies
Table routes {
  id integer [pk, increment]
  name varchar(140) [not null]
  description text
  distance_km numeric(5,2)               // ex: 12.50
  elevation_m integer
  difficulty varchar(20)                  // easy, medium, hard
  gpx_url varchar(255)
  map_image_url varchar(255)
  safety_notes text
  created_at timestamp
}

Table events {
  id integer [pk, increment]
  creator_user_id integer [not null]      // admin/organisateur
  status varchar(20) [not null, default: "draft"]  // draft, published, canceled
  start_at timestamptz [not null]
  duration_min integer [not null]         // >0 et multiple de 5 (check)
  title varchar(140) [not null]           // len 5..140 (check)
  description text [not null]             // len 20..1000 (check)
  price_cents integer [not null, default: 0] // 0 = gratuit
  currency char(3) [not null, default: "EUR"]
  location_text varchar(255) [not null]
  meeting_lat numeric(9,6)
  meeting_lng numeric(9,6)
  route_id integer                         // optionnel
  cover_image_url varchar(255)
  created_at timestamp
  updated_at timestamp
  Indexes {
    creator_user_id
    route_id
    (status, start_at)
  }
}

// Inscriptions/participations aux events
Table attendances {
  id integer [pk, increment]
  user_id integer [not null]
  event_id integer [not null]
  status varchar(20) [not null, default: "registered"] // registered, paid, canceled, present, no_show
  payment_id integer
  stripe_customer_id varchar(255)
  created_at timestamp
  Indexes {
    (user_id, event_id) [unique]
    user_id
    event_id
    payment_id
  }
}

// Paiements centralisés (Stripe / HelloAsso / gratuit)
Table payments {
  id integer [pk, increment]
  provider varchar(20) [not null]         // stripe, helloasso, free
  provider_payment_id varchar(255)
  amount_cents integer [not null, default: 0]
  currency char(3) [not null, default: "EUR"]
  status varchar(20) [not null, default: "succeeded"] // created, pending, succeeded, failed, refunded
  created_at timestamp
}

// Boutique minimaliste
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
  product_id integer [not null]
  quantity integer [not null, default: 1]
  unit_price_cents integer [not null]
  created_at timestamp
  Indexes {
    order_id
    product_id
  }
}

// Partenaires
Table partners {
  id integer [pk, increment]
  name varchar(140) [not null]
  url varchar(255)
  logo_url varchar(255)
  description text
  is_active boolean [not null, default: true]
  created_at timestamp
}

// Contact / messages (formulaire simple)
Table contact_messages {
  id integer [pk, increment]
  name varchar(140) [not null]
  email varchar(255) [not null]
  subject varchar(140) [not null]
  message text [not null]
  created_at timestamp
}

// Journalisation d'actions d'admin/modo
Table audit_logs {
  id integer [pk, increment]
  actor_user_id integer [not null]
  action varchar(80) [not null]       // e.g. event.publish, user.promote
  target_type varchar(50) [not null]  // users, events, products, orders, etc.
  target_id integer [not null]
  metadata jsonb
  created_at timestamp
  Indexes {
    actor_user_id
    (target_type, target_id)
  }
}

// Références & contraintes
Ref: users.role_id > roles.id                    // ON DELETE RESTRICT
Ref: organizer_applications.user_id > users.id   // ON DELETE CASCADE
Ref: organizer_applications.reviewed_by > users.id
Ref: events.creator_user_id > users.id           // ON DELETE RESTRICT
Ref: events.route_id > routes.id                 // ON DELETE SET NULL
Ref: attendances.user_id > users.id              // ON DELETE CASCADE
Ref: attendances.event_id > events.id            // ON DELETE CASCADE
Ref: attendances.payment_id > payments.id        // ON DELETE SET NULL
Ref: orders.user_id > users.id                   // ON DELETE CASCADE
Ref: orders.payment_id > payments.id             // ON DELETE SET NULL
Ref: order_items.order_id > orders.id            // ON DELETE CASCADE
Ref: order_items.product_id > products.id        // ON DELETE RESTRICT
Ref: products.category_id > product_categories.id // ON DELETE SET NULL
Ref: audit_logs.actor_user_id > users.id

// Seed rôles (suggestion):
// USER(10), REGISTERED(20), INITIATION(30), ORGANIZER(40), MODERATOR(50), ADMIN(60), SUPERADMIN(70)