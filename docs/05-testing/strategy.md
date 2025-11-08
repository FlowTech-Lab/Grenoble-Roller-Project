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
  -e BUNDLE_PATH=/usr/local/bundle \
  -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
  -e RAILS_ENV=test \
  web bundle exec rspec
```

> Astuce : ajouter `-- spec/models` ou un chemin particulier pour limiter la portée.

### Reset base de test (à faire après chaque migration)

```bash
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
  -e RAILS_ENV=test \
  web bundle exec rails db:drop db:create db:schema:load
```

## Couverture actuelle (08/11/2025)

- `spec/models` : 75 exemples, 0 échec (commande exécutée et validée)
- Prochaine étape : compléter tests admin (Pundit + ActiveAdmin), contrôleurs et features Phase 2.

## Données de test
- Préférer `FactoryBot` (ou helpers dédiés) plutôt que les seeds lourds.
- Éviter les dépendances croisées entre specs (nettoyage DB via transactions).

## Bonnes pratiques
- 1 scénario = 1 comportement validé (matcher explicite).
- Données réalistes et proches des cas d’usage.
- Tenir la base de test isolée de `db/seeds` (utiliser `db:schema:load`).
- Ajouter systématiquement la commande RSpec exécutée dans les PRs / docs de livraison.
