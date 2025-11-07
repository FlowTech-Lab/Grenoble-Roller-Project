# 📊 Phase 2 - Migrations et Modèles créés

**Date** : 2025-01-20  
**Statut** : ✅ Migrations appliquées et modèles créés (testés et validés)

---

## ✅ MIGRATIONS CRÉÉES

### Ordre d'exécution (dépendances respectées)

1. **Routes** (`20251107164343_create_routes.rb`)
   - Table de base, aucune dépendance FK
   - Colonnes : name, description, distance_km, elevation_m, difficulty, gpx_url, map_image_url, safety_notes

2. **OrganizerApplications** (`20251107164358_create_organizer_applications.rb`)
   - Dépend de : User (user_id, reviewed_by_id)
   - Colonnes : user_id, motivation, status, reviewed_by_id, reviewed_at

3. **Events** (`20251107164400_create_events.rb`)
   - Dépend de : User (creator_user_id), Route (route_id, optionnel)
   - Colonnes : creator_user_id, status, start_at (timestamptz), duration_min, title, description, price_cents, currency, location_text, meeting_lat, meeting_lng, route_id, cover_image_url
   - Index : creator_user_id, route_id, [status, start_at]

4. **Attendances** (`20251107164403_create_attendances.rb`)
   - Dépend de : User (user_id), Event (event_id), Payment (payment_id, optionnel)
   - Colonnes : user_id, event_id, status, payment_id, stripe_customer_id
   - Index : user_id, event_id, payment_id, [user_id, event_id] (unique)

5. **Partners** (`20251107164406_create_partners.rb`)
   - Aucune dépendance FK
   - Colonnes : name, url, logo_url, description, is_active

6. **ContactMessages** (`20251107164409_create_contact_messages.rb`)
   - Aucune dépendance FK
   - Colonnes : name, email, subject, message

7. **AuditLogs** (`20251107164412_create_audit_logs.rb`)
   - Dépend de : User (actor_user_id)
   - Colonnes : actor_user_id, action, target_type, target_id, metadata (jsonb)
   - Index : actor_user_id, [target_type, target_id]

---

## ✅ MODÈLES CRÉÉS

### 1. Route (`app/models/route.rb`)

**Associations** :
- `has_many :events, dependent: :nullify`

**Validations** :
- `name` : presence, length max 140
- `difficulty` : inclusion in ['easy', 'medium', 'hard'], allow_nil
- `distance_km` : numericality >= 0, allow_nil
- `elevation_m` : numericality integer >= 0, allow_nil

---

### 2. OrganizerApplication (`app/models/organizer_application.rb`)

**Associations** :
- `belongs_to :user`
- `belongs_to :reviewed_by, class_name: 'User', optional: true`

**Validations** :
- `status` : presence, enum (pending, approved, rejected) avec validate: true
- `motivation` : presence si status == 'pending'

**Enums** :
- `status` : pending, approved, rejected (Rails 8 avec validate: true)

---

### 3. Event (`app/models/event.rb`)

**Associations** :
- `belongs_to :creator_user, class_name: 'User'`
- `belongs_to :route, optional: true`
- `has_many :attendances, dependent: :destroy`
- `has_many :users, through: :attendances`

**Validations** :
- `status` : presence, enum (draft, published, canceled) avec validate: true
- `start_at` : presence
- `duration_min` : presence, integer > 0, multiple_of: 5
- `title` : presence, length 5..140
- `description` : presence, length 20..1000
- `price_cents` : presence, >= 0
- `currency` : presence, length 3
- `location_text` : presence, length max 255

**Scopes** :
- `upcoming` : events à venir (start_at > maintenant)
- `past` : events passés (start_at <= maintenant)
- `published` : events publiés (status: 'published')

**Enums** :
- `status` : draft, published, canceled (Rails 8 avec validate: true)

---

### 4. Attendance (`app/models/attendance.rb`)

**Associations** :
- `belongs_to :user`
- `belongs_to :event`
- `belongs_to :payment, optional: true`

**Validations** :
- `status` : presence, enum avec validate: true
- `user_id` : uniqueness scope event_id (un utilisateur ne peut s'inscrire qu'une fois par événement)

**Scopes** :
- `active` : attendances non annulées
- `canceled` : attendances annulées

**Enums** :
- `status` : registered, paid, canceled, present, no_show (Rails 8 avec validate: true)

---

### 5. Partner (`app/models/partner.rb`)

**Associations** : Aucune

**Validations** :
- `name` : presence, length max 140
- `url` : format URL, allow_blank
- `is_active` : inclusion in [true, false]

**Scopes** :
- `active` : partenaires actifs
- `inactive` : partenaires inactifs

---

### 6. ContactMessage (`app/models/contact_message.rb`)

**Associations** : Aucune

**Validations** :
- `name` : presence, length max 140
- `email` : presence, format email
- `subject` : presence, length max 140
- `message` : presence, length min 10

---

### 7. AuditLog (`app/models/audit_log.rb`)

**Associations** :
- `belongs_to :actor_user, class_name: 'User'`

**Validations** :
- `action` : presence, length max 80
- `target_type` : presence, length max 50
- `target_id` : presence, integer

**Scopes** :
- `by_action(action)` : filtrage par action
- `by_target(type, id)` : filtrage par cible
- `by_actor(user_id)` : filtrage par acteur
- `recent` : tri par date décroissante

**Colonnes spéciales** :
- `metadata` : jsonb (données additionnelles flexibles)

---

## ✅ MODÈLES MIS À JOUR

### User (`app/models/user.rb`)

**Associations ajoutées** :
- `has_many :created_events, class_name: 'Event', foreign_key: 'creator_user_id', dependent: :restrict_with_error`
- `has_many :attendances, dependent: :destroy`
- `has_many :events, through: :attendances`
- `has_many :organizer_applications, dependent: :destroy`
- `has_many :reviewed_applications, class_name: 'OrganizerApplication', foreign_key: 'reviewed_by_id', dependent: :nullify`
- `has_many :audit_logs, class_name: 'AuditLog', foreign_key: 'actor_user_id', dependent: :nullify`

---

### Payment (`app/models/payment.rb`)

**Associations ajoutées** :
- `has_many :attendances, dependent: :nullify`

---

## 🔧 COMMANDES POUR APPLIQUER

```bash
# Appliquer les migrations
rails db:migrate

# Vérifier le statut
rails db:migrate:status

# Rollback si nécessaire
rails db:rollback STEP=7
```

---

## 📋 PROCHAINES ÉTAPES

### 1. Appliquer les migrations
```bash
rails db:migrate
```

### 2. Créer les contrôleurs (Phase 2)
- `EventsController` (CRUD complet)
- `RoutesController` (CRUD complet)
- `AttendancesController` (inscription/désinscription)
- `OrganizerApplicationsController` (candidatures)
- `PartnersController` (CRUD complet)
- `ContactMessagesController` (création)
- `AuditLogsController` (lecture seule, admin)

### 3. Créer les routes
```ruby
resources :events
resources :routes
resources :attendances, only: [:create, :destroy]
resources :organizer_applications, only: [:new, :create, :show]
resources :partners, only: [:index]
resources :contact_messages, only: [:new, :create]
```

### 4. Tests RSpec (TDD)
- Tests modèles (validations, associations, scopes)
- Tests contrôleurs
- Tests système (inscription événements)

### 5. ActiveAdmin (Phase 2, Jour 11-12)
- Installation ActiveAdmin
- Configuration resources pour tous les modèles Phase 2

---

## ✅ CHECKLIST

- [x] Migrations créées (7 migrations)
- [x] Modèles créés (7 modèles)
- [x] Associations définies
- [x] Validations définies
- [x] Enums configurés (Rails 8 avec validate: true)
- [x] Scopes définis
- [x] Modèles existants mis à jour (User, Payment)
- [x] Migrations appliquées (`rails db:migrate`)
- [x] Seeds créés et testés (Phase 2)
- [x] Tests de validations et associations réussis
- [ ] Contrôleurs créés
- [ ] Routes créées
- [ ] Tests RSpec créés
- [ ] Vues créées

---

**Document créé le** : 2025-01-20  
**Version** : 1.0

