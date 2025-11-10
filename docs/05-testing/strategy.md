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

## Couverture actuelle (10/11/2025)

- **Total** : 106 exemples, 0 échec
- **Models** : 75 exemples (validations, associations, scopes)
- **Policies** : 12 exemples (EventPolicy - permissions, scopes)
- **Requests** : 19 exemples (Events, Attendances, Pages)

### Détails par catégorie

#### Models (75 exemples)
- `spec/models/attendance_spec.rb` - Validations, associations, scopes
- `spec/models/audit_log_spec.rb` - Validations, scopes, filtres
- `spec/models/contact_message_spec.rb` - Validations, format email
- `spec/models/event_spec.rb` - Validations, scopes (upcoming, past, published)
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
- `spec/policies/event_policy_spec.rb` - Permissions (show, create, update, destroy, attend), scopes par rôle

#### Requests (19 exemples)
- `spec/requests/events_spec.rb` - CRUD public, inscriptions/désinscriptions
- `spec/requests/attendances_spec.rb` - Page "Mes sorties", authentification
- `spec/requests/pages_spec.rb` - Pages publiques (home, association)

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
- `spec/factories/events.rb` - Événements (traits: published, upcoming, past, with_route)
- `spec/factories/attendances.rb` - Inscriptions aux événements

**Usage** :
```ruby
# Créer un utilisateur avec rôle organizer
user = create(:user, :organizer)

# Créer un événement publié à venir
event = create(:event, :published, :upcoming)

# Créer une inscription
attendance = create(:attendance, user: user, event: event)
```

**Bonnes pratiques** :
- Préférer `FactoryBot` plutôt que les seeds lourds
- Éviter les dépendances croisées entre specs (nettoyage DB via transactions)
- Utiliser les traits pour variantes courantes (ex: `:published`, `:upcoming`)
- Utiliser `build` au lieu de `create` quand la persistance n'est pas nécessaire

## Bonnes pratiques
- 1 scénario = 1 comportement validé (matcher explicite).
- Données réalistes et proches des cas d’usage.
- Tenir la base de test isolée de `db/seeds` (utiliser `db:schema:load`).
- Ajouter systématiquement la commande RSpec exécutée dans les PRs / docs de livraison.
