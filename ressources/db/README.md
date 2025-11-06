# Base de données – Checklists d’implantation

Ce dossier contient les schémas dbdiagram et la checklist modulaire pour déployer la DB par étapes. Chaque bloc peut être implanté indépendamment; coche à mesure de l’avancement.

> Schémas:
> - `dbdiagram.shop.md` → Users + Boutique
> - `dbdiagram.shop_events.md` → Users + Boutique + Événements (complet)
> - `dbdiagram.md` → version de travail globale (peut diverger)

## Bloc 0 — Setup Rails + PostgreSQL
- [ ] Fichier `app/config/database.yml` configuré (dev/test/prod)
- [ ] Création des DB locales (`rails db:create`)
- [ ] Ajout gem `pg` (déjà présent)
- [ ] Stratégie UUID (si souhaitée) décidée et documentée

## Bloc 1 — Rôles & Utilisateurs (obligatoire)
Tables: `roles`, `users`
- [ ] Migrations créées
- [ ] Index/unique: `roles.code`, `users.email`
- [ ] FK: `users.role_id → roles.id`
- [ ] Seeds rôles (USER=10, REGISTERED=20, INITIATION=30, ORGANIZER=40, MODERATOR=50, ADMIN=60, SUPERADMIN=70)
- [ ] Auth (has_secure_password ou devise) choisie et branchée
- [ ] Vérification email (bool `email_verified`) gérée

## Bloc 2 — Boutique (catalogue)
Tables: `product_categories`, `products`
- [ ] Migrations créées
- [ ] Index: `products(category_id)`, `(is_active, slug)`; uniques: `slug`
- [ ] FK: `products.category_id → product_categories.id`
- [ ] Seeds catégories/produits de démo

## Bloc 3 — Variantes produits (tailles/couleurs)
Tables: `option_types`, `option_values`, `product_variants`, `variant_option_values`
- [ ] Migrations créées
- [ ] Uniques: `option_types.name`, `product_variants.sku`, `(variant_id, option_value_id)`
- [ ] Index: `option_values.option_type_id`, `product_variants.product_id`
- [ ] FK: `option_values.option_type_id → option_types.id`
- [ ] FK: `product_variants.product_id → products.id`
- [ ] FK: `variant_option_values.variant_id → product_variants.id`
- [ ] FK: `variant_option_values.option_value_id → option_values.id`
- [ ] Stock: utiliser `product_variants.stock_qty` comme source de vérité

## Bloc 4 — Commandes & Paiements
Tables: `orders`, `order_items`, `payments`
- [ ] Migrations créées
- [ ] FK: `orders.user_id → users.id`, `orders.payment_id → payments.id`
- [ ] FK: `order_items.order_id → orders.id`, `order_items.variant_id → product_variants.id`
- [ ] États de commande: pending, paid, canceled, shipped
- [ ] Provider paiements: stripe, helloasso, free
- [ ] Calculs totaux cohérents (sommes des lignes)

## Bloc 5 — Panel Admin (DB prérequis)
- [ ] Rôles/permissions: Admin (≥60) accède au CRUD catalogue/commandes
- [ ] Journalisation optionnelle: `audit_logs` (voir Bloc 7)

## Bloc 6 — Événements (optionnel / phase ultérieure)
Tables: `routes`, `events`, `attendances`
- [ ] Migrations créées
- [ ] Index: `(status, start_at)`, `events.route_id`, `attendances(user_id, event_id) UNIQUE`
- [ ] FK: `events.creator_user_id → users.id`, `events.route_id → routes.id`
- [ ] FK: `attendances.user_id → users.id`, `attendances.event_id → events.id`, `attendances.payment_id → payments.id`

## Bloc 7 — Partenaires, Contact, Audit (optionnels)
Tables: `partners`, `contact_messages`, `audit_logs`
- [ ] Migrations créées
- [ ] Index: `audit_logs(actor_user_id)`, `(target_type, target_id)`
- [ ] FK: `audit_logs.actor_user_id → users.id`

## Bonnes pratiques
- [ ] Montants en centimes (`*_cents`), `currency` par défaut `EUR`
- [ ] Contraintes côté DB: NOT NULL, UNIQUE, CHECK (ex: durée multiple de 5)
- [ ] Horodatage: `created_at`, `updated_at` ajoutés quand pertinent
- [ ] Données seed pour démarrer l’app (rôles, un admin, quelques produits)

## Commandes utiles (Rails)
```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
bin/rails db:reset
```

## Synchronisation schémas
- [ ] `dbdiagram.shop.md` alimente les migrations de la Boutique
- [ ] `dbdiagram.shop_events.md` ajoute le module Événements
- [ ] Toute divergence est documentée dans ce README


