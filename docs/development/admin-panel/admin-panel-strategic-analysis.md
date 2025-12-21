# Analyse Stratégique - Admin Panel

**Date** : 2025-12-21  
**Contexte** : Réponses aux questions stratégiques pour l'amélioration de l'admin panel  
**Base** : Analyse complète du codebase, documentation, et structure actuelle

---

## ⚠️ IMPORTANT - DASHBOARD ADMIN UNIQUEMENT

**L'AdminPanel est un dashboard ADMIN, pas utilisateur.**

### Ce que l'AdminPanel fait :
- ✅ Gère **TOUTES les données** de l'application (tous les utilisateurs, toutes les commandes, tous les produits)
- ✅ Accessible **uniquement aux ADMIN/SUPERADMIN** (niveau 60+)
- ✅ Vue globale pour la gestion administrative

### Ce que les utilisateurs ont déjà (ne PAS refaire) :
- ✅ `/orders` → "Mes commandes" (`OrdersController#index` - affiche `current_user.orders`)
- ✅ `/memberships` → "Mes adhésions" (`MembershipsController#index` - affiche `current_user.memberships`)
- ✅ `/attendances` → "Mes sorties" (`AttendancesController#index` - affiche `current_user.attendances`)

**Références** :
- `app/controllers/orders_controller.rb:24` → `current_user.orders`
- `app/controllers/memberships_controller.rb:6` → `current_user.memberships`
- `app/controllers/attendances_controller.rb:4` → `current_user.attendances`

**Conclusion** : L'AdminPanel doit gérer **TOUTES les commandes** (`Order.all`), **TOUTES les adhésions** (`Membership.all`), etc. - pas seulement celles de l'utilisateur connecté.

---

## A) CONTEXTE & ÉQUIPE

### Qui va utiliser cet admin panel ?

**Réponse** : D'après la documentation (`docs/04-rails/admin-panel-research.md`), l'admin panel est conçu pour des **bénévoles non-techniques** de l'association Grenoble Roller.

**Utilisateurs actuels** :
- **2 comptes admin** identifiés dans les seeds :
  - `admin@roller.com` (ADMIN - niveau 60)
  - `T3rorX@hotmail.fr` (SUPERADMIN - niveau 70)

**Niveaux d'expertise technique** :
- **Bénévoles** : Non-techniques (interface graphique uniquement)
- **Admins** : Peu techniques (peuvent gérer via ActiveAdmin)
- **SuperAdmin** : Technique (développeur)

**Rôles distincts** (ordre par niveau) :
- **USER** (niveau 10) : Utilisateur de base
- **REGISTERED** (niveau 20) : Membre inscrit
- **INITIATION** (niveau 30) : Accès initiations - liste des présents et matériel demandé
- **ORGANIZER** (niveau 40) : Création/gestion de SES événements uniquement
- **MODERATOR** (niveau 50) : Modération des événements
- **ADMIN** (niveau 60) : Gestion complète via ActiveAdmin + AdminPanel
- **SUPERADMIN** (niveau 70) : Accès total, gestion technique

**Source** : `app/models/role.rb`, `db/seeds.rb`, `docs/04-rails/admin-panel-research.md`

---

### Timeline réaliste

**Réponse** : D'après la méthodologie Shape Up utilisée (`docs/02-shape-up/shape-up-methodology.md`) :

- **Appetite fixe** : 6 semaines (3 semaines Building + 1 semaine Cooldown)
- **Scope flexible** : Si pas fini → réduire scope, pas étendre deadline
- **Phase 1 rapide vs solution complète** : Approche Shape Up = solution complète mais scope réduit si nécessaire

**État actuel** :
- ✅ Phase 1 (E-commerce) : TERMINÉ
- ✅ Phase 2 (Événements) : TERMINÉ (166+ tests RSpec, 0 échec)
- ⏳ Améliorations ActiveAdmin : En cours (80% selon `docs/06-events/README.md`)

**Semaines avant production** :
- Non spécifié dans la documentation
- Recommandation : Finaliser les tests Capybara en préprod avant production

**Source** : `docs/02-shape-up/shape-up-methodology.md`, `docs/development/phase2/cycle-01-phase-2-plan.md`

---

### Technos préférées

**Réponse** : D'après la documentation et le code :

**Stack actuelle** :
- ✅ **Rails 8.1.1** (monolithe)
- ✅ **Bootstrap 5** + **Stimulus** + **Turbo** (Hotwire)
- ✅ **ActiveAdmin** (déjà installé et configuré)
- ✅ **Pundit** (autorisations)
- ✅ **PostgreSQL 16**

**Approche recommandée** :
- ✅ **100% Rails** (ViewComponent, Stimulus, Hotwire) - **RECOMMANDÉ**
- ❌ Séparation API Rails + Front moderne (React, Vue) - **NON recommandé** (rabbit hole évité)
- ❌ Hybrid approach (Rails + HTMX) - **NON nécessaire** (Turbo déjà présent)

**Justification** :
- Documentation explicite : "Rabbit Holes Évités" → Pas de microservices, pas d'API publique
- ActiveAdmin déjà installé et fonctionnel
- Stack cohérente et maintenable pour bénévoles

**Source** : `README.md`, `docs/02-shape-up/shape-up-methodology.md`, `docs/04-rails/admin-panel-research.md`

---

## B) GESTION DES PRODUITS/VARIANTES

### Flux de création produit complexe ?

**Réponse** : **OUI, flux complexe actuellement** avec ActiveAdmin.

**Structure actuelle** :
1. Créer le **Produit** (nom, description, catégorie, image, prix de base)
2. Créer les **Variantes** séparément (SKU, prix, stock, options)
3. Associer les **Options** (OptionType/OptionValue) aux variantes via checkboxes

**Problème identifié** :
- ❌ Pas de création en une seule étape (produit + variantes) → ✅ **RÉSOLU** : Génération automatique lors de la création
- ❌ Interface ActiveAdmin actuelle : formulaire produit → puis formulaire variante séparé → ✅ **RÉSOLU** : Nouveau formulaire AdminPanel
- ❌ Pas de génération automatique de variantes → ✅ **RÉSOLU** : `ProductVariantGenerator` créé
- ✅ **VÉRIFIÉ** : Service `ProductVariantGenerator` créé dans `app/services/product_variant_generator.rb`
- ✅ **NOUVEAU** : Création manuelle de variantes possible (bouton "Nouvelle variante" dans show produit)

**Exemple concret** :
- Produit "Veste Grenoble Roller" → 3 couleurs × 3 tailles = **9 variantes à créer manuellement**
- Chaque variante : SKU unique, prix, stock, image optionnelle

**Source** : `app/admin/products.rb`, `app/admin/product_variants.rb`, `app/models/product.rb`, `app/models/product_variant.rb`

---

### Un produit → combien de variantes en moyenne ?

**Réponse** : D'après les seeds (`db/seeds.rb`) :

**Exemples réels** :
- **Casque LED** : 3 variantes (S, M, L)
- **Casquette** : 1 variante (taille unique, blanche)
- **Sac à dos + Roller** : 4 variantes (4 couleurs)
- **T-shirt** : 3 variantes (S, M, L)
- **Veste** : 9 variantes (3 couleurs × 3 tailles)

**Moyenne** : **3-9 variantes par produit** (selon les exemples)

**Source** : `db/seeds.rb` (lignes 265-449)

---

### Les variantes ont-elles des images différentes ?

**Réponse** : **OUI, supporté mais pas toujours utilisé**.

**Structure** :
- Chaque `ProductVariant` peut avoir :
  - `image` (Active Storage) - **Recommandé**
  - `image_url` (string) - **Déprécié, pour transition**

**Exemple dans les seeds** :
- **Veste** : Images différentes par couleur (`veste noir.avif`, `veste bleu.avif`, `veste.png`)
- **Autres produits** : Image principale partagée

**Validation** : `image_or_image_url_present` (au moins une image requise)

**Source** : `app/models/product_variant.rb`, `db/seeds.rb` (lignes 422-427)

---

### Chaque variante a son propre SKU, prix, stock ?

**Réponse** : **OUI, absolument**.

**Structure** :
- `ProductVariant` :
  - `sku` : **Unique, obligatoire** (ex: "VESTE-NOIR-M")
  - `price_cents` : **Obligatoire** (peut différer du produit parent)
  - `stock_qty` : **Géré uniquement au niveau variante** (pas au niveau produit)
  - `currency` : EUR par défaut
  - `is_active` : Actif/inactif

**Exemple** :
- Veste L Rouge : SKU "VESTE-RED-L", prix 40€, stock 5
- Veste M Bleu : SKU "VESTE-BLUE-M", prix 40€, stock 10

**Source** : `app/models/product_variant.rb`, `app/admin/product_variants.rb`, `db/schema.rb`

---

### Options (OptionType/OptionValue) - c'est quoi ?

**Réponse** : **Système flexible d'options prédéfinies**.

**Structure** :
- `OptionType` : Type d'option (ex: "size", "color")
  - `name` : Code technique (ex: "size")
  - `presentation` : Nom affiché (ex: "Taille")
- `OptionValue` : Valeur d'option (ex: "M", "Rouge")
  - `value` : Code technique (ex: "M")
  - `presentation` : Nom affiché (ex: "Taille M")
  - `option_type_id` : Référence au type

**Exemples dans les seeds** :
- **Taille** : 37, 39, 41 (chaussures) + S, M, L (textile)
- **Couleur** : Red, Blue, Black, White, Violet

**Combien de types d'options max par produit ?**
- **Non limité** dans le code
- **Pratique** : 1-3 types (ex: Taille, Couleur, Matériel)

**Les options sont-elles prédéfinies ou créées au vol ?**
- **Prédéfinies** dans les seeds
- **Créables** via ActiveAdmin (`app/admin/option_types.rb`, `app/admin/option_values.rb`)

**Source** : `app/models/option_type.rb`, `app/models/option_value.rb`, `db/seeds.rb` (lignes 229-254)

---

### Besoin d'import/export ?

**Réponse** : **NON implémenté actuellement, mais mentionné dans la doc**.

**État actuel** :
- ❌ Pas d'import Excel/CSV visible
- ❌ Pas d'export Excel/CSV visible
- ✅ ActiveAdmin supporte l'export CSV **out-of-the-box** (mais pas configuré)
- ❌ **VÉRIFIÉ** : Pas de service `ProductImporter` dans `app/services/`
- ❌ **VÉRIFIÉ** : Pas de service `OrderExporter` dans `app/services/`
- ❌ **VÉRIFIÉ** : Aucune mention d'export dans `app/admin/orders.rb`

**Documentation** :
- `docs/04-rails/admin-panel-research.md` mentionne "Export CSV/PDF intégré (out-of-the-box)"
- `docs/02-shape-up/building/cycle-01-phase-2-plan.md` liste "Exports CSV/PDF" comme **À FAIRE**

**Recommandation** :
- **Import** : Utile pour 100+ produits (mais pas prioritaire actuellement)
- **Export** : Utile pour partenaires/trésorier (mais pas implémenté)

**Source** : `docs/04-rails/admin-panel-research.md`, `docs/development/phase2/cycle-01-phase-2-plan.md`

---

## C) ÉVÉNEMENTS & INITIATIONS

### Événement récurrent - complexité ?

**Réponse** : **Champs existent dans le schéma mais NON utilisés actuellement**.

**Structure dans le schéma** :
```ruby
# db/schema.rb (lignes 110-120)
t.boolean "is_recurring", default: false
t.string "recurring_day"
t.date "recurring_end_date"
t.date "recurring_start_date"
t.string "recurring_time"
```

**État actuel** :
- ❌ Pas de logique de récurrence dans `app/models/event.rb`
- ❌ Pas de création automatique d'instances
- ❌ Pas de copier-coller manuel facilité

**Recommandation** :
- **Création automatique** : Job récurrent pour créer les instances (complexe)
- **Copier-coller manuel** : Plus simple, recommandé pour MVP

**Source** : `db/schema.rb`, `app/models/event.rb`

---

### Gestion des attendances

**Réponse** : **Partiellement implémenté**.

**Rappels automatiques** :
- ✅ **OUI** : `EventReminderJob` envoie des rappels **la veille à 19h** pour les événements du lendemain
- ✅ Option `wants_reminder` dans les attendances (case à cocher, activée par défaut)
- ✅ Email de rappel (`EventMailer.event_reminder`)

**Gestion des no-show** :
- ✅ **OUI** : Statut `no_show` dans `Attendance` (enum: registered, paid, canceled, present, no_show)
- ⚠️ Pas de logique automatique de détection (marquage manuel)

**Notes d'équipement per participant** :
- ✅ **OUI** : Champ `equipment_note` dans `Attendance` (text)
- ⚠️ Pas d'affichage dans ActiveAdmin actuellement

**Source** : `app/models/attendance.rb`, `app/jobs/event_reminder_job.rb`, `docs/06-events/email-notifications-implementation.md`

---

### Routes associées

**Réponse** : **OUI, routes réutilisables implémentées**.

**Structure** :
- `Route` model : Parcours prédéfinis (nom, distance, difficulté, elevation, safety_notes)
- `Event` → `belongs_to :route, optional: true`
- Routes réutilisables d'un événement à l'autre : **OUI**

**Upload GPX direct** :
- ❌ **NON implémenté** actuellement
- ✅ Champ `gpx_url` dans `Route` (string, URL externe) - **VÉRIFIÉ** : `app/models/route.rb` ligne 15
- ✅ Champ `map_image_url` dans `Route` (string, URL externe)
- ✅ Active Storage `map_image` (attached) - **VÉRIFIÉ** : `app/models/route.rb` ligne 7 (`has_one_attached :map_image`)
- ❌ **VÉRIFIÉ** : Pas de `gpx_file` attachment (seulement `map_image`)
- ❌ **VÉRIFIÉ** : Pas de parsing GPX automatique (pas de méthode `parse_gpx_data`)

**Recommandation** :
- Ajouter upload GPX via Active Storage (`has_one_attached :gpx_file`)
- Parser GPX pour extraire distance/élévation automatiquement

**Source** : `app/models/route.rb`, `app/models/event.rb`, `db/schema.rb`

---

## D) DONNÉES & ANALYTICS

### Dashboard KPIs pour admin ?

**Réponse** : **OUI, dashboard ActiveAdmin existe avec KPIs basiques**.

**KPIs actuels** (`app/admin/dashboard.rb`) :
- ✅ Événements à valider
- ✅ Utilisateurs inscrits
- ✅ Commandes en attente
- ✅ CA boutique (commandes payées)
- ✅ Adhésions actives
- ✅ Adhésions en attente
- ✅ Revenus adhésions (saison courante)
- ✅ CA total (boutique + adhésions)

**KPIs manquants** :
- ❌ Revenu daily/weekly/monthly (pas de breakdown temporel)
- ❌ Taux de remplissage événements (pas de calcul automatique)
- ❌ Produits best-sellers (pas de calcul)
- ❌ Churn rate memberships (pas de calcul)
- ❌ **VÉRIFIÉ** : Pas de service `AdminDashboardService` dans `app/services/`
- ✅ **VÉRIFIÉ** : Dashboard ActiveAdmin existe avec KPIs basiques (`app/admin/dashboard.rb` lignes 8-129)
- ✅ **VÉRIFIÉ** : Dashboard admin_panel existe avec statistiques simples (`app/controllers/admin_panel/dashboard_controller.rb` lignes 5-13)

**Source** : `app/admin/dashboard.rb`

---

### Reporting/exports ?

**Réponse** : **NON implémenté actuellement**.

**État actuel** :
- ❌ Pas d'export Excel mensuel pour trésorier
- ❌ Pas de stats pour associés
- ✅ ActiveAdmin supporte l'export CSV **out-of-the-box** (mais pas configuré)
- ❌ **VÉRIFIÉ** : Pas de service `OrderExporter` dans `app/services/`
- ❌ **VÉRIFIÉ** : Aucune mention d'export dans `app/admin/orders.rb`

**Documentation** :
- `docs/02-shape-up/building/cycle-01-phase-2-plan.md` liste "Exports CSV/PDF" comme **À FAIRE**

**Recommandation** :
- Ajouter export CSV/Excel pour commandes, adhésions, événements
- Dashboard avec graphiques (Chartkick mentionné dans la doc)

**Source** : `docs/02-shape-up/building/cycle-01-phase-2-plan.md`, `docs/04-rails/admin-panel-research.md`

---

## E) SÉCURITÉ & PERMISSIONS

### Permissions granulaires ?

**Réponse** : **OUI, système Pundit implémenté avec rôles granulaires**.

**Structure actuelle** :

**SUPERADMIN (niveau 70)** :
- ✅ Accès total (via `Admin::ApplicationPolicy`)

**ADMIN (niveau 60)** :
- ✅ Accès total ActiveAdmin (via `Admin::ApplicationPolicy`)

**MODERATOR (niveau 50)** :
- ✅ Peut modifier le statut des événements (via `EventPolicy`)
- ✅ Peut voir tous les événements (via `EventPolicy::Scope`)

**INITIATION (niveau 30)** :
- ✅ Accès initiations - liste des présents et matériel demandé (via `Admin::InitiationPolicy`)
- ✅ Peut voir et gérer les présences des initiations (via `presences?` et `update_presences?`)
- ✅ Accès aux informations sur le matériel demandé par les participants
- ✅ Peut gérer les initiations (via `Event::InitiationPolicy#manage?` - niveau >= 30)

**ORGANIZER (niveau 40)** :
- ✅ Peut créer des événements (via `EventPolicy#create?` - niveau >= 40)
- ✅ Peut modifier SES événements (via `EventPolicy#update?` - owner check)
- ❌ Ne peut PAS modifier le statut (seuls modos+ peuvent)

**Note** : Les rôles existants (7 niveaux) sont suffisants. Seuls ADMIN/SUPERADMIN accèdent à AdminPanel pour gérer produits et commandes.

**Source** : `app/policies/application_policy.rb`, `app/policies/admin/application_policy.rb`, `app/policies/event_policy.rb`, `app/models/role.rb`

---

## F) CONTRAINTES

### Performance critique ?

**Réponse** : **NON critique actuellement, mais optimisations en cours**.

**Volume actuel** (statistiques base de données) :
- Users: **23**
- Products: **7**
- ProductVariants: **22**
- Orders: **10**
- Events: **9**
- Memberships: **15**
- Attendances: **48**

**Optimisations déjà faites** :
- ✅ Counter cache `attendances_count` sur Event
- ✅ Eager loading dans les controllers (includes)
- ✅ Bullet gem configuré (détection N+1)

**Optimisations à faire** :
- ⏳ Audit N+1 queries complet (Bullet configuré mais pas d'audit complet)
- ⏳ Index sur colonnes fréquemment utilisées
- ⏳ Pagination (non implémentée)
- ❌ **VÉRIFIÉ** : Aucune gem de pagination dans `Gemfile` (pas de `pagy` ni `kaminari`)

**Source** : Statistiques DB, `docs/02-shape-up/building/cycle-01-phase-2-plan.md`

---

### Mise à jour temps réel nécessaire (WebSocket) ?

**Réponse** : **NON, pas nécessaire actuellement**.

**État actuel** :
- ❌ Pas de WebSocket/ActionCable configuré
- ❌ Pas de mise à jour temps réel
- ✅ Polling JavaScript pour statut paiement (5 secondes pendant 1 minute)
- ✅ Cron job pour polling HelloAsso (5 minutes)

**Recommandation** :
- **NON prioritaire** : Pas de besoin identifié pour temps réel
- Polling suffisant pour les cas d'usage actuels

**Source** : Recherche dans le codebase (pas de WebSocket trouvé)

---

### Intégrations existantes à supporter ?

**Réponse** : **HelloAsso uniquement, Stripe mentionné mais pas implémenté**.

**HelloAsso** :
- ✅ **Déjà connecté et fonctionnel**
- ✅ Service `HelloassoService` complet
- ✅ Sandbox pour dev/staging, Production pour prod
- ✅ Polling automatique (cron + JS)
- ✅ Support adhésions + commandes boutique

**Stripe** :
- ⚠️ **Mentionné dans README** mais **PAS implémenté**
- ⚠️ Structure `Payment` supporte `provider: "stripe"` mais pas de service
- ⚠️ Champ `stripe_customer_id` dans `Attendance` mais pas utilisé

**PayPal** :
- ⚠️ **Mentionné dans README** mais **PAS implémenté**
- ⚠️ Structure `Payment` supporte `provider: "paypal"` mais pas de service

**Recommandation** :
- **HelloAsso** : Ne pas toucher, fonctionne bien
- **Stripe/PayPal** : À implémenter si besoin (pas prioritaire)

**Source** : `app/services/helloasso_service.rb`, `app/models/payment.rb`, `README.md`

---

## G) VÉRIFICATIONS TECHNIQUES & INCOHÉRENCES

### 1. ❌ Namespace Controllers - INCOHÉRENCE CONFIRMÉE

**État actuel** :
- ✅ **Namespace `admin_panel` existe** : `config/routes.rb` ligne 5
  ```ruby
  namespace :admin_panel, path: 'admin-panel' do
    root 'dashboard#index'
  end
  ```
- ✅ **Controllers dans `AdminPanel`** : 
  - `app/controllers/admin_panel/base_controller.rb` (module AdminPanel)
  - `app/controllers/admin_panel/dashboard_controller.rb` (module AdminPanel)
- ⚠️ **Module `Admin` séparé existe aussi** :
  - `app/controllers/admin/maintenance_toggle_controller.rb` (module Admin)

**Références** :
- `config/routes.rb` : lignes 2, 5-7
- `app/controllers/admin_panel/base_controller.rb` : ligne 1 (module AdminPanel)
- `app/controllers/admin/maintenance_toggle_controller.rb` : ligne 3 (module Admin)

**Conclusion** : **INCOHÉRENCE CONFIRMÉE** - Deux namespaces différents (`AdminPanel` et `Admin`) coexistent.

---

### 2. ❌ Paths Référencés - PARTIELLEMENT IMPLÉMENTÉ

**État actuel** :
- ✅ Routes définies : `admin_panel_root_path` dans `config/routes.rb` ligne 6
- ⚠️ **Pas de routes `admin_panel/products` ou autres ressources définies**

**Références** :
- `config/routes.rb` : ligne 6 (`admin_panel_root_path`)

**Conclusion** : **PARTIELLEMENT IMPLÉMENTÉ** - Seul le dashboard existe, pas de routes pour products/orders/etc.

---

### 3. ⚠️ Layout Héritage - NAVBAR EN DOUBLE CONFIRMÉ

**État actuel** :
- ✅ Layout admin existe : `app/views/layouts/admin.html.erb`
- ❌ **Navbar incluse dans layout** : ligne 15
  ```erb
  <%= render 'layouts/navbar' %>
  ```
- ⚠️ **Risque de doublon** si les vues incluent aussi la navbar

**Références** :
- `app/views/layouts/admin.html.erb` : ligne 15 (`render 'layouts/navbar'`)

**Conclusion** : **RISQUE CONFIRMÉ** - Navbar incluse dans layout, risque de doublon si vues l'incluent aussi.

---

### 4. ❌ Pagination - NON IMPLÉMENTÉE

**État actuel** :
- ❌ **Aucune gem de pagination trouvée** dans `Gemfile`
- ❌ Pas de `pagy` ni `kaminari` dans le Gemfile

**Références** :
- `Gemfile` : Aucune mention de `pagy` ou `kaminari`

**Conclusion** : **NON IMPLÉMENTÉ** - Aucune pagination configurée.

---

### 5. ⚠️ Helpers Namespace - NON EXISTANT

**État actuel** :
- ❌ **Aucun helper dans `app/helpers/admin/`**
- ✅ Helpers existants : `application_helper.rb`, `products_helper.rb`, etc. (pas dans namespace admin)

**Références** :
- `app/helpers/` : Aucun dossier `admin/` trouvé

**Conclusion** : **NON IMPLÉMENTÉ** - Pas de helpers dans namespace admin.

---

### 6. ✅ Routes ActiveAdmin - CONFLIT ÉVITÉ

**État actuel** :
- ✅ **ActiveAdmin configuré** : `config/routes.rb` ligne 2
  ```ruby
  ActiveAdmin.routes(self)  # Crée /admin prefix
  ```
- ✅ **Namespace admin_panel séparé** : ligne 5
  ```ruby
  namespace :admin_panel, path: 'admin-panel' do
  ```

**Références** :
- `config/routes.rb` : lignes 2, 5-7

**Conclusion** : **CONFLIT ÉVITÉ** - ActiveAdmin sur `/admin`, nouveau panel sur `/admin-panel` (chemins différents).

---

### 7. ✅ Dark Mode - FONCTIONNEL ET TOUJOURS ACCESSIBLE

**État actuel** :
- ✅ **Fonction `toggleTheme()` existe** : `app/views/layouts/application.html.erb` ligne 45
- ✅ **Toggle dans navbar principale** : `app/views/layouts/_navbar.html.erb` lignes 61-72 (bouton avec icônes sun/moon)
- ✅ **Navbar est sticky-top** : `app/views/layouts/_navbar.html.erb` ligne 11 (classe `sticky-top`) → **TOUJOURS VISIBLE**
- ✅ **Layout admin inclut navbar** : `app/views/layouts/admin.html.erb` ligne 15 (`render 'layouts/navbar'`)
- ⚠️ **Pas de toggle dans sidebar admin footer** : 
  - `app/views/admin/shared/_sidebar.html.erb` footer (lignes 332-341) ne contient pas de toggle dark mode
  - **MAIS** : Pas nécessaire car navbar sticky rend le toggle toujours accessible

**Références** :
- `app/views/layouts/application.html.erb` : lignes 43-55 (fonction toggleTheme)
- `app/views/layouts/_navbar.html.erb` : lignes 61-72 (bouton toggle avec `id="theme-toggle"` et `onclick="toggleTheme()"`)
- `app/views/layouts/_navbar.html.erb` : ligne 11 (classe `sticky-top` → navbar toujours visible)
- `app/views/layouts/admin.html.erb` : ligne 15 (inclut navbar sticky)
- `app/views/admin/shared/_sidebar.html.erb` : lignes 332-341 (footer sans toggle, mais pas nécessaire)

**Conclusion** : **FONCTIONNEL** - Dark mode fonctionne et est **toujours accessible** via navbar sticky. Ajouter un toggle dans sidebar footer est **optionnel** (amélioration UX mineure).

---

### 8. ❌ Breadcrumb Helper - NON DÉFINI

**État actuel** :
- ❌ **Pas de helper `show_breadcrumb?`** dans le codebase
- ✅ Breadcrumbs existent dans certaines vues (ex: `app/views/products/show.html.erb` ligne 7) mais pas de helper centralisé

**Références** :
- `app/views/products/show.html.erb` : lignes 7-11 (breadcrumb manuel)
- Aucun helper `show_breadcrumb?` trouvé

**Conclusion** : **NON IMPLÉMENTÉ** - Pas de helper centralisé pour breadcrumbs.

---

### 9. ⚠️ Stimulus Controller Sidebar - EXISTE MAIS BREAKPOINT HARDCODÉ

**État actuel** :
- ✅ **Controller Stimulus existe** : `app/javascript/controllers/admin/admin_sidebar_controller.js`
- ✅ **Breakpoint 992px utilisé** : ligne 9 (`window.innerWidth >= 992`)
- ⚠️ **Pas de `mobileBreakpoint` value défini** (contrairement à l'analyse qui mentionne `static values`)

**Références** :
- `app/javascript/controllers/admin/admin_sidebar_controller.js` : ligne 9 (breakpoint 992px)

**Conclusion** : **IMPLÉMENTÉ DIFFÉREMMENT** - Breakpoint hardcodé à 992px, pas de value configurable.

---

### 10. ❌ Validation Form Hybride - ENDPOINT MANQUANT

**État actuel** :
- ❌ **Pas d'endpoint `check_sku`** dans les routes
- ❌ Pas de controller `admin/product_variants_controller.rb` (ActiveAdmin gère les variants)
- ❌ Pas de méthode `check_sku` dans `app/admin/product_variants.rb`

**Références** :
- `config/routes.rb` : Pas de route `check_sku` trouvée
- `app/admin/product_variants.rb` : Existe mais pas de méthode `check_sku`

**Conclusion** : **NON IMPLÉMENTÉ** - Endpoint de validation SKU n'existe pas.

---

## H) AMÉLIORATIONS MANQUANTES (VÉRIFIÉES)

### A) Gestion Produits/Variantes - NON IMPLÉMENTÉE

**État actuel** :
- ❌ **Pas de `ProductVariantGenerator`** dans le codebase
- ✅ ActiveAdmin gère les variants manuellement : `app/admin/product_variants.rb`

**Références** :
- `app/admin/product_variants.rb` : Gestion manuelle des variants
- Aucun service `ProductVariantGenerator` trouvé dans `app/services/`

**Conclusion** : **NON IMPLÉMENTÉ** - Génération automatique de variantes n'existe pas.

---

### B) Permissions Granulaires - RÔLES EXISTANTS SUFFISANTS

**État actuel** :
- ✅ **Modèle Role existe** : `app/models/role.rb`
- ✅ **7 rôles implémentés** : SUPERADMIN (70), ADMIN (60), MODERATOR (50), ORGANIZER (40), INITIATION (30), REGISTERED (20), USER (10)
- ✅ **Policies implémentées** : `AdminPanel::BasePolicy`, `AdminPanel::ProductPolicy`, `AdminPanel::OrderPolicy`
- ✅ **Seuls ADMIN/SUPERADMIN** accèdent à AdminPanel (niveau 60+)
- ✅ **VÉRIFIÉ** : Rôles en base : USER (10), REGISTERED (20), INITIATION (30), ORGANIZER (40), MODERATOR (50), ADMIN (60), SUPERADMIN (70)

**Références** :
- `app/models/role.rb` : Modèle fonctionnel
- `app/policies/admin_panel/` : Policies créées et fonctionnelles
- Base de données : 7 rôles présents et vérifiés

**Conclusion** : **IMPLÉMENTÉ** - Les rôles existants sont suffisants. Seuls ADMIN/SUPERADMIN (niveau 60+) gèrent produits et commandes via AdminPanel. Pas besoin de rôles supplémentaires (PRODUCT_MANAGER/SUPPORT).

---

### C) Exports Excel/CSV - NON IMPLÉMENTÉS

**État actuel** :
- ❌ **Pas de service `OrderExporter`** dans le codebase
- ❌ Pas d'export CSV/Excel dans ActiveAdmin configuré
- ✅ ActiveAdmin supporte l'export CSV out-of-the-box mais pas configuré
- ❌ Aucune mention d'export dans `app/admin/orders.rb`

**Références** :
- `app/services/` : Seulement `email_security_service.rb` et `helloasso_service.rb`
- `app/admin/orders.rb` : Aucune mention d'export trouvée

**Conclusion** : **NON IMPLÉMENTÉ** - Exports CSV/Excel n'existent pas.

---

### D) Dashboard KPIs - BASIQUES EXISTANTS

**État actuel** :
- ✅ **Dashboard ActiveAdmin existe** : `app/admin/dashboard.rb`
- ✅ **KPIs basiques implémentés** : lignes 8-129
  - Événements à valider
  - Utilisateurs
  - Commandes en attente
  - CA boutique
  - Adhésions actives/en attente
  - Revenus adhésions
  - CA total
- ❌ **Pas de service `AdminDashboardService`** pour KPIs temporels
- ❌ Pas de breakdown daily/weekly/monthly
- ❌ Pas de taux de remplissage événements automatique
- ❌ Pas de produits best-sellers

**Références** :
- `app/admin/dashboard.rb` : KPIs basiques lignes 8-129
- `app/controllers/admin_panel/dashboard_controller.rb` : Statistiques simples lignes 5-13

**Conclusion** : **PARTIELLEMENT IMPLÉMENTÉ** - KPIs basiques existent mais pas de service avancé ni de métriques temporelles.

---

### E) Import CSV/Excel - NON IMPLÉMENTÉ

**État actuel** :
- ❌ **Pas de service `ProductImporter`** dans le codebase
- ❌ Pas d'action `import` dans les controllers admin

**Références** :
- `app/services/` : Pas de `ProductImporter`
- `app/admin/products.rb` : À vérifier pour action import

**Conclusion** : **NON IMPLÉMENTÉ** - Import CSV/Excel n'existe pas.

---

### F) Upload GPX Direct - PARTIELLEMENT IMPLÉMENTÉ

**État actuel** :
- ✅ **Modèle Route existe** : `app/models/route.rb`
- ✅ **Champ `gpx_url` existe** : ligne 15 (dans ransackable_attributes)
- ✅ **Active Storage `map_image` supporté** : ligne 7 (`has_one_attached :map_image`)
- ❌ **Pas de `gpx_file` attachment** (seulement `map_image`)
- ❌ **Pas de parsing GPX automatique** (pas de `parse_gpx_data`)

**Références** :
- `app/models/route.rb` : lignes 7, 15 (map_image et gpx_url)
- Pas de `has_one_attached :gpx_file` trouvé

**Conclusion** : **PARTIELLEMENT IMPLÉMENTÉ** - Support GPX via URL et image, mais pas d'upload direct ni de parsing automatique.

---

## ⚠️ SIMPLIFICATIONS & RECOMMANDATIONS (2025-12-21)

### **Décisions stratégiques :**

1. **ProductTemplate & OptionSets → SKIP** ⚠️
   - **Raison** : Overkill pour le cas d'usage actuel (3-5 produits MAX)
   - **Alternative** : Utiliser `OptionType` directement (existe déjà)
   - **Futur** : À ajouter dans 6-12 mois si besoin réel apparaît

2. **Upload de fichiers uniquement** ✅
   - **Décision** : Supprimer les liens `image_url`, seulement upload via Active Storage
   - **Migration** : Script de migration `image_url` → Active Storage (voir `flux-utilisateur-boutique.md`)

3. **Workflow Order amélioré** ✅
   - **Ajout** : Reserve/release stock avec `inventories` table
   - **Workflow** : Réserver à la création, libérer si annulé, déduire si expédié

4. **GRID éditeur simplifié** ✅
   - **Améliorations** : Validation client, debounce, optimistic locking
   - **Complexité** : Réduite pour v1 (pas d'édition inline complexe)

5. **Estimation révisée** 📊
   - **Initiale** : 5 semaines
   - **Réaliste** : 6-8 semaines
   - **Minimal Viable** : 4 semaines (80% de la valeur)

> 📄 **Document détaillé** : Voir `docs/development/admin-panel/flux-utilisateur-boutique.md` pour l'architecture complète et les migrations.

---

## 📋 RÉSUMÉ DES VÉRIFICATIONS

| Point | État | Référence Fichier |
|-------|------|-------------------|
| 1. Namespace Controllers | ❌ Incohérence | `config/routes.rb:2,5` + `app/controllers/admin_panel/` + `app/controllers/admin/` |
| 2. Paths Référencés | ⚠️ Partiel | `config/routes.rb:6` (seulement dashboard) |
| 3. Layout Navbar | ⚠️ Risque doublon | `app/views/layouts/admin.html.erb:15` |
| 4. Pagination | ❌ Non implémenté | `Gemfile` (aucune gem) |
| 5. Helpers Namespace | ❌ Non implémenté | `app/helpers/` (pas de dossier admin) |
| 6. Routes ActiveAdmin | ✅ Conflit évité | `config/routes.rb:2,5` (chemins différents) |
| 7. Dark Mode Sidebar | ✅ Fonctionnel | Toggle existe dans navbar sticky (`_navbar.html.erb:11,61-72`), toujours accessible |
| 8. Breadcrumb Helper | ❌ Non implémenté | Aucun helper trouvé |
| 9. Stimulus Sidebar | ✅ Implémenté | `app/javascript/controllers/admin/admin_sidebar_controller.js:9` |
| 10. Validation SKU | ❌ Non implémenté | Pas d'endpoint trouvé |
| A. ProductVariantGenerator | ❌ Non implémenté | Aucun service trouvé |
| B. Rôles PRODUCT_MANAGER/SUPPORT | ✅ Non nécessaire | Rôles existants suffisants (ADMIN/SUPERADMIN gèrent tout) |
| C. OrderExporter | ❌ Non implémenté | `app/services/` (pas de service) |
| D. AdminDashboardService | ❌ Non implémenté | `app/admin/dashboard.rb` (KPIs basiques seulement) |
| E. ProductImporter | ❌ Non implémenté | Aucun service trouvé |
| F. Upload GPX | ⚠️ Partiel | `app/models/route.rb:7,15` (gpx_url mais pas gpx_file) |

---

## ✅ POINTS CONFIRMÉS CORRECTS

1. **Stimulus Sidebar Controller** : Existe et fonctionne (`app/javascript/controllers/admin/admin_sidebar_controller.js`)
2. **Dashboard ActiveAdmin** : KPIs basiques implémentés (`app/admin/dashboard.rb`)
3. **Routes séparées** : ActiveAdmin et admin_panel sur chemins différents (pas de conflit)
4. **Dark Mode** : Fonctionne et toujours accessible via navbar sticky-top (visible en permanence lors du scroll)

---

## RÉSUMÉ DES RÉPONSES

### ✅ INFORMATIONS DISPONIBLES

| Question | Réponse | Source |
|----------|---------|--------|
| Utilisateurs admin | 2 comptes (ADMIN + SUPERADMIN) | `db/seeds.rb` |
| Rôles distincts | 7 niveaux (USER à SUPERADMIN) | `app/models/role.rb` |
| Timeline | Shape Up 6 semaines (scope flexible) | `docs/02-shape-up/` |
| Technos | 100% Rails (Bootstrap, Stimulus, Turbo) | `README.md` |
| Variantes par produit | 3-9 en moyenne | `db/seeds.rb` |
| Images par variante | Supporté (Active Storage) | `app/models/product_variant.rb` |
| SKU/Prix/Stock | OUI, géré au niveau variante | `app/models/product_variant.rb` |
| Options | OptionType/OptionValue prédéfinies | `app/models/option_type.rb` |
| Rappels automatiques | OUI (EventReminderJob à 19h) | `app/jobs/event_reminder_job.rb` |
| No-show | OUI (statut `no_show`) | `app/models/attendance.rb` |
| Notes équipement | OUI (`equipment_note`) | `app/models/attendance.rb` |
| Routes réutilisables | OUI (Route model) | `app/models/route.rb` |
| Dashboard KPIs | OUI (basiques) | `app/admin/dashboard.rb` |
| Permissions | OUI (Pundit + 7 rôles) | `app/policies/` |
| Volume données | Faible (23 users, 7 products) | Statistiques DB |
| WebSocket | NON | Recherche codebase |
| HelloAsso | OUI, connecté et fonctionnel | `app/services/helloasso_service.rb` |
| Stripe | NON implémenté | `README.md` |
| ProductVariantGenerator | ❌ NON implémenté | `app/services/` (vérifié) |
| OrderExporter | ❌ NON implémenté | `app/services/` (vérifié) |
| ProductImporter | ❌ NON implémenté | `app/services/` (vérifié) |
| AdminDashboardService | ❌ NON implémenté | `app/services/` (vérifié) |
| Pagination | ❌ NON implémenté | `Gemfile` (vérifié) |
| Upload GPX direct | ⚠️ Partiel (gpx_url seulement) | `app/models/route.rb` (vérifié) |
| Rôles PRODUCT_MANAGER/SUPPORT | ✅ Non nécessaire | Rôles existants suffisants (ADMIN/SUPERADMIN) |

### ❌ INFORMATIONS MANQUANTES

| Question | État | Action requise |
|----------|------|----------------|
| Combien d'utilisateurs admin en production ? | ❌ Non spécifié | Demander à l'utilisateur |
| Timeline exacte avant production | ❌ Non spécifié | Demander à l'utilisateur |
| Besoin d'import Excel 100+ produits | ❌ Non spécifié | Demander à l'utilisateur |
| Besoin d'export Excel pour trésorier | ❌ Non spécifié | Demander à l'utilisateur |
| Rôle "SUPPORT" nécessaire ? | ✅ Non nécessaire | ADMIN/SUPERADMIN gèrent tout |
| Rôle "PRODUCT_MANAGER" nécessaire ? | ✅ Non nécessaire | ADMIN/SUPERADMIN gèrent tout |
| Upload GPX direct nécessaire ? | ❌ Non spécifié | Demander à l'utilisateur |
| Récurrence automatique nécessaire ? | ❌ Non spécifié | Demander à l'utilisateur |
| Unifier namespace AdminPanel/Admin | ⚠️ Incohérence confirmée | `config/routes.rb` (vérifié) |
| Ajouter pagination | ❌ Non implémenté | `Gemfile` (vérifié) |
| Créer helpers admin namespace | ❌ Non implémenté | `app/helpers/` (vérifié) |
| Ajouter endpoint check_sku | ❌ Non implémenté | Routes (vérifié) |
| Toggle dark mode sidebar | ✅ Fonctionnel | Toggle existe dans navbar sticky (toujours visible), ajout sidebar footer optionnel |

---

## RECOMMANDATIONS PRIORITAIRES

### 🔴 Critique (À faire rapidement)

1. **Corriger l'incohérence namespace** :
   - Unifier sur `AdminPanel` ou `Admin` (choisir UN)
   - Référence : `config/routes.rb:2,5` + `app/controllers/admin_panel/` + `app/controllers/admin/`

2. **Améliorer la création de produits/variantes** :
   - Formulaire unifié (produit + variantes en une étape)
   - Génération automatique de variantes (combinaisons taille × couleur)
   - **VÉRIFIÉ** : Pas de `ProductVariantGenerator` dans `app/services/`

3. **Permissions granulaires** :
   - ✅ **DÉJÀ IMPLÉMENTÉ** : Système Pundit avec 7 rôles (USER à SUPERADMIN)
   - ✅ **VÉRIFIÉ** : Seuls ADMIN/SUPERADMIN accèdent à AdminPanel (niveau 60+)
   - ✅ **VÉRIFIÉ** : Rôles existants suffisants (pas besoin de PRODUCT_MANAGER/SUPPORT)

### 🟡 Important (À faire prochainement)

3. **Exports CSV/Excel** :
   - Export commandes, adhésions, événements
   - Export mensuel pour trésorier
   - **VÉRIFIÉ** : Pas de `OrderExporter` dans `app/services/`
   - **VÉRIFIÉ** : Aucune mention d'export dans `app/admin/orders.rb`

4. **Dashboard amélioré** :
   - KPIs temporels (daily/weekly/monthly)
   - Taux de remplissage événements
   - Produits best-sellers
   - **VÉRIFIÉ** : Pas de `AdminDashboardService` dans `app/services/`
   - ✅ Dashboard ActiveAdmin existe avec KPIs basiques (`app/admin/dashboard.rb`)

5. **Import Excel** :
   - Si besoin de 100+ produits
   - **VÉRIFIÉ** : Pas de `ProductImporter` dans `app/services/`

6. **Pagination** :
   - Ajouter gem de pagination (pagy ou kaminari)
   - **VÉRIFIÉ** : Aucune gem de pagination dans `Gemfile`

7. **Helpers & Validation** :
   - Créer helpers dans namespace admin (`app/helpers/admin/`)
   - Ajouter endpoint `check_sku` pour validation formulaire
   - Créer helper `show_breadcrumb?` pour breadcrumbs centralisés

### 🟢 Optionnel (À faire plus tard)

6. **Upload GPX direct** :
   - Parser GPX pour distance/élévation
   - **VÉRIFIÉ** : Support GPX via URL (`gpx_url`) et image (`map_image`) mais pas d'upload direct (`gpx_file`)
   - **VÉRIFIÉ** : Pas de parsing GPX automatique dans `app/models/route.rb`

7. **Récurrence automatique** :
   - Job pour créer instances récurrentes

8. **Dark Mode Sidebar** (OPTIONNEL) :
   - Ajouter toggle dark mode dans sidebar admin footer (amélioration UX mineure)
   - **VÉRIFIÉ** : Toggle dark mode existe déjà dans navbar principale (`app/views/layouts/_navbar.html.erb:61-72`)
   - **VÉRIFIÉ** : Navbar est `sticky-top` (ligne 11) → **TOUJOURS VISIBLE** lors du scroll
   - **VÉRIFIÉ** : Layout admin inclut navbar sticky, donc toggle **toujours accessible**
   - **Conclusion** : **OPTIONNEL** - Peut être sautée car navbar sticky rend le toggle toujours disponible

---

## PLAN D'IMPLÉMENTATION DÉTAILLÉ

### 📊 RÉSUMÉ EXÉCUTIF
- **Durée réaliste** : 4-5 jours (25-35h)
- **Équipe** : 1 développeur
- **Stack** : Rails 8.1.1 + Bootstrap 5.3.2 + Stimulus
- **Deadline recommandée** : Avant production (à définir)

**⚠️ IMPORTANT - DASHBOARD ADMIN UNIQUEMENT** :
- L'AdminPanel est **réservé aux ADMIN/SUPERADMIN** (niveau 60+)
- Il gère **TOUTES les données** de l'application (pas seulement celles de l'utilisateur connecté)
- **Les utilisateurs ont déjà** :
  - `/orders` → "Mes commandes" (`OrdersController#index`)
  - `/memberships` → "Mes adhésions" (`MembershipsController#index`)
  - `/attendances` → "Mes sorties" (`AttendancesController#index`)
- **Ne PAS refaire** ces fonctionnalités dans l'AdminPanel

---

## 🔐 RÔLES & PERMISSIONS - QUI PEUT FAIRE QUOI

### Hiérarchie des Rôles (par niveau)

| Niveau | Code | Nom | Description |
|--------|------|-----|-------------|
| 70 | SUPERADMIN | Super Admin | Accès total, gestion technique |
| 60 | ADMIN | Admin | Gestion complète ActiveAdmin + AdminPanel |
| 50 | MODERATOR | Modérateur | Modération des événements |
| 40 | ORGANIZER | Organisateur | Création/gestion de SES événements uniquement |
| 30 | INITIATION | Initiation | Accès initiations - présences et matériel |
| 20 | REGISTERED | Inscrit | Membre inscrit |
| 10 | USER | Utilisateur | Utilisateur de base |

### Permissions par Fonctionnalité

#### 🛒 GESTION PRODUITS (AdminPanel)
| Action | USER | REGISTERED | INITIATION | ORGANIZER | MODERATOR | ADMIN | SUPERADMIN |
|--------|------|------------|------------|-----------|-----------|-------|-------------|
| Voir produits (public) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Voir produits (admin) | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Créer produit | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Modifier produit | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Supprimer produit | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Gérer variantes | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Exporter produits | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Importer produits | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |

**Policies** : `AdminPanel::ProductPolicy` (seulement ADMIN/SUPERADMIN)

---

#### 📦 GESTION COMMANDES (AdminPanel)
**⚠️ IMPORTANT** : L'AdminPanel gère **TOUTES les commandes** (pas seulement celles de l'utilisateur).  
**Les utilisateurs ont déjà** : `OrdersController#index` → "Mes commandes" (route `/orders`)

| Action | USER | REGISTERED | INITIATION | ORGANIZER | MODERATOR | ADMIN | SUPERADMIN |
|--------|------|------------|------------|-----------|-----------|-------|-------------|
| Voir SES commandes (utilisateur) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Voir TOUTES commandes (admin) | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Modifier statut commande | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Exporter commandes | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |

**Policies** : `AdminPanel::OrderPolicy` (seulement ADMIN/SUPERADMIN)  
**Routes utilisateur existantes** : `/orders` (OrdersController) → "Mes commandes"

---

#### 📅 GESTION ÉVÉNEMENTS
| Action | USER | REGISTERED | INITIATION | ORGANIZER | MODERATOR | ADMIN | SUPERADMIN |
|--------|------|------------|------------|-----------|-----------|-------|-------------|
| Voir événements publiés | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Créer événement | ❌ | ❌ | ❌ | ✅ (SES événements) | ❌ | ✅ | ✅ |
| Modifier SES événements | ❌ | ❌ | ❌ | ✅ (owner check) | ❌ | ✅ | ✅ |
| Modifier statut événement | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| Voir TOUS événements (draft) | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |

**Policies** : `EventPolicy` (ORGANIZER niveau 40+, MODERATOR niveau 50+, ADMIN niveau 60+)

---

#### 🎓 GESTION INITIATIONS
| Action | USER | REGISTERED | INITIATION | ORGANIZER | MODERATOR | ADMIN | SUPERADMIN |
|--------|------|------------|------------|-----------|-----------|-------|-------------|
| Voir initiations publiées | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Gérer initiations | ❌ | ❌ | ✅ (niveau 30+) | ✅ | ✅ | ✅ | ✅ |
| Voir présences | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Modifier présences | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Créer initiation | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ (niveau 60+) | ✅ |

**Policies** : `Event::InitiationPolicy` (INITIATION niveau 30+ pour manage?, ADMIN niveau 60+ pour create?)

---

#### 👥 GESTION UTILISATEURS (ActiveAdmin)
| Action | USER | REGISTERED | INITIATION | ORGANIZER | MODERATOR | ADMIN | SUPERADMIN |
|--------|------|------------|------------|-----------|-----------|-------|-------------|
| Voir utilisateurs | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Modifier utilisateurs | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Gérer rôles | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |

**Policies** : `Admin::ApplicationPolicy` (seulement ADMIN/SUPERADMIN)

---

#### 🏠 ADMIN PANEL (Dashboard)
**⚠️ IMPORTANT** : Dashboard **ADMIN uniquement** - Vue globale de toutes les données de l'application.  
**Les utilisateurs ont déjà** :
- `/orders` → "Mes commandes" (OrdersController)
- `/memberships` → "Mes adhésions" (MembershipsController)
- `/attendances` → "Mes sorties" (AttendancesController)

| Action | USER | REGISTERED | INITIATION | ORGANIZER | MODERATOR | ADMIN | SUPERADMIN |
|--------|------|------------|------------|-----------|-----------|-------|-------------|
| Accéder au dashboard ADMIN | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Voir KPIs globaux | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Voir statistiques globales | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |

**Policies** : `AdminPanel::BasePolicy` (seulement ADMIN/SUPERADMIN)  
**Routes utilisateur existantes** : `/orders`, `/memberships`, `/attendances` (ne PAS refaire dans AdminPanel)

---

### Règles de Permission

1. **Principe de hiérarchie** : Un niveau supérieur hérite des permissions des niveaux inférieurs
2. **Owner check** : ORGANIZER peut modifier SES événements uniquement (vérification `creator_user_id`)
3. **Statut événements** : Seuls MODERATOR+ peuvent modifier le statut (draft → published)
4. **AdminPanel** : Seulement ADMIN/SUPERADMIN (niveau 60+)
5. **ActiveAdmin** : Seulement ADMIN/SUPERADMIN (niveau 60+)

### Fichiers de Policies

- `app/policies/admin_panel/base_policy.rb` : Base pour AdminPanel (ADMIN/SUPERADMIN)
- `app/policies/admin_panel/product_policy.rb` : Produits (ADMIN/SUPERADMIN)
- `app/policies/admin_panel/order_policy.rb` : Commandes (ADMIN/SUPERADMIN)
- `app/policies/event_policy.rb` : Événements (ORGANIZER 40+, MODERATOR 50+, ADMIN 60+)
- `app/policies/event/initiation_policy.rb` : Initiations (INITIATION 30+, ADMIN 60+)
- `app/policies/admin/application_policy.rb` : ActiveAdmin (ADMIN/SUPERADMIN)

---

## 📂 FICHIERS À CRÉER (Index Global)

### Controllers
- `app/controllers/admin_panel/base_controller.rb`
- `app/controllers/admin_panel/products_controller.rb`
- `app/controllers/admin_panel/product_variants_controller.rb`
- `app/controllers/admin_panel/orders_controller.rb`

### Services
- `app/services/product_variant_generator.rb`
- `app/services/product_exporter.rb`
- `app/services/order_exporter.rb`
- `app/services/admin_dashboard_service.rb` (PHASE 4)
- `app/services/product_importer.rb` (PHASE 4)

### Helpers
- `app/helpers/admin_panel_helper.rb`
- `app/helpers/admin_panel/products_helper.rb`
- `app/helpers/admin_panel/orders_helper.rb`

### Policies
- `app/policies/admin_panel/base_policy.rb`
- `app/policies/admin_panel/product_policy.rb`
- `app/policies/admin_panel/order_policy.rb`

### Migrations
- ~~`db/migrate/xxxxx_add_product_manager_and_support_roles.rb`~~ (ANNULÉE - rôles non nécessaires)

### Views (25+ fichiers)
- `app/views/admin_panel/products/index.html.erb`
- `app/views/admin_panel/products/show.html.erb`
- `app/views/admin_panel/products/new.html.erb`
- `app/views/admin_panel/products/edit.html.erb`
- `app/views/admin_panel/products/_form.html.erb`
- `app/views/admin_panel/products/_product_variant_form.html.erb`
- `app/views/admin_panel/orders/index.html.erb`
- `app/views/admin_panel/orders/show.html.erb`
- `app/views/admin_panel/product_categories/index.html.erb`
- `app/views/admin_panel/product_categories/show.html.erb`
- `app/views/admin_panel/product_categories/edit.html.erb`
- `app/views/admin_panel/shared/_breadcrumb.html.erb`
- `app/views/admin_panel/shared/_pagination.html.erb`
- `app/views/admin_panel/shared/_filters.html.erb`

### Tests
- `spec/controllers/admin_panel/base_controller_spec.rb`
- `spec/controllers/admin_panel/products_controller_spec.rb`
- `spec/controllers/admin_panel/orders_controller_spec.rb`
- `spec/services/product_variant_generator_spec.rb`
- `spec/services/product_exporter_spec.rb`
- `spec/services/order_exporter_spec.rb`
- `spec/policies/admin_panel/product_policy_spec.rb`
- `spec/policies/admin_panel/order_policy_spec.rb`
- `spec/helpers/admin_panel_helper_spec.rb`

---

## 🔴 PHASE 0 : FONDATIONS CRITIQUES (1 jour / ~8 heures) ✅ TERMINÉ

**Status** : ✅ **TERMINÉ** - Toutes les tâches critiques complétées

### Tâche 0.1 : Unifier Namespace Controllers ✅ TERMINÉ
**Problème** : Module `Admin` et `AdminPanel` coexistent → confusion de routes  
**Solution** : Utiliser `AdminPanel` partout  
**Durée** : 2h  
**Checklist** :
- [x] Renommer `app/controllers/admin/` → `app/controllers/admin_legacy/`
- [x] Mettre à jour routes (`namespace :admin` → `namespace :admin_legacy`)
- [x] Routes ActiveAdmin corrigées dans sidebar
- [x] Tester que maintenance toggle fonctionne
- [x] Vérifier `rails routes | grep admin_panel`

### Tâche 0.2 : Ajouter Gems Essentielles ✅ TERMINÉ
**Problème** : Pas de pagination, pas d'export Excel  
**Solution** : Ajouter Pagy + rubyXL  
**Durée** : 30m  
**Code** :
```ruby
# Gemfile
gem 'pagy', '~> 8.0'
gem 'rubyXL', '~> 3.4'
```

**Checklist** :
- [x] `bundle install`
- [x] Initializer Pagy créé (`config/initializers/pagy.rb`)

### Tâche 0.3 : Corriger Routes AdminPanel ✅ TERMINÉ
**Problème** : Routes incomplètes (seul dashboard existe)  
**Solution** : Ajouter toutes les ressources  
**Durée** : 1h  
**Code** :
```ruby
# config/routes.rb
namespace :admin_panel, path: 'admin-panel' do
  root 'dashboard#index'
  resources :products do
    resources :product_variants, only: %i[edit update destroy]
    collection do
      get :check_sku
      post :import
      get :export
    end
  end
  resources :product_categories
  resources :orders do
    member { patch :change_status }
    collection { get :export }
  end
end
```

**Checklist** :
- [x] Routes définies
- [x] `rails routes` vérifie tout
- [x] Tester chemins `admin_panel_products_path`

### Tâche 0.4 : Corriger Navbar Doublon ✅ TERMINÉ
**Problème** : Layout admin inclut navbar, risque de duplication  
**Solution** : Vérifier qu'une seule instance de navbar  
**Durée** : 30m  
**Checklist** :
- [x] Vérifier `app/views/layouts/admin.html.erb:15` inclut navbar
- [x] Vérifier aucune vue n'inclut navbar en interne
- [x] Sidebar corrigée (seulement AdminPanel, lien ActiveAdmin séparé)
- [x] Lien ActiveAdmin retiré du menu burger navbar
- [x] Tester responsive

### Tâche 0.5 : Ajouter Toggle Dark Mode Sidebar (OPTIONNEL)
**État actuel** : ✅ **Toggle dark mode existe déjà dans la navbar principale** (`app/views/layouts/_navbar.html.erb` lignes 61-72)  
**État navbar** : ✅ **Navbar est `sticky-top`** (ligne 11) → **TOUJOURS VISIBLE** lors du scroll  
**Conclusion** : Le toggle dark mode est **déjà accessible en permanence** depuis la navbar sticky  
**Priorité** : 🟢 **OPTIONNEL** - Amélioration UX mineure (dupliquer le toggle dans sidebar footer)  
**Durée** : 1h (peut être fait plus tard si temps disponible)  
**Références** :
- Toggle existant : `app/views/layouts/_navbar.html.erb:61-72` (fonction `toggleTheme()`)
- Navbar sticky : `app/views/layouts/_navbar.html.erb:11` (classe `sticky-top`)
- Script existant : `app/views/layouts/application.html.erb:45` (fonction `toggleTheme()`)
- Sidebar footer : `app/views/admin/shared/_sidebar.html.erb:332-341` (à modifier si on veut dupliquer)

**Checklist** (si on décide de l'implémenter) :
- [ ] Ajouter bouton toggle dans `app/views/admin/shared/_sidebar.html.erb:340` (dans le footer)
- [ ] Utiliser la même fonction `toggleTheme()` déjà présente
- [ ] Vérifier `toggleTheme()` fonctionne depuis sidebar
- [ ] Tester dark mode persiste après rechargement
- [ ] Vérifier que les icônes (sun/moon) s'affichent correctement

**Note** : Cette tâche peut être **sautée** car la navbar sticky rend le toggle toujours accessible.

---

## 📊 ÉTAT D'AVANCEMENT GLOBAL

| Phase | Status | Progression | Fichiers créés |
|-------|--------|-------------|----------------|
| **PHASE 0** : Fondations | ✅ **TERMINÉ** | 100% | Namespace, routes, gems, sidebar |
| **PHASE 1** : Infrastructure | ✅ **TERMINÉ** | 100% | Controllers, policies, helpers |
| **PHASE 2** : Produits | ✅ **TERMINÉ** | 100% | Service, controller, vues complètes |
| **PHASE 3** : Commandes | ⚠️ **PARTIEL** | ~60% | Controller basique, vues basiques |
| **PHASE 4** : Optionnel | ❌ **NON FAIT** | 0% | - |

**Total** : **~75% du plan d'implémentation complété**

### Fichiers créés (récapitulatif)
- **Services** : `ProductVariantGenerator`
- **Controllers** : `BaseController`, `ProductsController`, `ProductVariantsController`, `OrdersController` (basique)
- **Policies** : `BasePolicy`, `ProductPolicy`, `OrderPolicy`
- **Helpers** : `admin_panel_helper`, `products_helper`, `orders_helper`
- **Vues** : 10+ fichiers (products, orders, shared)
- **JavaScript** : `sku_validator_controller.js`
- **Config** : `pagy.rb` initializer

---

## 🟡 PHASE 1 : INFRASTRUCTURE ADMIN (1 jour / ~8 heures) ✅ TERMINÉ

**Dépend de** : PHASE 0 ✓  
**Status** : ✅ **TERMINÉ** - Toutes les tâches complétées

### Tâche 1.1 : BaseController + Policies ✅ TERMINÉ
**Durée** : 2h  
**Fichiers créés** :
- [x] `app/controllers/admin_panel/base_controller.rb`
- [x] `app/policies/admin_panel/base_policy.rb`
- [x] `app/policies/admin_panel/product_policy.rb`
- [x] `app/policies/admin_panel/order_policy.rb`

**Checklist** :
- [x] BaseController inclut Pundit + authenticate
- [x] Policies implémentées (index?, show?, create?, update?, destroy?)
- [x] Namespace corrigé (authorize [:admin_panel, Model])
- [x] Policies fonctionnelles

### Tâche 1.2 : Helpers Namespace Admin ✅ TERMINÉ
**Durée** : 1.5h  
**Fichiers créés** :
- [x] `app/helpers/admin_panel_helper.rb` (admin_user?)
- [x] `app/helpers/admin_panel/products_helper.rb` (stock_badge, price_display, active_badge)
- [x] `app/helpers/admin_panel/orders_helper.rb` (status_badge, total_display)

**Checklist** :
- [x] Helpers utilisables dans vues
- [x] Helpers acceptent variant/product ou valeurs directes
- [x] Helpers fonctionnels

### Tâche 1.3 : Vérifier Rôles Existants
**Durée** : 30m  
**État** : ✅ **DÉJÀ FAIT** - Les 7 rôles existants sont suffisants

**Rôles en base** :
- USER (10), REGISTERED (20), INITIATION (30), ORGANIZER (40), MODERATOR (50), ADMIN (60), SUPERADMIN (70)

**Policies** :
- `AdminPanel::BasePolicy` : Seulement ADMIN/SUPERADMIN (niveau 60+)
- `AdminPanel::ProductPolicy` : Seulement ADMIN/SUPERADMIN
- `AdminPanel::OrderPolicy` : Seulement ADMIN/SUPERADMIN

**Checklist** :
- [x] Rôles vérifiés en base (7 rôles présents)
- [x] Policies créées et fonctionnelles
- [x] Permissions testées (seulement ADMIN/SUPERADMIN)

### Tâche 1.4 : Layout Admin Adapté ✅ TERMINÉ
**Durée** : 1h  
**Vérifier** : `app/views/layouts/admin.html.erb`
- [x] Inclut navbar correctement
- [x] Inclut sidebar
- [x] Dark mode hérité (via navbar sticky)
- [x] Sidebar corrigée (seulement AdminPanel)
- [x] Responsive OK

---

## 🟠 PHASE 2 : GESTION PRODUITS (2 jours / ~14 heures) ✅ TERMINÉ

**Dépend de** : PHASE 1 ✓  
**Status** : ✅ **TERMINÉ** - Toutes les tâches complétées

### Tâche 2.1 : ProductVariantGenerator Service ✅ TERMINÉ
**Problème** : 9 variantes créées manuellement au lieu d'automatiquement  
**Solution** : Service qui génère combinaisons taille × couleur  
**Durée** : 3h  
**Créé** : `app/services/product_variant_generator.rb`

**Checklist** :
- [x] Service génère combinaisons correctes
- [x] SKU uniques générés (avec gestion des doublons)
- [x] Transaction pour cohérence
- [x] Intégré dans ProductsController

### Tâche 2.2 : ProductsController + Check SKU ✅ TERMINÉ
**Durée** : 4h  
**Créé** : `app/controllers/admin_panel/products_controller.rb`
- [x] CRUD complet (index, show, new, edit, create, update, destroy)
- [x] Endpoint `check_sku` pour validation real-time
- [x] Export CSV implémenté
- [x] Filtres + recherche (Ransack)
- [x] Pagination avec Pagy (25 items/page)
- [x] Initializer Pagy créé

**Checklist** :
- [x] Toutes actions implémentées
- [x] Validation SKU fonctionne (endpoint JSON)
- [x] Export CSV génère fichiers

### Tâche 2.3 : ProductVariantsController Imbriqué ✅ TERMINÉ
**Durée** : 2h  
**Créé** : `app/controllers/admin_panel/product_variants_controller.rb`
- [x] Création manuelle de variantes (`new`, `create`)
- [x] Édition/suppression inline (`edit`, `update`, `destroy`)
- [x] Validation via check_sku endpoint
- [x] Association d'options (couleur, taille) via checkboxes
- [x] Vue `new.html.erb` pour créer une variante manuellement
- [x] Bouton "Nouvelle variante" dans la page show du produit

### Tâche 2.4 : Vues Products (Index, Show, Edit) ✅ TERMINÉ
**Durée** : 5h  
**Créé** :
- [x] `app/views/admin_panel/products/index.html.erb` (tableau + filtres + pagination)
- [x] `app/views/admin_panel/products/show.html.erb` (détail + variantes)
- [x] `app/views/admin_panel/products/new.html.erb` (formulaire création)
- [x] `app/views/admin_panel/products/edit.html.erb` (formulaire édition)
- [x] `app/views/admin_panel/products/_form.html.erb` (partial réutilisable)
- [x] `app/views/admin_panel/product_variants/new.html.erb` (création variante manuelle)
- [x] `app/views/admin_panel/product_variants/edit.html.erb` (édition variante avec options)
- [x] `app/views/admin_panel/shared/_breadcrumb.html.erb` (breadcrumb)
- [x] `app/views/admin_panel/shared/_pagination.html.erb` (pagination)
- [x] Contrôleur Stimulus `sku_validator_controller.js` (validation SKU temps réel)

**Checklist** :
- [x] Tableau fonctionne avec pagination
- [x] Filtres actifs (Ransack)
- [x] Formulaire avec génération automatique variantes (lors de la création produit)
- [x] Création manuelle de variantes (bouton "Nouvelle variante" dans show)
- [x] Association d'options (couleur, taille) via checkboxes
- [x] Responsive design (Bootstrap 5)

---

## 🟠 PHASE 3 : GESTION COMMANDES + EXPORTS (1.5 jours / ~10 heures) ⚠️ PARTIELLEMENT FAIT

**Dépend de** : PHASE 1 ✓  
**Status** : ⚠️ **PARTIELLEMENT FAIT** - Controller et vues de base créés, à compléter

**⚠️ IMPORTANT** : L'AdminPanel gère **TOUTES les commandes** (pas seulement celles de l'utilisateur connecté).  
**Les utilisateurs ont déjà** : `OrdersController#index` → "Mes commandes" (route `/orders`)  
**Ne PAS refaire** : La fonctionnalité "Mes commandes" existe déjà pour les utilisateurs.

### Tâche 3.1 : OrdersController Complet (ADMIN uniquement) ⚠️ PARTIELLEMENT FAIT
**Durée** : 3h  
**Créé** : `app/controllers/admin_panel/orders_controller.rb` (version basique)
- [x] Index avec filtres (**TOUTES les commandes**, pas `current_user.orders`)
- [x] Show détail (n'importe quelle commande)
- [x] Change status (basique, sans validation transitions)
- [x] Export CSV (basique)
- [ ] Validation des transitions de statut (à faire)
- [ ] Export XLSX (à faire)

**Checklist** :
- [ ] Workflow statuts fonctionne
- [ ] Transitions invalides bloquées
- [ ] Export CSV fonctionne

### Tâche 3.2 : Services Exporters ❌ NON FAIT
**Durée** : 2h  
**À créer** :
- `app/services/product_exporter.rb` (CSV + XLSX) - CSV fait dans controller
- `app/services/order_exporter.rb` (CSV + XLSX) - CSV fait dans controller

**Checklist** :
- [x] Export CSV fonctionne (dans controller)
- [ ] Services dédiés (à créer)
- [ ] Export XLSX (à faire)
- [ ] Colonnes pertinentes (à améliorer)

### Tâche 3.3 : Vues Orders + Dashboard ⚠️ PARTIELLEMENT FAIT
**Durée** : 5h  
**Créé** :
- [x] `app/views/admin_panel/orders/index.html.erb` (**TOUTES les commandes**, avec filtres)
- [x] `app/views/admin_panel/orders/show.html.erb` (détail complet)
- [x] Dashboard existe avec KPIs basiques (`app/views/admin_panel/dashboard/index.html.erb`)

**Checklist** :
- [x] Tableau commandes visible (**TOUTES les commandes**)
- [x] Changement statuts fonctionne (basique)
- [x] Dashboard affiche KPIs **globaux**
- [x] Filtres par utilisateur fonctionnent
- [ ] Validation transitions de statut (à améliorer)
- [ ] Export XLSX (à faire)

---

## 🟢 PHASE 4 : OPTIONNEL (1 semaine / ~7 heures)

**Dépend de** : PHASE 1 ✓ (peut être fait en parallèle de PHASE 2-3)

### Tâche 4.1 : AdminDashboardService (KPIs Avancés)
**Durée** : 2h  
**Créer** : `app/services/admin_dashboard_service.rb`

**Méthodes à implémenter** :
- `revenue_breakdown` : Retourne hash avec today/week/month/all-time
- `top_products(limit = 5)` : Top N produits par ventes
- `event_occupancy_rate` : Taux de remplissage événements

**Code** :
```ruby
# app/services/admin_dashboard_service.rb
class AdminDashboardService
  def self.revenue_breakdown
    {
      today: revenue_for(Date.today),
      this_week: revenue_for(1.week.ago..Date.today),
      this_month: revenue_for(1.month.ago..Date.today),
      this_year: revenue_for(1.year.ago..Date.today)
    }
  end
  
  def self.top_products(limit = 5)
    Product
      .joins(product_variants: {order_items: :order})
      .select('products.*, COUNT(order_items.id) as orders_count')
      .where('orders.created_at > ?', 30.days.ago)
      .where(orders: { status: %w[paid shipped] })
      .group('products.id')
      .order('orders_count DESC')
      .limit(limit)
  end
  
  def self.event_occupancy
    Event.active
      .select('events.*, COUNT(attendances.id) as registered_count')
      .where('events.date >= ?', Date.today)
      .group('events.id')
      .map { |e| { event: e, occupancy: (e.registered_count.to_f / e.max_participants * 100).round } }
  end
  
  private
  
  def self.revenue_for(range)
    Order
      .where(created_at: range)
      .where(status: %w[paid shipped])
      .sum(:total_cents) / 100.0
  end
end
```

**Checklist** :
- [ ] Service crée les KPIs corrects
- [ ] Dashboard affiche graphiques (Chartkick si disponible)
- [ ] Tests passent (`spec/services/admin_dashboard_service_spec.rb`)
- [ ] Performance OK (pas de N+1 queries)

---

### Tâche 4.2 : ProductImporter (100+ produits)
**Durée** : 3h  
**Créer** : `app/services/product_importer.rb`

**Fonctionnalités** :
- Import CSV/XLSX
- Validation + gestion erreurs
- Rollback si erreurs critiques
- Rapport d'import détaillé

**Code** :
```ruby
# app/services/product_importer.rb
class ProductImporter
  def initialize(file)
    @file = file
    @results = { success: 0, errors: [] }
  end
  
  def import
    workbook = load_workbook
    sheet = workbook.worksheets.first
    
    sheet.each_with_index do |row, idx|
      next if idx == 0  # Skip header
      
      begin
        create_product_from_row(row)
        @results[:success] += 1
      rescue => e
        @results[:errors] << { row: idx + 1, error: e.message }
      end
    end
    
    @results
  end
  
  private
  
  def load_workbook
    case @file.content_type
    when 'text/csv'
      # Parser CSV
      CSV.parse(@file.read)
    else
      RubyXL::Parser.parse(@file.path)
    end
  end
  
  def create_product_from_row(row)
    product = Product.create!(
      name: row[0].value,
      slug: row[1].value.parameterize,
      description: row[2].value,
      price_cents: (row[3].value.to_f * 100).to_i,
      product_category_id: find_category(row[4].value),
      is_active: row[5].value.downcase == 'oui'
    )
    
    # Optionnel: créer variantes depuis colonne 6
    if row[6].value.present?
      ProductVariantGenerator.generate_from_csv(product, row[6].value)
    end
  end
  
  def find_category(name)
    ProductCategory.find_by(name: name)&.id || 
      ProductCategory.create!(name: name).id
  end
end
```

**Controller Action** :
```ruby
# app/controllers/admin_panel/products_controller.rb
def import
  @import_form = ProductImportForm.new
end

def perform_import
  file = params[:import_form][:file]
  importer = ProductImporter.new(file)
  @results = importer.import
  
  if @results[:errors].empty?
    redirect_to admin_panel_products_path, 
                notice: "#{@results[:success]} produits importés avec succès"
  else
    render :import, alert: "#{@results[:errors].count} erreurs lors de l'import"
  end
end
```

**Checklist** :
- [ ] Import CSV fonctionne
- [ ] Import XLSX fonctionne
- [ ] Validation erreurs affichée
- [ ] Rapport d'import détaillé
- [ ] Tests passent (`spec/services/product_importer_spec.rb`)

---

### Tâche 4.3 : GPX Upload + Parsing
**Durée** : 2h  
**Modifier** : `app/models/route.rb`

**Fonctionnalités** :
- Upload GPX direct (au lieu que URL)
- Parser automatique distance/élévation
- Validation format GPX

**Code** :
```ruby
# app/models/route.rb
class Route < ApplicationRecord
  has_one_attached :gpx_file
  has_one_attached :map_image
  
  validates :name, presence: true, length: { maximum: 140 }
  validate :gpx_valid_if_attached
  
  after_commit :parse_gpx_data, if: :gpx_file_changed?
  
  def gpx_valid_if_attached
    return unless gpx_file.attached?
    
    begin
      gpx_content = gpx_file.download
      GPX::GPXFile.new(gpx: gpx_content)
    rescue => e
      errors.add(:gpx_file, "invalide: #{e.message}")
    end
  end
  
  def parse_gpx_data
    return unless gpx_file.attached?
    
    gpx = GPX::GPXFile.new(gpx: gpx_file.download)
    
    # Calculer distance
    self.distance_km = gpx.tracks.first.distance / 1000.0
    
    # Calculer élévation
    self.elevation_m = gpx.tracks.first.points.map(&:elevation).compact.max.to_i
    
    save!
  end
end
```

**View** :
```erb
<!-- app/views/admin_panel/routes/_form.html.erb -->
<div class="mb-3">
  <%= f.label :gpx_file, 'Fichier GPX (optionnel)' %>
  <%= f.file_field :gpx_file, accept: '.gpx', class: 'form-control' %>
  <small class="text-muted">
    Distance et élévation seront calculées automatiquement
  </small>
</div>

<% if @route.gpx_file.attached? %>
  <div class="alert alert-info">
    ✅ Fichier chargé: <%= @route.gpx_file.filename %>
    <%= link_to '✕', route_gpx_file_path(@route), 
        method: :delete, class: 'float-end text-danger' %>
  </div>
<% end %>
```

**Gem à ajouter** :
```ruby
# Gemfile
gem 'gpx', '~> 0.1'
```

**Checklist** :
- [ ] Upload GPX fonctionne
- [ ] Parsing distance/élévation automatique
- [ ] Validation format GPX
- [ ] Tests passent (`spec/models/route_spec.rb`)

---

## ✅ TESTS (Par Phase)

### PHASE 0 Tests
**Commandes** :
```bash
# Routes correctes
rails routes | grep admin_panel

# Gems installés
bundle show pagy
bundle show ruby-xlsx

# Namespace unifié (no Admin module)
grep -r "module Admin" app/controllers/ | grep -v admin_legacy
```

**Checklist** :
- [ ] Routes correctes : `rails routes | grep admin_panel`
- [ ] Gems installés : `bundle show pagy`
- [ ] Namespace unifié (no Admin module)
- [ ] Navbar non-dupliquée (inspecter HTML)
- [ ] Dark mode toggle fonctionne dans sidebar

---

### PHASE 1 Tests
**Commandes** :
```bash
# BaseController authentifie
rails test controllers/admin_panel/base_controller_test.rb

# Policies appliquées
rails test policies/

# Helpers fonctionnent
rails test helpers/
```

**Checklist** :
- [ ] BaseController authentifie : `rails test controllers/admin_panel/base_controller_test.rb`
- [ ] Policies appliquées : `rails test policies/`
- [ ] Helpers fonctionnent : `rails test helpers/`
- [ ] Rôles créés en BD : `rails console` → `Role.where(code: ['PRODUCT_MANAGER', 'SUPPORT'])`

---

### PHASE 2 Tests
**Commandes** :
```bash
# ProductsController CRUD
rails test controllers/admin_panel/products_controller_test.rb

# ProductVariantGenerator génère 9 variantes
rails test services/product_variant_generator_test.rb

# Validation SKU fonctionne
curl "http://localhost:3000/admin-panel/products/check_sku?sku=TEST"
```

**Checklist** :
- [ ] ProductsController CRUD : `rails test controllers/admin_panel/products_controller_test.rb`
- [ ] ProductVariantGenerator génère 9 variantes : `rails test services/product_variant_generator_test.rb`
- [ ] Validation SKU fonctionne : `GET /admin-panel/products/check_sku?sku=TEST`
- [ ] Export CSV/XLSX génère fichiers
- [ ] Pagination fonctionne avec 100+ produits

---

### PHASE 3 Tests
**Commandes** :
```bash
# OrdersController workflow
rails test controllers/admin_panel/orders_controller_test.rb

# Exporters CSV/XLSX
rails test services/product_exporter_test.rb
rails test services/order_exporter_test.rb
```

**Checklist** :
- [ ] OrdersController workflow : `rails test controllers/admin_panel/orders_controller_test.rb`
- [ ] Exporters CSV/XLSX : `rails test services/product_exporter_test.rb`
- [ ] Changement statut avec transitions validées
- [ ] Export commandes fonctionne

---

### PHASE 4 Tests (Optionnel)
**Commandes** :
```bash
# AdminDashboardService KPIs
rails test services/admin_dashboard_service_test.rb

# ProductImporter
rails test services/product_importer_test.rb

# GPX parsing
rails test models/route_test.rb
```

**Checklist** :
- [ ] AdminDashboardService KPIs : `rails test services/admin_dashboard_service_test.rb`
- [ ] ProductImporter : `rails test services/product_importer_test.rb`
- [ ] GPX parsing : `rails test models/route_test.rb`

---

## 🧪 TESTS & QA (Tout au long du projet)

### Par phase :
- [ ] Unit tests (Models + Services)
- [ ] Controller tests (RSpec)
- [ ] Integration tests (Capybara)
- [ ] Permissions (Pundit)

### Avant production :
- [ ] Tous les tests passent
- [ ] Performance audit (N+1 queries)
- [ ] Dark mode testé
- [ ] Pagination testée avec 100+ items
- [ ] Export/import fonctionnent
- [ ] Permissions testées par rôle

---

## 📊 TIMELINE ESTIMÉE

| Phase | Durée | Dates | Priorité | Status |
|-------|-------|-------|----------|--------|
| 0: Fondations | 1 jour (8h) | Jour 1 | 🔴 CRITIQUE | ✅ TERMINÉ |
| 1: Infrastructure | 1 jour (8h) | Jour 2 | 🔴 CRITIQUE | ✅ TERMINÉ |
| 2: Produits | 2 jours (14h) | Jours 3-4 | 🟠 HAUTE | ✅ TERMINÉ |
| 3: Commandes | 1.5 jours (10h) | Jour 5 | 🟠 HAUTE | ⚠️ PARTIEL |
| **TOTAL** | **4-5 jours (35h)** | **5 jours** | ✅ RÉALISTE | **~75% FAIT** |
| 4: Optionnel | 1 semaine | Semaine 2 | 🟢 OPTIONNEL | ❌ NON FAIT |

---

## 🎯 POINTS D'AMÉLIORATION (Priorisés)

| # | Point | Impact | Durée | Priorité | Phase |
|---|-------|--------|-------|----------|-------|
| 1 | Namespace incohérence | Architecture | 2h | 🔴 BLOQUANT | 0 |
| 2 | Vérifier rôles existants | Sécurité | 30m | ✅ FAIT | 1 |
| 3 | Pagination manquante | Scalabilité | 30m | 🔴 CRITIQUE | 0 |
| 4 | Variantes manuelles vs auto | UX/Vitesse | 3h | 🟠 HAUTE | 2 |
| 5 | Exports CSV/Excel | Opérations | 2h | 🟠 HAUTE | 3 |
| 6 | Validation SKU real-time | UX | 1h | 🟠 HAUTE | 2 |
| 7 | Dashboard KPIs avancés | Business | 2h | 🟢 OPTIONNEL | 4 |
| 8 | Navbar doublon | UX | 30m | 🟡 FAIBLE | 0 |
| 9 | Dark mode sidebar | UX | 1h | 🟢 OPTIONNEL | 0 (peut être sautée) |

---

## 🚀 COMMANDES À EXÉCUTER

### Phase 0
```bash
git checkout -b admin-panel/phase-0-foundations
# Faire tâches 0.1-0.5
git commit -m "feat: admin panel phase 0 foundations"
git push
```

### Phase 1
```bash
git checkout -b admin-panel/phase-1-infrastructure
# Faire tâches 1.1-1.4
git commit -m "feat: admin panel phase 1 infrastructure"
git push
```

### Phase 2
```bash
git checkout -b admin-panel/phase-2-products
# Faire tâches 2.1-2.4
git commit -m "feat: admin panel phase 2 products"
git push
```

### Phase 3
```bash
git checkout -b admin-panel/phase-3-orders
# Faire tâches 3.1-3.3
git commit -m "feat: admin panel phase 3 orders"
git push
```

### Phase 4 (Optionnel)
```bash
git checkout -b admin-panel/phase-4-advanced
# Faire tâches 4.1-4.3
git commit -m "feat: admin panel phase 4 advanced (optional)"
git push
```

---

## 📋 CHECKLIST FINAL

Avant de démarrer avec Cursor :
- [ ] Valider timeline avec équipe
- [ ] Décider si PHASE 4 (optionnelle) nécessaire
- [ ] Définir deadline production
- [ ] Choisir branche de départ (`develop` ou `main`)
- [ ] Vérifier accès BD staging
- [ ] Confirmer Gemfile accessible

✅ Prêt pour implémentation !

---

## 💻 UTILISER AVEC CURSOR

### Configuration Cursor

1. **Copier ce document entier dans Cursor**
   - Ouvrir Cursor
   - Créer un nouveau fichier ou coller dans le chat
   - Copier tout le contenu de ce document

2. **Instructions de démarrage pour Cursor** :
```
Tu vas implémenter un admin panel Rails selon ce plan.
Ordre strict : PHASE 0 → 1 → 2 → 3 (optionnel 4).
Pour chaque tâche : code complet + tests.
Style : Rails 8 conventions, Bootstrap 5 classes, Stimulus patterns.
Respecter les durées estimées et les dépendances entre phases.
```

3. **Demander à Cursor par phase** :
   - **Phase 0** : "Implémente PHASE 0 (tâches 0.1-0.5). Suis exactement les checklists."
   - **Phase 1** : "Implémente PHASE 1 (tâches 1.1-1.4). Vérifie que PHASE 0 est complète."
   - **Phase 2** : "Implémente PHASE 2 (tâches 2.1-2.4). Utilise les services créés en PHASE 1."
   - **Phase 3** : "Implémente PHASE 3 (tâches 3.1-3.3). Intègre les exports."
   - **Phase 4** : "Implémente PHASE 4 (tâches 4.1-4.3) si temps disponible."

4. **Bonnes pratiques avec Cursor** :
   - ✅ Demander une phase à la fois
   - ✅ Vérifier les tests après chaque phase
   - ✅ Commit Git après chaque phase complète
   - ✅ Utiliser les checklists pour validation
   - ❌ Ne pas sauter de phases
   - ❌ Ne pas mélanger les phases

5. **Vérification après chaque phase** :
   ```bash
   # Lancer les tests
   rails test
   # ou
   bundle exec rspec
   
   # Vérifier les routes
   rails routes | grep admin_panel
   
   # Vérifier les fichiers créés
   ls -la app/controllers/admin_panel/
   ls -la app/services/
   ```

---

**Document créé le** : 2025-12-21  
**Dernière mise à jour** : 2025-12-21 (Simplifié selon recommandations d'analyse)  
**Version** : 2.6

**📄 Document complémentaire** : `docs/development/admin-panel/flux-utilisateur-boutique.md`  
→ Documentation détaillée du flux utilisateur pour la gestion de la boutique

> ⚠️ **IMPORTANT - SIMPLIFICATIONS** :  
> - **ProductTemplate** et **OptionSets** sont **SKIP** pour l'instant (overkill pour le cas d'usage actuel)  
> - **Upload de fichiers uniquement** : Pas de liens `image_url`, seulement upload via Active Storage  
> - Voir section "Extensions futures" dans `flux-utilisateur-boutique.md` pour détails

---

## 📝 CHANGELOG

### Version 2.6 (2025-12-21)
- ⚠️ **SIMPLIFICATIONS** : ProductTemplate et OptionSets SKIP (overkill)
- ✅ **Upload fichiers uniquement** : Suppression des liens image_url, seulement Active Storage
- ✅ **Workflow Order amélioré** : Reserve/release stock avec inventories
- ✅ **GRID éditeur amélioré** : Validation, debounce, optimistic locking
- ✅ **Estimation révisée** : 6-8 semaines au lieu de 5 semaines
- ✅ **Plan Minimal Viable** : 4 semaines pour 80% de la valeur

### Version 2.5 (2025-12-21)
- ✅ **Documentation harmonisée** : Référence à flux-utilisateur-boutique.md

### Version 2.4 (2025-12-21)
- ✅ **PHASE 0 terminée** : Fondations critiques complètes
- ✅ **PHASE 1 terminée** : Infrastructure Admin complète
- ✅ **PHASE 2 terminée** : Gestion Produits complète
- ⚠️ **PHASE 3 partiellement faite** : Controller et vues Orders de base créés
- ✅ **Sidebar corrigée** : Ne contient que les nouvelles structures AdminPanel (Dashboard, Produits, Commandes)
- ✅ **Lien ActiveAdmin** : Retiré du menu burger, disponible dans sidebar AdminPanel
- ✅ **Corrections** : Policies namespace, helpers, routes
- ✅ **Documentation mise à jour** : État actuel complet

### Version 2.3 (2025-12-21)
- ✅ **PHASE 2 terminée** : Gestion Produits complète
- ✅ **Sidebar corrigée** : Ne contient que les nouvelles structures AdminPanel (Dashboard, Produits, Commandes)
- ✅ **Lien ActiveAdmin** : Ajout d'un lien vers ActiveAdmin pour les autres fonctionnalités
- ✅ **Documentation mise à jour** : Toutes les tâches PHASE 2 marquées comme terminées

### Version 2.2 (2025-12-21)
- Vérifications intégrées + plan d'implémentation complet
- Section rôles et permissions détaillée
- Clarification dashboard ADMIN vs utilisateur

