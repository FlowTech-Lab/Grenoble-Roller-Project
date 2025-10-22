Table users {
  id integer [pk, increment]
  email varchar(255) [not null, default: ""]
  encrypted_password varchar(255) [not null, default: ""]
  first_name varchar(255)
  last_name varchar(255)
  description text
  created_at timestamp
}

Table events {
  id integer [pk, increment]
  start_date timestamptz [not null]
  duration integer [not null]        // >0 et multiple de 5 (check)
  title varchar(140) [not null]      // len 5..140 (check)
  description text [not null]        // len 20..1000 (check)
  price integer [not null]           // 1..1000 (check)
  location varchar(255) [not null]
  user_id integer [not null]         // admin/organisateur
  created_at timestamp
  Indexes {
    user_id
  }
}

Table attendances {
  id integer [pk, increment]
  user_id integer [not null]
  event_id integer [not null]
  stripe_customer_id varchar(255) [not null]
  created_at timestamp
  Indexes {
    (user_id, event_id) [unique]
    user_id
    event_id
  }
}

Ref: events.user_id > users.id         // ON DELETE RESTRICT (éviter orphelins)
Ref: attendances.user_id > users.id     // ON DELETE CASCADE
Ref: attendances.event_id > events.id   // ON DELETE CASCADE