# ✅ CHECKLIST PHASE 2 - ÉVÉNEMENTS
## Checklist complète pour le développement Phase 2 (15 jours)

> **📋 Planning détaillé** : Voir [`FIL_CONDUCTEUR_PROJET.md`](FIL_CONDUCTEUR_PROJET.md)  
> **📋 Guide technique** : Voir [`GUIDE_IMPLEMENTATION.md`](GUIDE_IMPLEMENTATION.md)

---

## 📋 CHECKLIST GLOBALE

### ✅ PRÉ-REQUIS (Avant Jour 1)
- [x] ER Diagram créé (Event → Route, User, Attendance) ✅
- [x] Branching strategy définie (main/develop/feature branches) ✅
- [x] Database.yml configuré pour 3 envs (dev/staging/prod) ✅
- [x] `dbdiagram.md` à jour avec tous les modèles ✅

---

## 📅 SEMAINE 1 (Jour 1-5) - Setup & Infrastructure

### ✅ Jour 1 : Infrastructure
- [ ] Rails 8 + Docker configuré ✓ (déjà fait)
- [ ] Repository Git avec conventions ✓ (déjà fait)
- [ ] Credentials Rails configurés ✓ (déjà fait)

### ✅ Jour 2-3 : Authentification & Rôles
- [ ] Devise + configuration initiale ✓ (déjà fait)
- [ ] Modèle User avec enum rôles + validations Rails 8
- [ ] Tests fixtures/seeds en parallèle

### ✅ Jour 4 : Autorisation & Tests Setup
- [ ] Pundit (policies) **AVANT** les contrôleurs métier
- [ ] ApplicationController avec includes Pundit complet
- [x] RSpec setup ✅ (configuré)
- [ ] FactoryBot (factories/) NOT fixtures
- [ ] Database cleaner + Transaction rollback

### ✅ Jour 5 : CI/CD GitHub Actions
- [ ] GitHub Actions workflow (tests, linting, security)
- [ ] Tests automatisés dans CI (coverage >70% dès Week 2)
- [ ] Prometheus + Grafana basique (optionnel MVP)
- [ ] Let's Encrypt préconfiguré (optionnel MVP)

---

## 📅 SEMAINE 2 (Jour 6-10) - CRUD Événements

### ✅ Jour 6-7 : Models CRUD + Tests (TDD) ⚠️ **ORDRE MIGRATIONS CRITIQUE**
- [x] **⚠️ ORDRE CORRECT DES MIGRATIONS** :
  1. `routes` ← **CRÉER EN PREMIER** (Event dépend de Route via FK) ✅
  2. `events` (APRÈS routes) ✅
  3. `attendances` (APRÈS events) ✅
  4. `organizer_applications`, `partners`, `contact_messages`, `audit_logs` ✅
- [x] **Énums avec validations Rails 8** : `enum :status, {...}, validate: true` ✅
- [x] Migrations appliquées et testées ✅
- [x] Seeds créés et testés (Phase 2) ✅
- [ ] Controllers manuels (app/controllers/events_controller.rb)
- [ ] Tests RSpec models (validations, associations, scopes) - **TDD dès le début**

### ✅ Jour 8 : Controllers & Routes
- [ ] CRUD Events controller complet (new, create, edit, update, destroy)
- [ ] Routes RESTful + custom (register, unregister)
- [ ] Vues ERB de base (index, show, new, edit)
- [ ] Tests controllers (RSpec avec let + factories)
- [ ] Guardrails (validations dates, places, etc.)

### ✅ Jour 9 : Inscriptions & Calendrier
- [ ] Système inscription/désinscription aux événements
- [ ] Calendrier interactif (FullCalendar)
- [ ] Tests d'intégration (Capybara)

### ✅ Jour 10 : Tests Unitaires & Intégration (TDD)
- [ ] Tests unitaires Event (RSpec) - validations, associations, scopes
- [ ] Tests intégration Events + Attendances (Capybara)
- [ ] Tests calendar + inscription workflow
- [ ] **Coverage >70%** (unitaire + intégration) ← **OBLIGATOIRE**
- [ ] Revue qualité, fixes bugs, optimisation requêtes (N+1 queries)

---

## 📅 SEMAINE 3 (Jour 11-15) - Admin Panel & Finalisation

### ✅ Jour 11 : Pundit Policies + Finalisation Modèles
- [ ] Créer policies : `app/policies/event_policy.rb`
- [ ] Update ApplicationController avec Pundit complet
- [ ] Tests authorization (Pundit rules)
- [ ] Sécurisation accès (rôles ADMIN/SUPERADMIN uniquement)
- [ ] ⚠️ **Vérifier que tous les modèles Event/Route sont 100% FINALISÉS** :
  - Migrations définitives ✓
  - Associations complètes ✓
  - Validations finales ✓
  - Enums corrects ✓
  - Tests passing >70% ✓

### ✅ Jour 12 : Installation ActiveAdmin ⚠️ **CRITIQUE - APRÈS modèles stables**
- [ ] ⚠️ **PRÉ-REQUIS vérifiés** :
  - Event modèle 100% finalisé ✓
  - Routes CRÉÉES AVANT Events ✓
  - Tests RSpec Event >70% coverage ✓
  - Attendances + inscriptions testées ✓
  - Calendrier fonctionnel testé ✓
- [ ] `bundle add activeadmin devise`
- [ ] `rails generate activeadmin:install --skip-users`
- [ ] Config `app/admin/application.rb` (authentication_method, PunditAdapter)
- [ ] Generate resources : `rails g activeadmin:resource Event User Route Product Order Attendance`
- [ ] Configuration routes admin (`/admin`)

### ✅ Jour 13 : Customisation ActiveAdmin
- [ ] Configurer colonnes visibles (index, show, form)
- [ ] Filtres simples (email, role, created_at) - utilisables via UI par bénévoles
- [ ] Bulk actions (sélectionner 10 événements = modifier status en 1 clic)
- [ ] Export CSV/PDF intégré (out-of-the-box)
- [ ] Dashboard validation organisateurs
- [ ] Actions personnalisées (validate_organizer!)

### ✅ Jour 14 : Tests Admin Panel & Notifications
- [ ] Tests admin controllers (RSpec)
- [ ] Integration tests (admin actions via Capybara)
- [ ] Permissions Pundit testées
- [ ] Coverage >70% maintenu
- [ ] Notifications email (inscription événement, rappel)
- [ ] Active Storage configuration complète
- [ ] Upload photos événements

### ✅ Jour 15 : Performance & Sécurité
- [ ] Audit sécurité complet (Brakeman) ← **OBLIGATOIRE**
- [ ] Optimisation requêtes (N+1 queries) ← **OBLIGATOIRE**
- [ ] Tests de performance basiques (optionnel pour MVP associatif)
  - ⚠️ **Si temps** : Tests simple via k6 (10→100 users)
  - ⚠️ **Si pas temps** : Sauter, faire en Cooldown
- [ ] Cache strategy (Redis) - optionnel MVP
- [ ] CDN assets - optionnel MVP

---

## 🚨 POINTS CRITIQUES À VÉRIFIER

### ⚠️ Ordre Migrations
- [x] Routes créées AVANT Events (Event dépend de Route via FK `route_id`) ✅
- [x] Events créés AVANT Attendances (Attendance dépend de Event via FK) ✅

### ⚠️ ActiveAdmin Timing
- [ ] ActiveAdmin installé APRÈS tests complets (Jour 12, pas avant)
- [ ] Modèles garantis 100% stables avant installation

### ⚠️ Tests Coverage
- [ ] Coverage >70% maintenu dès Week 2
- [ ] Tests unitaires + intégration (RSpec + Capybara)

### ⚠️ CI/CD
- [ ] CI/CD configuré Jour 5 (AVANT modèles métier)
- [ ] Tests automatisés dans CI

---

## 📊 CRITÈRES DE "DONE" Phase 2

Une feature est "Done" quand :
- ✅ Tests passent (coverage >70%)
- ✅ Code review approuvé
- ✅ Documentation mise à jour
- ✅ Déployable en production
- ✅ Performance acceptable
- ✅ Sécurité validée (Brakeman)
- ✅ ActiveAdmin fonctionnel pour bénévoles

---

## 🔗 RESSOURCES

- **Planning détaillé** : [`FIL_CONDUCTEUR_PROJET.md`](FIL_CONDUCTEUR_PROJET.md)
- **Guide technique** : [`GUIDE_IMPLEMENTATION.md`](GUIDE_IMPLEMENTATION.md)
- **Méthodologie** : [`GUIDE_SHAPE_UP.md`](GUIDE_SHAPE_UP.md)
- **Admin Panel** : `docs/04-rails/admin-panel-research.md`
- **Schema DB** : `ressources/db/dbdiagram.md`

---

*Checklist créée le : Janvier 2025*  
*Version : 1.0*  
*Timeline : 15 jours exactement (Jour 1-15)*

