# Stratégie de tests (RSpec)

Le projet s'appuie sur **RSpec** pour l'ensemble de la couverture de tests.  
Les specs sont regroupées dans `spec/` (modèles, contrôleurs, features, etc.).

## Types de tests
- **Modèles** : validations, associations, scopes (Phase 2 : `Event`, `Route`, `Attendance`, `Partner`, `AuditLog`, etc.)
- **Services / Jobs** : comportements métiers isolés
- **Contrôleurs / APIs** : réponses HTTP, redirections, droits (à couvrir en priorité après ActiveAdmin)
- **System / Features** : parcours critiques (inscription événements, commandes e-commerce)

## Exécution

### Avec Docker Compose (environnement projet)

```bash
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
  -e RAILS_ENV=test \
  web bundle exec rspec
```

> Astuce : ajouter `-- spec/models` ou un chemin particulier pour limiter la portée.

### Reset base de test (à faire après chaque migration)

```bash
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
  -e RAILS_ENV=test \
  web bash -lc "bundle exec rails db:drop db:create db:schema:load"
```

## Couverture actuelle (Nov 2025)

- **Total** : 154 exemples unitaires, 0 échec ✅
- **Models** : 135 exemples (validations, associations, scopes, counter cache, max_participants)
- **Policies** : 12 exemples (EventPolicy - permissions, scopes, attend, can_attend)
- **Requests** : 19 exemples (Events, Attendances, Pages)
- **Mailers** : 19 exemples (EventMailer - attendance_confirmed, attendance_cancelled, event_reminder)

**Note** : 10 tests Capybara (system/feature) nécessitent ChromeDriver dans Docker (non configuré - priorité basse)

### Détails par catégorie

#### Models (135 exemples)
- `spec/models/attendance_spec.rb` - Validations, associations, scopes, counter cache, max_participants validation
- `spec/models/audit_log_spec.rb` - Validations, scopes, filtres
- `spec/models/contact_message_spec.rb` - Validations, format email
- `spec/models/event_spec.rb` - Validations, scopes (upcoming, past, published), max_participants (unlimited?, full?, remaining_spots, has_available_spots?)
- `spec/models/option_type_spec.rb` - Validations, associations
- `spec/models/option_value_spec.rb` - Validations, associations
- `spec/models/order_item_spec.rb` - Associations
- `spec/models/order_spec.rb` - Associations, callbacks
- `spec/models/organizer_application_spec.rb` - Validations, workflow status
- `spec/models/partner_spec.rb` - Validations, scopes (active, inactive)
- `spec/models/payment_spec.rb` - Associations, callbacks
- `spec/models/product_category_spec.rb` - Validations, associations
- `spec/models/product_spec.rb` - Validations, associations
- `spec/models/product_variant_spec.rb` - Validations, associations
- `spec/models/role_spec.rb` - Validations, associations
- `spec/models/route_spec.rb` - Validations, associations
- `spec/models/user_spec.rb` - Validations, associations, callbacks
- `spec/models/variant_option_value_spec.rb` - Validations, associations

#### Policies (12 exemples)
- `spec/policies/event_policy_spec.rb` - Permissions (show, create, update, destroy, attend, can_attend, user_has_attendance?), scopes par rôle, validation max_participants

#### Requests (19 exemples)
- `spec/requests/events_spec.rb` - CRUD public, inscriptions/désinscriptions (avec emails)
- `spec/requests/attendances_spec.rb` - Page "Mes sorties", authentification
- `spec/requests/pages_spec.rb` - Pages publiques (home, association)

#### Mailers (19 exemples)
- `spec/mailers/event_mailer_spec.rb` - Emails de confirmation d'inscription/désinscription, rappels

### Prochaines étapes
- Tests Capybara pour parcours utilisateur complet
- Tests admin (ActiveAdmin + Pundit)
- Tests d'intégration pour notifications e-mail

## Données de test

### FactoryBot

Le projet utilise **FactoryBot** pour générer des données de test. Les factories sont définies dans `spec/factories/` :

- `spec/factories/roles.rb` - Rôles (visitor, member, organizer, admin, superadmin)
- `spec/factories/users.rb` - Utilisateurs avec traits par rôle
- `spec/factories/routes.rb` - Parcours roller
- `spec/factories/events.rb` - Événements (traits: published, upcoming, past, with_route, with_limit, unlimited)
- `spec/factories/attendances.rb` - Inscriptions aux événements

**Usage** :
```ruby
# Créer un utilisateur avec rôle organizer
user = create(:user, :organizer)

# Créer un événement publié à venir
event = create(:event, :published, :upcoming)

# Créer un événement avec limite de participants
event = create(:event, :published, :with_limit, max_participants: 20)

# Créer un événement illimité
event = create(:event, :published, :unlimited)

# Créer une inscription
attendance = create(:attendance, user: user, event: event)
```

**Bonnes pratiques** :
- Préférer `FactoryBot` plutôt que les seeds lourds
- Éviter les dépendances croisées entre specs (nettoyage DB via transactions)
- Utiliser les traits pour variantes courantes (ex: `:published`, `:upcoming`)
- Utiliser `build` au lieu de `create` quand la persistance n'est pas nécessaire

## Bonnes pratiques

### Général
- 1 scénario = 1 comportement validé (matcher explicite).
- Données réalistes et proches des cas d’usage.
- Tenir la base de test isolée de `db/seeds` (utiliser `db:schema:load`).
- Ajouter systématiquement la commande RSpec exécutée dans les PRs / docs de livraison.

### Authentification dans les Tests
- **Request Specs** : Utiliser `login_user(user)` helper (utilise `post user_session_path`)
- **System Specs** : Utiliser `login_as(user)` helper (simule la connexion via l'UI)
- **Controller Specs** : Utiliser `sign_in user` (fonctionne)

### Tests avec ActiveJob / ActionMailer
- Inclure `ActiveJob::TestHelper` dans les tests request qui utilisent `deliver_later`
- Utiliser `perform_enqueued_jobs` pour exécuter les jobs enqueued
- Vérifier les emails avec `ActionMailer::Base.deliveries`

### FactoryBot
- Toujours définir les traits de date (`:upcoming`, `:past`) dans les factories
- Utiliser les traits au lieu de spécifier manuellement les valeurs
- Créer des traits réutilisables pour les cas courants

**Documentation complète** : Voir `docs/05-testing/rspec-best-practices.md` pour plus de détails.
