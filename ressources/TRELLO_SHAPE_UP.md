# 📋 Configuration Trello - Shape Up (3 semaines, 4 personnes)

## 🎯 Structure du Tableau

### Colonnes Principales (Shape Up Adapté)

#### 📥 **Shaping** (2-3 jours)
- Épopées et User Stories en cours de définition
- Champs personnalisés : Priorité (P0-P3), Estimation (points), Assigné
- Labels : Front, Back, Design, Ops

#### 📋 **Betting Table** (1 jour)
- Pitches prêts pour validation
- Critères d'acceptation définis
- Estimation validée

#### 🔄 **Building** (3 semaines)
- Une carte = une feature active
- Limite : 1-2 cartes par développeur (4 personnes = 4-8 cartes max)
- Mise à jour quotidienne

#### 👀 **En Revue/QA**
- Tests unitaires et d'intégration
- Revue de code croisée
- Tests de régression

#### ✅ **Shippable**
- Feature complète déployable en production
- Tests de performance OK
- Documentation mise à jour

#### 🏁 **Terminé**
- Historique des livrables
- Métriques de vélocité

#### 🚫 **Cooldown** (1 semaine)
- Bug fixes prioritaires
- Technical debt paydown
- R&D personnel
- Formation

---

## 🎯 Cartes par Phase Shape Up

### **PHASE 1 : SHAPING** (2-3 jours)

#### Cartes à créer :
- [X] **Identifier problème utilisateur**
  - Description : Communauté roller dispersée (Facebook, WhatsApp)
  - Labels : Design, Front
  - Estimation : 1 point
  - Assigné : Product Owner

- [X **Définir appetite (3 semaines)**
  - Description : Appetite fixe, scope flexible
  - Labels : Ops
  - Estimation : 1 point
  - Assigné : Tech Lead

- [X] **Breadboarding solution**
  - Description : Wireframes grossiers (Excalidraw)
  - Labels : Design, Front
  - Estimation : 2 points
  - Assigné : UX Designer

- [X] **Identifier rabbit holes**
  - Description : Liste des No-Gos (microservices, Kubernetes, etc.)
  - Labels : Ops
  - Estimation : 1 point
  - Assigné : Tech Lead

- X] **Écrire pitch (1 page A4)**
  - Description : Problème → Solution → Appetite → No-Gos
  - Labels : Ops
  - Estimation : 2 points
  - Assigné : Product Owner

### **PHASE 2 : BETTING TABLE** (1 jour)

#### Cartes à créer :
- [X] **Présenter pitch (15 min)**
  - Description : Présentation + questions + validation
  - Labels : Ops
  - Estimation : 1 point
  - Assigné : Product Owner

- [X] **Décision finale**
  - Description : Vote + engagement + documentation
  - Labels : Ops
  - Estimation : 1 point
  - Assigné : Tech Lead

### **PHASE 3 : BUILDING** (3 semaines)

#### Semaine 1 : Get One Piece Done (✅ TERMINÉ - Phase 1 E-commerce)
- [X] **Setup projet Rails 8**
  - Description : `rails new grenoble-roller --database=postgresql --css=bootstrap`
  - Labels : Back, Ops
  - Estimation : 3 points
  - Assigné : Tech Lead
  - ✅ **STATUS** : Terminé - Rails 8.0.4 configuré avec Docker

- [X] **Schéma boutique + seeds de base**
  - Description : Catégories, Produits, Variantes, Options, Commandes, Paiements + FK OrderItems→Variants
  - Labels : Back
  - Estimation : 3 points
  - Assigné : Backend Dev
  - ✅ **STATUS** : Terminé - 13 migrations appliquées, seeds complets

- [X] **Boutique fonctionnelle complète**
  - Description : Catalogue, Panier session, Checkout, Historique commandes, Guardrails stock
  - Labels : Back, Front
  - Estimation : 8 points
  - Assigné : Fullstack Dev
  - ✅ **STATUS** : Terminé - Toutes les fonctionnalités e-commerce opérationnelles

- [ ] **Boutique UX/UI améliorations**
  - Description : Améliorations visuelles et expérience utilisateur selon spécifications
  - Labels : Front, Design
  - Estimation : 5 points
  - Assigné : Frontend Dev
  - 🔜 **STATUS** : En attente - Fonctionnel mais améliorations UX prévues

- [X] **Authentification de base**
  - Description : Devise installé + rôles (7 niveaux: USER à SUPERADMIN)
  - Labels : Back, Front
  - Estimation : 5 points
  - Assigné : Backend Dev
  - ✅ **STATUS** : Terminé - Devise configuré, 7 rôles créés, système de permissions en place

- [ ] **Premier événement CRUD** (Phase 2)
  - Description : Créer, lire, modifier, supprimer événements
  - Labels : Back, Front
  - Estimation : 5 points
  - Assigné : Fullstack Dev
  - 🔜 **STATUS** : Phase 2 - À venir après finalisation e-commerce

- [ ] **Inscription événement** (Phase 2)
  - Description : Un utilisateur peut s'inscrire à un événement
  - Labels : Back, Front
  - Estimation : 3 points
  - Assigné : Frontend Dev
  - 🔜 **STATUS** : Phase 2 - À venir après finalisation e-commerce

#### Semaine 2 : Map Scopes (Phase 2 - Événements)
- [ ] **Gestion des rôles et permissions** (Phase 2)
  - Description : Pundit pour autorisation fine (actuellement rôles basiques en place)
  - Labels : Back
  - Estimation : 3 points
  - Assigné : Backend Dev
  - 🔜 **STATUS** : Phase 2 - Rôles créés, permissions fines à implémenter

- [ ] **Upload et gestion des photos** (Phase 2)
  - Description : Photos d'événements (Active Storage)
  - Labels : Back, Front
  - Estimation : 5 points
  - Assigné : Fullstack Dev
  - 🔜 **STATUS** : Phase 2 - À venir avec module événements

- [ ] **Interface admin** (Phase 2)
  - Description : Valider les organisateurs, gestion événements
  - Labels : Back, Front
  - Estimation : 5 points
  - Assigné : Frontend Dev
  - 🔜 **STATUS** : Phase 2 - À venir avec module événements

- [ ] **Notifications email** (Phase 2)
  - Description : Inscription événement, rappel
  - Labels : Back
  - Estimation : 3 points
  - Assigné : Backend Dev
  - 🔜 **STATUS** : Phase 2 - À venir avec module événements

#### Semaine 3 : Downhill Execution (Phase 1 E-commerce)
- [X] **Documentation**
  - Description : README complet, runbooks, setup guides
  - Labels : Ops
  - Estimation : 2 points
  - Assigné : Tech Lead
  - ✅ **STATUS** : Terminé - Documentation complète mise à jour (Nov 2025)

- [ ] **Tests complets** (Phase 1 ou 2)
  - Description : RSpec + Capybara (coverage >70%)
  - Labels : Back, Front
  - Estimation : 5 points
  - Assigné : Tous
  - 🔜 **STATUS** : À planifier - Tests unitaires et intégration

- [ ] **Tests de performance** (Phase 1 ou 2)
  - Description : Tests de charge basiques
  - Labels : Ops
  - Estimation : 2 points
  - Assigné : Tech Lead
  - 🔜 **STATUS** : À planifier

- [ ] **Audit sécurité** (Phase 1 ou 2)
  - Description : Brakeman + review credentials
  - Labels : Ops
  - Estimation : 1 point
  - Assigné : Tech Lead
  - 🔜 **STATUS** : À planifier - Credentials régénérés, audit complet à faire

- [ ] **Déploiement production** (Phase 1 ou 2)
  - Description : Application en ligne (staging/prod configurés)
  - Labels : Ops
  - Estimation : 3 points
  - Assigné : Tech Lead
  - 🔜 **STATUS** : Docker configuré (dev/staging/prod), déploiement à finaliser

### **PHASE 4 : COOLDOWN** (1 semaine)

#### Cartes à créer :
- [ ] **Bug fixes prioritaires**
  - Description : Problèmes signalés par utilisateurs
  - Labels : Back, Front
  - Estimation : 3 points
  - Assigné : Tous

- [ ] **Technical debt paydown**
  - Description : Refactoring, tests manquants
  - Labels : Back, Front
  - Estimation : 5 points
  - Assigné : Tous

- [ ] **R&D personnel**
  - Description : Explorer nouvelles libs, POCs
  - Labels : Back, Front
  - Estimation : 3 points
  - Assigné : Tous

- [ ] **Formation**
  - Description : Apprendre nouvelles technos
  - Labels : Back, Front
  - Estimation : 2 points
  - Assigné : Tous

- [ ] **Rétrospective**
  - Description : Améliorer process Shape Up
  - Labels : Ops
  - Estimation : 1 point
  - Assigné : Tech Lead

---

## 🎯 Configuration Trello (4 personnes)

### Rôles Équipe
- **Tech Lead** : Architecture, DevOps, coordination
- **Backend Dev** : Rails, API, base de données
- **Frontend Dev** : Bootstrap, JavaScript, UX
- **Fullstack Dev** : Polyvalent, support équipe

### Champs Personnalisés
- **Priorité** : P0 (Critique), P1 (Haute), P2 (Moyenne), P3 (Basse)
- **Estimation** : Points (1, 2, 3, 5, 8)
- **Assigné** : Tech Lead, Backend Dev, Frontend Dev, Fullstack Dev
- **Phase** : Shaping, Betting, Building, Cooldown

### Labels
- **Front** : Interface utilisateur
- **Back** : Backend, API
- **Design** : UX/UI, wireframes
- **Ops** : DevOps, déploiement
- **Test** : Tests, QA
- **Doc** : Documentation

### Power-Ups Recommandés
- **Calendar** : Voir les deadlines
- **Custom Fields** : Priorité, estimation
- **Butler** : Automatisation basique

---

## 📊 Métriques Shape Up (3 semaines, 4 personnes)

### Vélocité
- **Points par semaine** : 15-20 points par personne (60-80 points total)
- **Burndown chart** : Suivi quotidien
- **Hill Chart** : Position montée/descente

### Répartition des Points (Phase 1 - E-commerce)
- **Semaine 1** : ✅ 19 points terminés (Setup + Boutique + Auth base)
- **Semaine 2** : 🔜 Phase 2 - Événements (à planifier)
- **Semaine 3** : 🔜 Phase 2 - Finalisation (à planifier)

### État Actuel (Nov 2025)
- ✅ **Phase 1 E-commerce** : Terminée (boutique fonctionnelle complète)
- 🔜 **Phase 2 Événements** : À venir (CRUD événements, inscriptions, etc.)

### Critères de "Done"
- [ ] Tests passent (coverage >70%)
- [ ] Code review approuvé
- [ ] Documentation mise à jour
- [ ] Déployable en production
- [ ] Performance acceptable

---

## 🚨 Règles Shape Up (3 semaines)

### ✅ À Faire
- **Appetite fixe** : 3 semaines, scope flexible
- **Cooldown obligatoire** : 1 semaine de repos
- **Feature shippable** : Déployable en production
- **Pas de backlog** : Projet unique
- **Limite cartes** : 1-2 cartes par personne max

### ❌ À Éviter
- **Sprints fragmentés** : Pas de 1 semaine
- **Backlog infini** : Pas de sprint planning
- **Estimation en temps** : Utiliser points
- **Sauter cooldown** : Santé équipe prioritaire
- **Over-engineering** : MVP simple d'abord

---

*Configuration Trello selon méthodologie Shape Up*  
*Version : 2.0 - Shape Up Adapté (3 semaines, 4 personnes)*
