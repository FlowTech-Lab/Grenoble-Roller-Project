# 🎯 PLAN PHASE 2 - Événements & Admin

**Document unique** : Planning, checklist et pièges à éviter pour Phase 2  
**Date** : Jan 2025  
**État** : Public events (CRUD + inscriptions) ✅ → Tests & ActiveAdmin custom ⏳

---

## 📊 ÉTAT ACTUEL

### ✅ TERMINÉ
- [x] Migrations Phase 2 créées et appliquées (7 migrations)
- [x] Modèles Phase 2 créés (Route, Event, Attendance, OrganizerApplication, Partner, ContactMessage, AuditLog)
- [x] Validations, associations, enums, scopes
- [x] Seeds créés et testés (Phase 2)
- [x] RSpec configuré
- [x] ActiveAdmin installé (core + intégration Pundit configurée)
- [x] Application publique : CRUD Events complet (index/show/new/edit/destroy)
- [x] UI/UX évènements conforme UI-Kit (cards, hero, auth-form, mobile-first)
- [x] Parcours inscription/désinscription (EventsController#attend / #cancel_attendance)
- [x] Page membre `Mes sorties` (liste des attendances + CTA cohérents)
- [x] Navigation mise à jour (lien “Événements”, “Mes sorties”)

### 🔜 EN COURS
- [ ] FactoryBot factories pour tous les modèles Phase 2 (optionnel si helpers suffisants)
- [ ] Tests RSpec/Capybara pour les controllers publics (Events, Attendances) et policies
- [ ] Optimisations UX en file d’attente : badge compteur, retours flash (préparés côté vue)

### 📅 À VENIR
- [ ] Customisation ActiveAdmin (Jour 12-13)
- [ ] Tests admin + permissions (Jour 14-15)
- [ ] Optimisations performance : `attendances_count` (counter cache), `max_participants`
- [ ] Notifications e-mail inscription/désinscription + export iCal
- [ ] Accessibilité (ARIA, navigation clavier) & pagination “Mes sorties”

---

## ⚠️ PIÈGE CRITIQUE À ÉVITER

### ❌ NE PAS créer contrôleurs/routes manuels avant ActiveAdmin

**Pourquoi ?** ActiveAdmin génère automatiquement :
- Contrôleurs admin (`app/admin/events.rb`, etc.)
- Routes admin (`/admin/events`, `/admin/routes`, etc.)
- Vues admin (index, show, form, filters, bulk actions)

**Si vous créez maintenant** :
```ruby
# app/controllers/events_controller.rb (full CRUD)
# app/controllers/routes_controller.rb (full CRUD)
# + routes.rb resources :events, :routes
# + vues ERB admin
```

**Puis Jour 11** :
```bash
rails generate activeadmin:resource Event Route
# ← Crée les MÊMES contrôleurs (version ActiveAdmin)
# ← Résultat : Duplication complète, travail perdu ❌
```

**✅ Solution** : ActiveAdmin génère TOUT automatiquement. Zéro travail manuel de CRUD admin.

> ℹ️ Exception déjà appliquée côté **application publique** : contrôleurs `EventsController` & `AttendancesController` implémentés pour le front (non admin). Ne rien dupliquer dans l’espace `admin`.

---

## 📅 PLAN DÉTAILLÉ (Jour par jour)

### Jour 5-10 : Tests RSpec COMPLETS (AVANT ActiveAdmin)

#### ✅ Pré-requis vérifiés
- [x] Modèles stables (validations, associations, scopes) ✅
- [x] Migrations appliquées ✅
- [x] Seeds créés et testés ✅

#### ✅ Réalisé
- [x] **Tests RSpec models complets** :
  - `spec/models/route_spec.rb` (validations name, distance_km, elevation_m, difficulty)
  - `spec/models/event_spec.rb` (validations title, description, start_at, duration_min, status, scopes)
  - `spec/models/attendance_spec.rb` (associations user, event, payment, validations)
  - `spec/models/organizer_application_spec.rb` (workflow status, associations)
  - `spec/models/partner_spec.rb` (validations, associations)
  - `spec/models/contact_message_spec.rb` (validations)
  - `spec/models/audit_log_spec.rb` (validations, associations, scopes)

- [x] **Tests edge cases** (validations négatives, associations invalides)
- [x] **Coverage >70%** ← **OBLIGATOIRE AVANT ActiveAdmin** *(modèle specs : 75 exemples, 0 échec)*

**Vérification** :
```bash
rspec spec/models
# ✅ 75 examples, 0 failures
# ✅ Coverage >70%
```

---

### Jour 11 : Installation ActiveAdmin

#### ⚠️ Pré-requis OBLIGATOIRES
- [x] Modèles 100% stables ✅
- [x] Migrations appliquées ✅
- [x] Seeds testés ✅
- [x] **Tests RSpec >70% coverage** ← **OBLIGATOIRE** (confirmé via `bundle exec rspec spec/models`)

> ✅ Commande validée (Docker) :
> ```bash
> docker compose -f ops/dev/docker-compose.yml up -d db
> docker compose -f ops/dev/docker-compose.yml run --rm \
>   -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
>   -e RAILS_ENV=test \
>   web bundle exec rspec spec/models
> ```
> Utiliser la même configuration (`DATABASE_URL` explicite) pour `db:drop db:create db:schema:load` si un reset test est nécessaire.

#### Installation
- [x] Gems `activeadmin` + `pundit` ajoutées (`Gemfile`) puis `bundle install` via Docker (`BUNDLE_PATH=/rails/vendor/bundle`)
- [x] `rails generate active_admin:install --skip-users`
- [x] Configuration `config/initializers/active_admin.rb` + `ApplicationController` (Devise auth, `ActiveAdmin::PunditAdapter`, redirections)
- [x] `rails generate pundit:install`
- [x] `rails db:migrate` (création table `active_admin_comments`)
- [x] Vérification RSpec `spec/models` (base test) après migration
- [x] `bin/docker-entrypoint` mis à jour pour reconstruire automatiquement les CSS (application + ActiveAdmin) à chaque `docker compose up web`
- [x] Accès `/admin` validé (`admin@roller.com` / `admin123`)
- [x] Generate resources :
  ```bash
  rails g activeadmin:resource Route
  rails g activeadmin:resource Event
  rails g activeadmin:resource Attendance
  rails g activeadmin:resource OrganizerApplication
  rails g activeadmin:resource Partner
  rails g activeadmin:resource ContactMessage
  rails g activeadmin:resource AuditLog
  rails g activeadmin:resource User
  rails g activeadmin:resource Product
  rails g activeadmin:resource Order
  ```

> Commandes exécutées (Docker) :
> ```bash
> docker compose -f ops/dev/docker-compose.yml run --rm \
>   -e BUNDLE_PATH=/rails/vendor/bundle \
>   web bundle install
>
> docker compose -f ops/dev/docker-compose.yml run --rm \
>   -e BUNDLE_PATH=/rails/vendor/bundle \
>   -e DATABASE_URL=postgresql://postgres:postgres@db:5432/grenoble_roller_development \
>   web bundle exec rails generate active_admin:install --skip-users
>
> docker compose -f ops/dev/docker-compose.yml run --rm \
>   -e BUNDLE_PATH=/rails/vendor/bundle \
>   -e DATABASE_URL=postgresql://postgres:postgres@db:5432/grenoble_roller_development \
>   web bundle exec rails generate pundit:install
>
> docker compose -f ops/dev/docker-compose.yml run --rm \
>   -e BUNDLE_PATH=/rails/vendor/bundle \
>   -e DATABASE_URL=postgresql://postgres:postgres@db:5432/grenoble_roller_development \
>   web bundle exec rails db:migrate
>
> docker compose -f ops/dev/docker-compose.yml run --rm \
>   -e BUNDLE_PATH=/rails/vendor/bundle \
>   -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
>   -e RAILS_ENV=test \
>   web bundle exec rails db:drop db:create db:schema:load
>
> docker compose -f ops/dev/docker-compose.yml run --rm \
>   -e BUNDLE_PATH=/rails/vendor/bundle \
>   -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
>   -e RAILS_ENV=test \
>   web bundle exec rspec spec/models
>
> docker compose -f ops/dev/docker-compose.yml up web
> # → Dashboard ActiveAdmin disponible via http://localhost:3000/admin
> ```

#### ✅ ActiveAdmin génère automatiquement
- Contrôleurs admin (`app/admin/events.rb`, `app/admin/routes.rb`, etc.)
- Routes admin (`/admin/events`, `/admin/routes`, `/admin/attendances`, etc.)
- Vues admin (index, show, form, filters, bulk actions)
- **ZÉRO travail manuel de CRUD admin** ✅

---

### Jour 12-13 : Customisation ActiveAdmin

- [ ] Configurer colonnes visibles (index, show, form)
- [ ] Filtres simples (email, role, created_at, status, date) - utilisables par bénévoles
- [x] Exposer `Role` dans ActiveAdmin (ressource dédiée + policy Pundit) pour gérer la hiérarchie/rôles via l'UI
- [ ] Bulk actions (sélectionner 10 événements = modifier status en 1 clic)
- [ ] Export CSV/PDF intégré (out-of-the-box)
- [ ] Dashboard validation organisateurs
- [ ] Actions personnalisées (validate_organizer!, publish_event, cancel_event)

---

### Jour 14-15 : Tests Admin & Finalisation

- [ ] Tests admin controllers (RSpec)
- [ ] Integration tests (admin actions via Capybara)
- [ ] Permissions Pundit testées
- [ ] Coverage >70% maintenu
- [ ] Audit sécurité (Brakeman)
- [ ] Optimisation requêtes (N+1 queries)

---

## 📋 CHECKLIST RAPIDE

### Modèles Phase 2
- [x] Route ✅
- [x] Event ✅
- [x] Attendance ✅
- [x] OrganizerApplication ✅
- [x] Partner ✅
- [x] ContactMessage ✅
- [x] AuditLog ✅

### Tests RSpec
- [x] Route (validations, associations)
- [x] Event (validations, associations, scopes)
- [x] Attendance (validations, associations)
- [x] OrganizerApplication (validations, workflow)
- [x] Partner (validations)
- [x] ContactMessage (validations)
- [x] AuditLog (validations, associations, scopes)
- [x] Coverage >70%

### ActiveAdmin (Jour 11+)
- [x] Installation
- [x] Resource `Role` exposée + policy Pundit dédiée
- [ ] Autres resources générées (`events`, `attendances`, etc.)
- [ ] Customisation (filtres, bulk actions, exports)
- [ ] Tests admin
- [ ] Permissions Pundit

---

## 🎯 PROCHAINES ÉTAPES

1. **MAINTENANT** : Renforcer la couverture de tests (Events/Attendances + policies) et finaliser factories
2. **ENSUITE** : Générer/affiner les resources ActiveAdmin restantes (events, attendances, etc.)
3. **Jour 12-13** : Customiser ActiveAdmin (UX, filtres, batch, exports)
4. **Jour 14-15** : Tests admin + finalisation (Brakeman, Bullet, accessibilité)

---

## 📚 RESSOURCES

- **Schema DB** : `ressources/db/dbdiagram.md`
- **Documentation modèles** : `docs/03-architecture/domain/models.md`
- **Migrations Phase 2** : `docs/04-rails/phase2-migrations-models.md`
- **Guide technique** : `GUIDE_IMPLEMENTATION.md`

---

**Document créé le** : 2025-01-20  
**Version** : 1.0 (Document unique simplifié)

