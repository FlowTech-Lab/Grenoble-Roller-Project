# 📋 Configuration Trello - Shape Up

## 🎯 Structure du Tableau

### Colonnes Principales (Shape Up)

#### 📥 **Shaping**
- Épopées et User Stories en cours de définition
- Champs personnalisés : Priorité (P0-P3), Estimation (points), Assigné
- Labels : Front, Back, Design, Ops

#### 📋 **Betting Table**
- Pitches prêts pour validation
- Critères d'acceptation définis
- Estimation validée

#### 🔄 **Building**
- Une carte = une feature active
- Limite : 2-3 cartes par développeur
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

#### 🚫 **Cooldown**
- Bug fixes prioritaires
- Technical debt paydown
- R&D personnel
- Formation

---

## 🎯 Cartes par Phase Shape Up

### **PHASE 1 : SHAPING** (Semaine -2 à 0)

#### Cartes à créer :
- [ ] **Identifier problème utilisateur**
  - Description : Communauté roller dispersée (Facebook, WhatsApp)
  - Labels : Design, Front
  - Estimation : 2 points

- [ ] **Définir appetite (6 semaines)**
  - Description : Appetite fixe, scope flexible
  - Labels : Ops
  - Estimation : 1 point

- [ ] **Breadboarding solution**
  - Description : Wireframes grossiers (Excalidraw)
  - Labels : Design, Front
  - Estimation : 3 points

- [ ] **Identifier rabbit holes**
  - Description : Liste des No-Gos (microservices, Kubernetes, etc.)
  - Labels : Ops
  - Estimation : 2 points

- [ ] **Écrire pitch (1 page A4)**
  - Description : Problème → Solution → Appetite → No-Gos
  - Labels : Ops
  - Estimation : 3 points

### **PHASE 2 : BETTING TABLE** (Semaine 0)

#### Cartes à créer :
- [ ] **Présenter pitch (15 min)**
  - Description : Présentation + questions + validation
  - Labels : Ops
  - Estimation : 1 point

- [ ] **Décision finale**
  - Description : Vote + engagement + documentation
  - Labels : Ops
  - Estimation : 1 point

### **PHASE 3 : BUILDING** (Semaine 1-6)

#### Semaine 1-2 : Get One Piece Done
- [ ] **Setup projet Rails 8**
  - Description : `rails new grenoble-roller --database=postgresql --css=bootstrap`
  - Labels : Back, Ops
  - Estimation : 5 points

- [ ] **Authentification complète**
  - Description : Devise + rôles (Membre, Staff, Admin)
  - Labels : Back, Front
  - Estimation : 8 points

- [ ] **Premier événement CRUD**
  - Description : Créer, lire, modifier, supprimer événements
  - Labels : Back, Front
  - Estimation : 8 points

- [ ] **Inscription événement**
  - Description : Un utilisateur peut s'inscrire à un événement
  - Labels : Back, Front
  - Estimation : 5 points

- [ ] **Déploiement staging**
  - Description : Application accessible en ligne
  - Labels : Ops
  - Estimation : 3 points

#### Semaine 2-4 : Map Scopes
- [ ] **Gestion des rôles et permissions**
  - Description : Pundit pour autorisation
  - Labels : Back
  - Estimation : 5 points

- [ ] **Upload et gestion des photos**
  - Description : Photos d'événements
  - Labels : Back, Front
  - Estimation : 8 points

- [ ] **Interface admin**
  - Description : Valider les organisateurs
  - Labels : Back, Front
  - Estimation : 8 points

- [ ] **Notifications email**
  - Description : Inscription, rappel
  - Labels : Back
  - Estimation : 5 points

#### Semaine 4-6 : Downhill Execution
- [ ] **Tests complets**
  - Description : RSpec + Capybara (coverage >70%)
  - Labels : Back, Front
  - Estimation : 8 points

- [ ] **Tests de performance**
  - Description : Tests de charge basiques
  - Labels : Ops
  - Estimation : 3 points

- [ ] **Audit sécurité**
  - Description : Brakeman
  - Labels : Ops
  - Estimation : 2 points

- [ ] **Documentation**
  - Description : README complet, runbooks
  - Labels : Ops
  - Estimation : 3 points

- [ ] **Déploiement production**
  - Description : Application en ligne
  - Labels : Ops
  - Estimation : 5 points

### **PHASE 4 : COOLDOWN** (Semaine 7-8)

#### Cartes à créer :
- [ ] **Bug fixes prioritaires**
  - Description : Problèmes signalés par utilisateurs
  - Labels : Back, Front
  - Estimation : 5 points

- [ ] **Technical debt paydown**
  - Description : Refactoring, tests manquants
  - Labels : Back, Front
  - Estimation : 8 points

- [ ] **R&D personnel**
  - Description : Explorer nouvelles libs, POCs
  - Labels : Back, Front
  - Estimation : 5 points

- [ ] **Formation**
  - Description : Apprendre nouvelles technos
  - Labels : Back, Front
  - Estimation : 3 points

- [ ] **Rétrospective**
  - Description : Améliorer process Shape Up
  - Labels : Ops
  - Estimation : 2 points

---

## 🎯 Configuration Trello

### Champs Personnalisés
- **Priorité** : P0 (Critique), P1 (Haute), P2 (Moyenne), P3 (Basse)
- **Estimation** : Points (1, 2, 3, 5, 8, 13)
- **Assigné** : Nom du développeur
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

## 📊 Métriques Shape Up

### Vélocité
- **Points par semaine** : 20-30 points
- **Burndown chart** : Suivi quotidien
- **Hill Chart** : Position montée/descente

### Critères de "Done"
- [ ] Tests passent (coverage >70%)
- [ ] Code review approuvé
- [ ] Documentation mise à jour
- [ ] Déployable en production
- [ ] Performance acceptable

---

## 🚨 Règles Shape Up

### ✅ À Faire
- **Appetite fixe** : 6 semaines, scope flexible
- **Cooldown obligatoire** : 2 semaines de repos
- **Feature shippable** : Déployable en production
- **Pas de backlog** : Projet unique

### ❌ À Éviter
- **Sprints fragmentés** : Pas de 2 semaines
- **Backlog infini** : Pas de sprint planning
- **Estimation en temps** : Utiliser points
- **Sauter cooldown** : Santé équipe prioritaire

---

*Configuration Trello selon méthodologie Shape Up*  
*Version : 1.0 - Shape Up Compliant*
