---
title: "Cycle 01 - Building Phase Log"
status: "active"
version: "1.0"
created: "2025-01-20"
updated: "2025-11-14"
authors: ["FlowTech"]
tags: ["shape-up", "building", "cycle-01", "roadmap"]
---

# Cycle 01 - Building Phase Log

**Project** : Grenoble Roller Community Platform  
**Technology Stack** : Rails 8.1.1 + Bootstrap 5.3.2  
**Methodology** : Shape Up (6 weeks cycle)

> **Related Documents** :
> - Phase 2 detailed plan : [`cycle-01-phase-2-plan.md`](cycle-01-phase-2-plan.md)
> - Shape Up methodology : [`../shape-up-methodology.md`](../shape-up-methodology.md)
> - Technical implementation guide : [`../technical-implementation-guide.md`](../technical-implementation-guide.md)

This document contains the overall planning, sprints, progress tracking and project status.

---

## 📋 SYNTHÈSE EXÉCUTIVE

**Objectif** : Développer un site web moderne pour l'association Grenoble Roller en utilisant Rails 8 et Bootstrap, avec une approche agile et une architecture scalable.

**Durée estimée** : 3 semaines (Building) + 1 semaine (Cooldown)  
**Équipe** : 2 développeurs  
**Méthodologie** : Agile avec Trello + TDD + CI/CD

---

## 🎯 FONCTIONNALITÉS IDENTIFIÉES

Basé sur l'analyse du contenu existant, voici les fonctionnalités prioritaires :

### 🔐 **Authentification & Rôles**
- Inscription/Connexion utilisateurs
- Gestion des rôles : Membre, Staff, Admin
- Système d'adhésion (10€, 56,55€, 58€)

### 🏢 **Présentation Association**
- Page d'accueil avec valeurs (Convivialité, Sécurité, Dynamisme, Respect)
- Présentation du bureau et CA
- Règlement intérieur et statuts
- Lutte contre les violences

### 🎪 **Gestion des Événements**
- CRUD événements (randos vendredi soir)
- Calendrier interactif
- Gestion des parcours (4-15km)
- Système d'inscription aux événements

### 🎓 **Module Initiation**
- Gestion des séances (samedi 10h15-12h00)
- Inscription aux initiations
- Gestion des créneaux (actuellement complet)
- Système de prêt de matériel

### 🛒 **Boutique HelloAsso**
- Intégration API HelloAsso
- Gestion des produits
- Système de paiement sécurisé
- Gestion des commandes

### 👥 **Panel Administration**
- Statistiques d'utilisation
- Gestion des membres
- Modération des contenus
- Gestion des événements

### 📱 **Réseaux Sociaux**
- Partage automatique des événements
- Intégration Twitter/X et Facebook
- Planification des posts

---

## 🗂️ STRUCTURE TRELLO OPTIMISÉE

### **Colonnes Principales**

#### 📥 **Backlog**
- Épopées et User Stories
- Champs personnalisés : Priorité (P0-P3), Estimation (points), Assigné
- Labels : Front, Back, Design, Ops

#### 📋 **À Faire**
- User Stories prêtes pour le sprint
- Critères d'acceptation définis
- Estimation validée

#### 🔄 **En Cours**
- Une carte = une User Story active
- Limite : 2-3 cartes par développeur
- Mise à jour quotidienne

#### 👀 **En Revue/QA**
- Tests unitaires et d'intégration
- Revue de code croisée
- Tests de régression

#### ✅ **Prêt pour Prod**
- Validation QA complète
- Tests de performance OK
- Documentation mise à jour

#### 🏁 **Terminé**
- Historique des livrables
- Métriques de vélocité

#### 🚫 **Blocages/Imprévus**
- Obstacles techniques
- Attentes client
- Dépendances externes

---

## 🎯 MÉTHODOLOGIE SHAPE UP ADAPTÉE

### Principe Fondamental
**Appetite fixe (3 semaines), scope flexible** - Si pas fini → réduire scope, pas étendre deadline.

### 4 Phases Shape Up
1. **SHAPING** (2-3 jours) : Définir les limites
2. **BETTING TABLE** (1 jour) : Priorisation brutale  
3. **BUILDING** (Semaines 1-3) : Livrer feature shippable
4. **COOLDOWN** (Semaine 4) : Repos obligatoire

### Rabbit Holes Évités
- ❌ Microservices → Monolithe Rails d'abord
- ❌ Kubernetes → Docker Compose simple
- ❌ Internationalisation → MVP français uniquement
- ❌ API publique → API interne uniquement

---

## 🚀 PHASES DE DÉVELOPPEMENT

### **PHASE 1 - SHAPING** (Semaine -2 à 0)

#### 🎯 **Objectifs**
- Définir le périmètre fonctionnel précis
- Établir les personas et parcours utilisateurs
- Choisir l'architecture Rails 8
- Planifier l'infrastructure

#### 📋 **Livrables**
- [✅] User Stories détaillées avec critères d'acceptation
- [✅] **ER Diagram (Event → Route, User, Attendance)** ← **CRITIQUE avant Jour 1**
- [✅] Diagrammes d'architecture technique
- [✅] Personas et parcours utilisateurs
- [✅] Plan d'infrastructure (serveur, DB, CI/CD)
- [✅] **Branching strategy (main/develop/feature branches)** ← **CRITIQUE**
- [✅] **Database.yml pour 3 envs (dev/staging/prod)** ← **CRITIQUE**
- [✅] Conventions de développement

#### 🛠️ **Actions**
1. **Atelier de cadrage** (2 jours)
   - Analyse des besoins métier
   - Priorisation des fonctionnalités
   - Définition des personas

2. **Architecture technique** (2 jours)
   - Choix Rails 8 (monolithique vs modularisé)
   - Stack technique complète
   - Plan de sécurité

3. **Planification** (1 jour)
   - Estimation des User Stories
   - Planification des sprints
   - Définition des critères de "Done"

---

### **PHASE 2 - DESIGN & PROTOTYPAGE** (1-2 semaines)

#### 🎯 **Objectifs**
- Créer les wireframes et prototypes
- Valider l'UX/UI
- Définir le design system

#### 📋 **Livrables**
- [✅] Wireframes desktop et mobile
- [✅] Prototype interactif (Figma)
- [✅] Design system Bootstrap
- [✅] Validation UX/UI

#### 🛠️ **Actions**
1. **Wireframes** (3 jours)
   - [✅] Pages principales
   - [✅] Responsive design
   - [✅] Navigation

2. **Prototype interactif** (4 jours)
   - [✅] Interactions utilisateur
   - [✅] Flux de navigation
   - [✅] Validation

3. **Design system** (2 jours)
   - [✅] Composants Bootstrap
   - [✅] Thème personnalisé (Liquid Design 2025)
   - [✅] Guidelines
   - [✅] UI Kit complet (Atoms, Molecules, Organisms)
   - [✅] Version staging déployée

---

### **PHASE 3 - ENVIRONNEMENT & CI/CD** (Jour 4-5 - AVANT modèles métier)

> ⚠️ **IMPORTANT** : CI/CD doit être configuré **AVANT** le développement des modèles métier pour garantir la qualité dès le début.

#### 🎯 **Objectifs**
- Mettre en place l'environnement de développement
- Configurer CI/CD **tôt** (Jour 4-5)
- Implémenter le monitoring de base

#### 📋 **Livrables**
- [✅] Repository GitHub structuré
- [✅] Pipeline CI (tests, linting, audit)
- [✅] Pipeline CD (staging/prod)
- [ ] Monitoring initial (Prometheus + Grafana basique)

#### 🛠️ **Actions (Ordre Recommandé Rails 8)**

**Jour 1-2 : Infrastructure de Base**
- [✅] Rails 8 + Ruby 3.3+ + PostgreSQL ✓ (déjà fait)
- [✅] Docker Compose (dev/staging/prod) ✓ (déjà fait)
- [✅] Repository Git avec conventions (main/develop/feature branches) ✓
- [✅] Credentials Rails configurés ✓

**Jour 2-3 : Authentification & Rôles**
- [✅] Devise + configuration initiale ✓ (déjà fait)
- [✅] Modèle User avec enum rôles + validations Rails 8 : `enum role: [...], validate: true` + `validates :role, presence: true`
- [✅] Tests fixtures/seeds en parallèle

**Jour 3-4 : Autorisation & Tests Setup**
- [✅] Pundit (policies) **AVANT** les contrôleurs métier
- [✅] ApplicationController avec includes Pundit complet (include Pundit::Authorization, verify_authorized, rescue_from)
- [✅] RSpec setup + minitest configuration
- [✅] FactoryBot (factories/) NOT fixtures
- [✅] Database cleaner + Transaction rollback

**Jour 5 : CI/CD GitHub Actions** ⚠️ **CRITIQUE - FAIRE MAINTENANT**
- [✅] GitHub Actions workflow (tests, linting, security)
- [✅] Tests automatisés dans CI (coverage >70% dès Week 2, pas Week 5)
- [ ] Prometheus + Grafana basique (optionnel MVP)
- [ ] Let's Encrypt préconfiguré (optionnel MVP)

---

### **PHASE 4 - DÉVELOPPEMENT ITÉRATIF** (Cycle unique de 3 semaines)

#### 🎯 **Objectifs**
- Développement TDD avec revues de code
- Tests automatisés et performance
- Déploiement continu

#### 📋 **Sprint 1-2 : Authentification & Base** ✅ (TERMINÉ)
- [✅] Système d'authentification (Devise)
- [✅] Gestion des rôles (enum avec validations Rails 8)
- [✅] Dashboard de base
- [✅] Présentation association
- [✅] E-commerce complet

#### 📋 **Sprint 3-4 : Événements & Paiement** (Phase 2 - Week 1-2)
- [✅] **CRUD événements complet** (modèles stables d'abord)
- [ ] **Calendrier interactif** (FullCalendar)
- [✅] **Système d'inscription** aux événements
- [ ] Intégration HelloAsso (optionnel Phase 2)
- [✅] Gestion des inscriptions

#### 📋 **Sprint 5 : Admin Panel (ActiveAdmin)**

> **📋 Voir [`cycle-01-phase-2-plan.md`](cycle-01-phase-2-plan.md) pour le plan détaillé complet**

**Résumé** :
- ✅ **Pré-requis** : Modèles Phase 2 créés et stables
- ✅ **Jour 5-10** : Tests RSpec complets (>70% coverage)
- ✅ **Jour 11** : Installation ActiveAdmin (génère automatiquement tout)
- [✅] **Jour 12-13** : Customisation ActiveAdmin
- [ ] **Jour 14-15** : Tests admin + finalisation

**⚠️ IMPORTANT** : Ne pas créer contrôleurs/routes manuels avant ActiveAdmin (voir [`cycle-01-phase-2-plan.md`](cycle-01-phase-2-plan.md))

#### 📋 **Sprint 6 : Initiation & Finalisation** (Phase 2 - Week 3)
- [ ] Module initiation
- [ ] Gestion des créneaux
- [ ] Système de prêt matériel
- [ ] Upload photos (Active Storage)
- [ ] Notifications email (code présent, non validé en production)
- [✅] Tests de régression (coverage >70% maintenu)

#### 🛠️ **Actions par Sprint (Rails 8 TDD)**

1. **Planification** (1h)
   - Sélection des User Stories
   - Estimation des tâches
   - Répartition des rôles

2. **Développement TDD** (4 jours)
   - **Tests AVANT code** (TDD strict)
   - RSpec + FactoryBot (pas fixtures)
   - Revues de code croisées
   - Tests d'intégration (Capybara)
   - Coverage >70% **maintenu en continu** (pas à la fin)

3. **Déploiement** (1 jour)
   - Tests en staging
   - Démonstration
   - Feedback et ajustements

#### ⚠️ **SÉQUENCE CRITIQUE Rails 8 (Ordre à Respecter)**

```
JOUR 1: Rails 8 + Docker ✓
  ↓
JOUR 2-3: Devise (User model + auth) ✓
  ↓
JOUR 4: Pundit setup + RSpec setup ✓
  ↓
JOUR 5: CI/CD GitHub Actions ✓
  ↓
JOUR 6-7: Models Event/Route/Attendance (Routes AVANT Events!) ✓
  ↓
JOUR 8: Controllers CRUD Events ✓
  ↓
JOUR 9: Inscriptions + Calendrier (Inscriptions ✓, Calendrier 🔜)
  ↓
JOUR 10: Tests unitaires & intégration (Coverage >70%) ✓
  ↓
JOUR 11: Pundit Policies + Finalisation modèles (100% stables) ✓
  ↓
JOUR 12: ⚠️ INSTALL ACTIVEADMIN (après modèles garantis stables) ✓
  ↓
JOUR 13-14: ActiveAdmin customisation (filtres, bulk actions, exports) ✓
  ↓
JOUR 15: Tests Admin + Notifications + Performance (Brakeman) (Notifications ✓, Tests Admin 🔜, Performance 🔜)
```

---

### **PHASE 5 - TESTS & OPTIMISATION** (Intégré dans Phase 2 - Week 3)

> ⚠️ **CORRIGÉ** : Tests doivent être faits **en parallèle du développement** (TDD), pas à la fin. Coverage >70% dès Week 2.

#### 🎯 **Objectifs**
- Tests de montée en charge
- Optimisation des performances
- Mise en cache

#### 📋 **Livrables**
- [ ] Tests de charge (JMeter/k6)
- [ ] Optimisation des requêtes
- [ ] Mise en cache Redis
- [ ] CDN et compression

#### 🛠️ **Actions (Réparties sur Phase 2)**

**Week 1-2 : Tests TDD (en parallèle)**
- [✅] Model tests (validations, associations, scopes)
- [✅] Controller tests (RSpec avec let + factories)
- [✅] Integration tests (Capybara)
- [✅] **Coverage >70%** (unitaire + intégration) ← **OBLIGATOIRE dès Week 2**

**Week 3 : Performance & Optimisation (OPTIONNEL pour MVP)**
1. **Optimisation requêtes** (obligatoire)
   - Identification N+1 queries
   - Optimisation requêtes (includes, joins)
   - Index database si nécessaire

2. **Audit sécurité** (obligatoire)
   - Brakeman security audit
   - Fixes vulnérabilités

3. **Tests de charge** (optionnel MVP associatif)
   - ⚠️ **Si temps** : Tests simple via k6 (10→100 users)
   - ⚠️ **Si pas temps** : Sauter, faire en Cooldown
   - **Note** : Coverage >70% suffit pour MVP. Tests de charge coûtent du temps sans ROI immédiat.

4. **Mise en cache** (optionnel MVP)
   - Cache fragment Rails
   - Redis pour sessions
   - CDN pour assets

---

### **PHASE 6 - DÉPLOIEMENT PRODUCTION** (fin Semaine 3 ou début Cooldown)

#### 🎯 **Objectifs**
- Déploiement en production
- Formation des administrateurs
- Documentation opérationnelle

#### 📋 **Livrables**
- [ ] Déploiement production
- [ ] SSL automatisé (Let's Encrypt)
- [ ] **Rollback strategy production** ← **CRITIQUE** (procédure documentée)
- [ ] **Error tracking (Sentry / Rollbar)** ← **CRITIQUE** (bugs invisibles production)
- [ ] Documentation runbook
- [ ] **Formation bénévoles** : durée/format/docs (budgéter 4h formation + docs)

#### 🛠️ **Actions**
1. **Déploiement** (2 jours)
   - Migration des données
   - Configuration DNS
   - Tests de production

2. **Formation** (2 jours)
   - Documentation utilisateur
   - Formation administrateurs
   - Procédures de maintenance

3. **Monitoring** (1 jour)
   - Alertes de production
   - Métriques de santé
   - Procédures d'incident

---

### **PHASE 7 - MAINTENANCE & ÉVOLUTION** (Continue)

#### 🎯 **Objectifs**
- Maintenance continue
- Évolutions fonctionnelles
- Monitoring 24/7

#### 📋 **Actions**
- **Sprint mensuel** : Correctifs et nouvelles demandes
- **Monitoring 24/7** : Alertes et métriques
- **Revue trimestrielle** : Sécurité et audit

---

## 🛠️ STACK TECHNIQUE

### **Backend**
- **Rails 8** (dernière version)
- **Ruby 3.3+**
- **PostgreSQL** (base de données)
- **Redis** (cache et sessions)
- **Sidekiq** (background jobs)

### **Frontend**
- **Bootstrap 5.5** (UI framework)
- **Stimulus** (JavaScript framework)
- **Turbo** (navigation SPA)
- **FullCalendar** (calendrier)

### **Intégrations**
- **HelloAsso API** (paiements)
- **Twitter API** (réseaux sociaux)
- **Facebook API** (réseaux sociaux)

### **DevOps**
- **GitHub Actions** (CI/CD)
- **Docker** (containerisation)
- **Prometheus + Grafana** (monitoring)
- **Let's Encrypt** (SSL)

---

## 📊 MÉTRIQUES DE SUCCÈS

### **Techniques**
- ✅ 100% de couverture de tests
- ✅ 0 erreur de linting
- ✅ Temps de réponse < 200ms
- ✅ Uptime > 99.9%

### **Fonctionnelles**
- ✅ Inscription utilisateur < 2 minutes
- ✅ Création d'événement < 5 minutes
- ✅ Paiement HelloAsso < 3 minutes
- ✅ Partage réseaux sociaux < 1 minute

### **Business**
- ✅ +50% d'inscriptions aux événements
- ✅ +30% d'adhésions en ligne
- ✅ -70% de temps administratif
- ✅ +100% de visibilité sur réseaux sociaux

---

## 🚨 POINTS CRITIQUES & ERREURS À ÉVITER

### **❌ Erreurs Fréquentes**
1. **Périmètre flou** → User Stories claires dès le début
2. **Absence de tests** → TDD obligatoire
3. **Pas de CI/CD** → Automatisation dès le début
4. **Ignorer la montée en charge** → Tests de performance
5. **Documentation négligée** → README et runbooks
6. **Revue de code insuffisante** → Pull requests obligatoires
7. **Monitoring absent** → Alertes 24/7
8. **⚠️ ActiveAdmin installé trop tôt** → Attendre modèles stables (Jour 8+)
9. **⚠️ Tests à la fin** → TDD dès le début (coverage >70% Week 2)
10. **⚠️ CI/CD trop tard** → Configurer Jour 4-5, pas Semaine 1

### **✅ Bonnes Pratiques Rails 8**
1. **Architecture claire** → Diagrammes et documentation
2. **Tests complets TDD** → Unitaires, intégration, e2e (dès Week 1-2)
3. **CI/CD tôt** → Déploiement automatisé (Jour 4-5)
4. **Performance** → Tests de charge réguliers
5. **Sécurité** → Audit et mise à jour
6. **Monitoring** → Métriques et alertes
7. **Documentation** → Toujours à jour
8. **Énums avec validations** → `enum role: [...], validate: true`
9. **Pundit AVANT contrôleurs** → Policies d'abord
10. **ActiveAdmin APRÈS tests complets** → Jour 11-12 uniquement (choix pour contexte associatif : stabilité 14+ ans, zéro maintenance, interface graphique complète)
11. **⚠️ Routes migration AVANT Events** → Ordre migrations critique (Event dépend de Route via FK)

### **🎯 Checklist Implémentation Rails 8 (Révisée)**

#### ✅ Phase 1 (Semaines 1-2) - TERMINÉE
- [✅] Rails 8 + Docker
- [✅] Devise + User model
- [✅] Role enum avec validations
- [✅] E-commerce CRUD (current state)

#### ✅ Phase 2 Révisée (Semaines 3-4) - EN COURS
> **📋 Voir [`cycle-01-phase-2-plan.md`](cycle-01-phase-2-plan.md) pour le plan détaillé**

- [✅] **EVENT models** (Route, Event, Attendance, OrganizerApplication, Partner, ContactMessage, AuditLog) ✅
- [✅] **Migrations appliquées** (7 migrations Phase 2) ✅
- [✅] **Seeds créés et testés** (Phase 2) ✅
- [✅] **Modèles stables** (validations, associations, scopes) ✅
- [✅] **Tests RSpec complets (>70% coverage)** ← **OK (75 exemples, 0 échec)**
- [✅] **ActiveAdmin** (Jour 11, après tests >70%)
- [✅] **Customisation ActiveAdmin** (Jour 12-13)
- [ ] **Tests admin + finalisation** (Jour 14-15)

#### ✅ Phase 3 (Semaine 5)
- [ ] Performance tests
- [ ] Cache strategy (Redis)
- [ ] CDN assets
- [ ] Production deploy

---

## 📋 RÉSUMÉ DES CORRECTIONS APPORTÉES (Analyse Rails 8)

### 🔴 Problèmes Critiques Corrigés

1. **✅ Ordre des Dépendances Fondamentales**
   - **AVANT** : CI/CD en Semaine 1
   - **APRÈS** : CI/CD Jour 4-5 (AVANT modèles métier)

2. **✅ Admin Panel - Installation Timing (CRITIQUE)**
   - **AVANT** : Administrate Semaine 3-4 (Sprint 5)
   - **APRÈS** : **ActiveAdmin** Jour 11-12 (APRÈS tests complets >70% coverage)
   - **POURQUOI ActiveAdmin ?** Contexte associatif → stabilité 14+ ans, zéro maintenance post-livraison, interface graphique pour bénévoles non-tech, features complètes (export CSV, filtres, bulk actions)
   - **POURQUOI Jour 11-12 ?** ActiveAdmin génère du code pour chaque model. Si model change → code généré invalide. Mieux attendre modèles rock-solid (migrations + validations + associations 100% définitives + tests passing)

3. **✅ Énums + Validations Rails 8**
   - **AVANT** : `enum role: [:user, :admin]` (risky)
   - **APRÈS** : `enum role: [:user, :admin], validate: true` (secure)

4. **✅ Ordre Modèles - Associations Complexes**
   - **AVANT** : Ordre non spécifié
   - **APRÈS** : Base → FK simples → Joins/polymorphes → Dépendants

5. **✅ ApplicationController Setup**
   - **AVANT** : Setup incomplet
   - **APRÈS** : Pundit complet + rescue_from + verify_authorized

6. **✅ Testing Order (TDD)**
   - **AVANT** : Tests >70% Week 5
   - **APRÈS** : TDD dès Week 1-2, coverage >70% maintenu

7. **✅ Séquence Devise + Pundit + ActiveAdmin**
   - **AVANT** : Ordre flou
   - **APRÈS** : Timeline jour par jour détaillée (Jour 1 → 13+)
   - **CHOIX ActiveAdmin** : Contexte associatif nécessite stabilité, zéro maintenance, interface graphique complète

### 📊 Recommandations Structurelles Intégrées

- **A. Refactoriser Phase 2** : Semaine 3 détaillée jour par jour
- **B. Testing Order** : TDD dès Week 1, pas Week 5
- **C. Séquence Complète** : Timeline jour par jour (Jour 1 → 15)
- **D. Choix ActiveAdmin** : Contexte associatif → stabilité, zéro maintenance, interface graphique complète

---

## 📅 TIMELINE ACTUALISÉE

### ✅ PHASE 1 - E-COMMERCE (TERMINÉE - Nov 2025)

| Semaine | Phase | Objectifs | Livrables | État |
|---------|-------|-----------|-----------|------|
| 1-2 | Building (S1) | Setup Rails 8, Auth (Devise), Rôles, E-commerce complet | Auth + rôles, Boutique fonctionnelle, Docker configuré | ✅ TERMINÉ |

**Livrables Phase 1** :
- ✅ Rails 8.0.4 configuré avec Docker
- ✅ Authentification Devise + 7 niveaux de rôles
- ✅ E-commerce complet (catalogue, panier, checkout, commandes)
- ✅ Documentation complète (README, setup, architecture)
- ✅ Seeds complets avec données de test

### 🔜 PHASE 2 - ÉVÉNEMENTS (À PLANIFIER - ORDRE CORRIGÉ Rails 8)

> **📋 Checklist complète jour par jour** : Voir [`CHECKLIST_PHASE2.md`](CHECKLIST_PHASE2.md)

> ⚠️ **CRITIQUE** : L'ordre d'implémentation a été révisé selon les bonnes pratiques Rails 8.  
> **ActiveAdmin doit être installé APRÈS tests complets** (Jour 11-12), pas avant.  
> **Pourquoi ActiveAdmin (et pas Administrate) ?** Contexte association avec bénévoles non-tech → besoin de stabilité (14+ ans), zéro maintenance post-livraison, interface graphique complète, features out-of-the-box (export CSV, filtres, bulk actions).  
> **⚠️ ORDRE MIGRATIONS CRITIQUE** : Routes AVANT Events (Event dépend de Route via FK `route_id`).

| Semaine | Phase | Objectifs | Livrables | État |
|---------|-------|-----------|-----------|------|
| 1-2 | Building (S1) | CRUD Événements, Inscriptions, Calendrier | Événements fonctionnels, système d'inscription | ✅ TERMINÉ (CRUD ✅, Inscriptions ✅, Calendrier 🔜) |
| 3 | Building (S2) | **Modèles stables → ActiveAdmin (Jour 11+)**, Permissions fines (Pundit), Upload photos, Notifications | Rôles/permissions, gestion médias, admin minimal (ActiveAdmin), mails | ✅ TERMINÉ (ActiveAdmin ✅, Pundit ✅, Upload photos 🔜, Notifications 🔜) |

#### 📋 **SÉQUENCE DÉTAILLÉE - Phase 2**

> **📋 Voir [`cycle-01-phase-2-plan.md`](cycle-01-phase-2-plan.md) pour le plan détaillé jour par jour avec checklist complète et pièges à éviter**

**Résumé rapide** :
- ✅ **Jour 1-2** : Modèles et migrations Phase 2 créés et appliqués
- ✅ **Jour 5-10** : Tests RSpec complets (>70% coverage) réalisés
- ✅ **Jour 11** : Installation ActiveAdmin (génère automatiquement contrôleurs/vues/routes)
- 🔜 **Jour 12-13** : Customisation ActiveAdmin
- 🔜 **Jour 12-13** : Ajout du module `Role` dans ActiveAdmin + ajustement Pundit pour hiérarchie dynamique
- 🔜 **À programmer (Cooldown ou phase suivante)** : Exposer `payments`, `product_variants`, `option_types/values` dans ActiveAdmin + batch actions / exports avancés
- 🔜 **Jour 14-15** : Tests admin + finalisation

**⚠️ PIÈGE CRITIQUE** : Ne pas créer contrôleurs/routes manuels avant ActiveAdmin (voir détails dans [`cycle-01-phase-2-plan.md`](cycle-01-phase-2-plan.md))

| 5-6 | Building (S3) | Tests (>70%), Performance, Sécurité (Brakeman), Déploiement prod | Coverage OK, audit sécurité, déploiement finalisé | 🔜 À VENIR |

---

## 🎯 CONCLUSION

Ce fil conducteur garantit une livraison progressive, un maximum de visibilité et un contrôle qualité continu. L'utilisation de Trello optimise la collaboration à deux, tandis que Rails 8, Bootstrap et les pipelines automatisés assurent rapidité, sécurité et maintenabilité.

### État Actuel (Jan 2025)
- ✅ **Phase 1 E-commerce** : Terminée et fonctionnelle
- 🔄 **Phase 2 Événements** : Modèles et migrations créés ✅, contrôleurs et vues à venir

**Prochaines étapes** :
1. ✅ Validation du fil conducteur
2. ✅ Création du tableau Trello
3. ✅ Phase 1 E-commerce terminée
4. ✅ Planification Phase 2 - Événements
5. ✅ Modèles et migrations Phase 2 créés et appliqués
6. ✅ Seeds Phase 2 créés et testés
7. ✅ RSpec configuré
8. ✅ Tests RSpec Phase 2 complets (coverage >70%)
9. ✅ ActiveAdmin (Jour 11, après tests >70%)
10. 🔜 Customisation ActiveAdmin (Jour 12-13)
11. 🔜 Exposition `Role` dans ActiveAdmin + policy Pundit
12. 🔜 Tests admin + permissions (Jour 14-15)

**⚠️ IMPORTANT** : Voir [`cycle-01-phase-2-plan.md`](cycle-01-phase-2-plan.md) pour le plan détaillé Phase 2 avec les pièges à éviter

---

## ✅/🔜 SUIVI D'AVANCEMENT (État actuel - Jan 2025)

### ✅ PHASE 1 - E-COMMERCE (TERMINÉE)

#### Authentification & Rôles
- [✅] Base Users (Devise) + détails (`first_name`, `last_name`, `bio`, `phone`, `avatar_url`)
- [✅] Table `roles` conforme (ajout `code` unique + `level`) et FK `users.role_id`
- [✅] Seeds rôles (7 niveaux: USER→SUPERADMIN) et Florian en SUPERADMIN
- [✅] Devise configuré et fonctionnel
- [✅] Système de rôles opérationnel

#### E-commerce - Base de données
- [✅] Boutique: `product_categories`, `products`, `product_variants`, `option_types`, `option_values`, `variant_option_values`
- [✅] Paiements (`payments`) et commandes (`orders`, `order_items`)
- [✅] FK `order_items.variant_id → product_variants.id` + seeds corrigés
- [✅] 13 migrations appliquées avec succès
- [✅] Seeds complets (7 rôles, utilisateurs, produits, commandes, paiements)

#### E-commerce - Fonctionnalités
- [✅] **Boutique fonctionnelle complète** :
  - [✅] Catalogue produits (index/show) avec variantes
  - [✅] Panier session (add/update/remove/clear)
  - [✅] Checkout (création commande + déduction stock)
  - [✅] Historique commandes (index/show)
  - [✅] Guardrails (validation stock, quantité max, variantes actives)
  - [✅] UX quantité limitée au stock sur fiche produit

#### Infrastructure & Documentation
- [✅] Setup Rails 8.0.4 avec Docker (dev/staging/prod)
- [✅] PostgreSQL 16 configuré
- [✅] Docker Compose pour 3 environnements
- [✅] Documentation complète mise à jour (README, setup guides, architecture)
- [✅] Credentials Rails configurés et régénérés

#### Simplification formulaire inscription + Confirmation email (2025-11-24)
- [✅] **Formulaire simplifié** : 4 champs uniquement (Email, Prénom, Mot de passe 12 caractères, Niveau)
- [✅] **Skill level** : Cards Bootstrap visuelles (Débutant, Intermédiaire, Avancé)
- [✅] **Confirmation email** : Accès immédiat + confirmation requise pour actions critiques
- [✅] **Email de bienvenue** : UserMailer avec template HTML responsive
- [✅] **Améliorations UX** : Header moderne, labels avec icônes, help text positif
- [✅] **Conformité** : NIST 2025 (12 caractères), WCAG 2.2 (focus 3px, cibles tactiles)
- [✅] **Corrections finales** :
  - Traductions I18n corrigées (12 caractères)
  - Redirection erreurs : reste sur `/users/sign_up`
  - CSS input-group : contour englobe input + toggle
  - Rack::Attack : correction accès match_data
  - Page profil : skill level ajouté avec cards Bootstrap

#### Pages légales & Conformité RGPD (2025-11-21)
- [✅] **Pages légales complètes** :
  - [✅] Mentions Légales (`/mentions-legales`) - Conforme LCEN
  - [✅] Politique de Confidentialité (`/politique-confidentialite`, `/rgpd`) - Conforme RGPD
  - [✅] Conditions Générales de Vente (`/cgv`) - Conforme Code consommation
  - [✅] Conditions Générales d'Utilisation (`/cgu`)
  - [✅] Page Contact (`/contact`) - Email uniquement
- [✅] **Gestion des cookies conforme RGPD 2025** :
  - [✅] Banner de consentement automatique (Stimulus Controller)
  - [✅] Page de préférences détaillée (`/cookie_consent/preferences`)
  - [✅] Gestion granulaire (nécessaires, préférences, analytiques)
  - [✅] Cookies de session Rails documentés (panier, authentification)
- [✅] Routes RESTful modernes (`resource :cookie_consent`)
- [✅] Footer mis à jour avec tous les liens légaux

### 🔜 PHASE 2 - ÉVÉNEMENTS (À VENIR)

#### Améliorations E-commerce
- [🔜] **Boutique UX/UI** : Améliorations visuelles et expérience utilisateur
- [🔜] Panier persistant pour utilisateurs connectés (fusion session/DB)

#### Authentification avancée
- [✅] Permissions fines (Pundit: politiques + intégration)
- [ ] Vues Devise personnalisées si nécessaire

#### Module Événements
- [✅] Modèles: `routes`, `events`, `attendances`, `organizer_applications`, `partners`, `contact_messages`, `audit_logs` ✅
- [✅] Migrations appliquées (7 migrations Phase 2) ✅
- [✅] Seeds créés et testés (Phase 2) ✅
- [✅] CRUD événements complet
- [ ] Calendrier interactif
- [✅] Inscription aux événements
- [ ] Gestion des parcours (GPX)

#### Administration
- [✅] Interface admin minimale
- [✅] Validation des organisateurs
- [ ] Statistiques d'utilisation
- [ ] Exposition admin des entités e-commerce secondaires (`payments`, `product_variants`, `option_types/values`) + batch actions/exports personnalisés (après livraison des CRUD front)

#### Médias & Notifications
- [ ] Upload photos (Active Storage)
- [ ] Notifications email (inscription événement, rappel) - code présent, non validé

#### Tests & Qualité ⚠️ **CORRIGÉ - TDD dès le début**
- [✅] RSpec configuré ✅
- [✅] Model specs Phase 2 >70% coverage (à maintenir)
- [✅] Tests d'intégration (Capybara) à ajouter
- [ ] Tests de performance (Week 3)
- [✅] Audit sécurité complet (Brakeman) - Week 3

#### Déploiement
- [ ] Déploiement production finalisé
- [ ] Formation utilisateurs

---

## 📋 AMÉLIORATIONS FUTURES (Backlog)

### 🛒 Panier - Persistance pour utilisateurs connectés

**Problème actuel** :
- Le panier est stocké uniquement dans `session[:cart]` (cookies)
- Perdu si cookie expiré/supprimé
- Pas de synchronisation multi-appareils
- Même système pour connectés/non connectés

**Solution proposée** :
1. **Table `carts`** (optionnel) ou utiliser `orders` avec `status: 'cart'`
   - `user_id` (nullable pour non connectés)
   - `session_id` (pour non connectés)
   - `created_at`, `updated_at`

2. **Fusion automatique** :
   - À la connexion : fusionner `session[:cart]` avec panier DB de l'utilisateur
   - Synchronisation entre appareils pour utilisateurs connectés

3. **Migration progressive** :
   - Utilisateurs connectés : panier en DB
   - Utilisateurs non connectés : panier en session (comme actuellement)

**Priorité** : Basse (fonctionnel actuellement, amélioration UX)

---

### 🎨 Boutique - Variantes de couleurs avec changement d'images

**Problème actuel** :
- Chaque couleur est un produit séparé (ex: "Veste - Noir", "Veste - Bleu", "Veste - Blanc")
- Duplication de produits pour chaque couleur
- L'image ne change pas dynamiquement selon la couleur sélectionnée dans les variantes
- Gestion complexe des stocks et prix par couleur

**Solution proposée** :
1. **Migration structure** :
   - Ajouter colonne `image_url` à la table `product_variants`
   - Regrouper les produits par couleur en un seul produit avec variantes
   - Migration des données existantes (fusionner produits de même famille)

2. **Logique de changement d'image** :
   - Stocker l'image dans `product_variants.image_url` (fallback sur `product.image_url`)
   - JavaScript pour changer l'image dynamiquement selon la variante sélectionnée
   - API endpoint optionnel pour récupérer l'image d'une variante

3. **Structure** : Un produit avec variantes (couleur, taille) → image par variante

4. **Avantages** :
   - Un seul produit à gérer au lieu de N produits (N = nombre de couleurs)
   - Image change automatiquement selon la sélection
   - Meilleure organisation des stocks et prix
   - URL produit unique (SEO amélioré)

**Priorité** : Moyenne (amélioration structurelle importante, mais fonctionnel actuellement)

---

### 🎨 Boutique - Améliorations UX/UI

**État actuel** :
- ✅ Fonctionnalités de base opérationnelles (catalogue, panier, checkout)
- ✅ Guardrails techniques (stock, validations)
- 🔜 Améliorations visuelles et expérience utilisateur à définir

**À venir** :
- Améliorations UX/UI selon spécifications détaillées (en attente)

**Priorité** : Haute (amélioration immédiate de l'expérience utilisateur)

---

*Document créé le : $(date)*  
*Version : 1.0*  
*Équipe : 2 développeurs*
