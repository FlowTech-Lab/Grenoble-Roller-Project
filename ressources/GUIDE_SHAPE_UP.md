# 🚀 GUIDE SHAPE UP - Grenoble Roller
## Rails 8 + Bootstrap - Méthodologie Shape Up Adaptée

---

## 🎯 PRINCIPE FONDAMENTAL

**Appetite fixe (6 semaines), scope flexible** - Si pas fini → réduire scope, pas étendre deadline.

---

## 🔄 LES 4 PHASES SHAPE UP

### **PHASE 1 : SHAPING** (Semaine -2 à 0)
**Objectif : Définir les limites avant de s'engager**

#### Actions
1. **Identifier le problème utilisateur**
   - Problème : Communauté roller dispersée (Facebook, WhatsApp éparpillés)
   - Pourquoi maintenant : 20+ ans de communauté, besoin de centralisation
   - Pour qui : Membres Grenoble Roller (200+ personnes estimées)

2. **Définir l'appetite (FIXE)**
   - Appetite choisi : 6 semaines (cycle Shape Up standard)
   - Scope flexible : Si pas fini → réduire scope, pas étendre deadline
   - Documenter : "On a 6 semaines pour livrer MVP fonctionnel"

3. **Breadboarding & Fat Marker Sketching**
   - Wireframes grossiers : Pages principales (accueil, événements, profil)
   - Outils : Excalidraw ou papier-crayon
   - Focus : Flux utilisateur, pas esthétique

4. **Identifier les rabbit holes**
   - Rabbit hole #1 : "Internationalisation complète" → MVP français uniquement
   - Rabbit hole #2 : "Microservices" → Monolithe Rails d'abord
   - Rabbit hole #3 : "API publique complète" → API interne uniquement
   - Rabbit hole #4 : "Système de paiement complexe" → HelloAsso simple

5. **Écrire le pitch** (1 page A4 max)
   - **Problème** : Communauté dispersée, événements difficiles à découvrir
   - **Solution proposée** : Plateforme centralisée avec rôles
   - **Rabbit holes évités** : Pas de microservices, pas d'internationalisation
   - **Appetite** : 6 semaines
   - **No-Gos** : Pas de mobile app, pas d'API publique, pas de chat

#### Output
→ **Pitch validé** pour betting table

---

### **PHASE 2 : BETTING TABLE** (Semaine 0)
**Objectif : Priorisation brutale et engagement**

#### Actions
1. **Présenter le pitch** (15 min)
   - Problème → Solution → Appetite → No-Gos
   - Questions/débat : 10 min
   - Validation : Tous les stakeholders alignés

2. **Décision finale**
   - Vote : Projet validé pour cycle 6 semaines
   - Engagement : Deadline fixe, scope flexible
   - Documenter : Décision écrite et partagée

#### Output
→ **Projet validé** pour cycle 6 semaines

---

### **PHASE 3 : BUILDING** (Semaine 1-6)
**Objectif : Livrer une feature shippable**

#### ✅ Semaine 1-2 : Get One Piece Done (TERMINÉ - Phase 1 E-commerce)
- [X] **Setup projet Rails 8** : `rails new grenoble-roller --database=postgresql --css=bootstrap`
  - ✅ Rails 8.0.4 configuré avec Docker (dev/staging/prod)
  - ✅ PostgreSQL 16, Bootstrap 5, Stimulus, Turbo
- [X] **Authentification de base** : Devise + rôles (7 niveaux: USER à SUPERADMIN)
  - ✅ Devise configuré et fonctionnel
  - ✅ Système de rôles avec 7 niveaux
  - ✅ Seeds avec utilisateurs de test
- [X] **E-commerce complet** : Boutique fonctionnelle
  - ✅ Catalogue produits avec variantes et options
  - ✅ Panier session (add/update/remove/clear)
  - ✅ Checkout et création de commandes
  - ✅ Historique des commandes
  - ✅ Guardrails stock et validations
- [X] **Documentation** : README complet, runbooks, setup guides
  - ✅ Documentation mise à jour (Nov 2025)
  - ✅ Guides de setup Docker
  - ✅ Documentation architecture et modèles

#### 🔜 Semaine 2-4 : Map Scopes (Phase 2 - Événements)
- [ ] **Scope 1** : CRUD événements complet
  - Créer, lire, modifier, supprimer événements
  - Calendrier interactif
  - Gestion des parcours
- [ ] **Scope 2** : Inscription aux événements
  - Un utilisateur peut s'inscrire à un événement
  - Gestion des places (si nécessaire)
- [ ] **Scope 3** : Gestion des rôles et permissions (Pundit)
  - Permissions fines pour organisateurs
  - Validation des organisateurs
- [ ] **Scope 4** : Upload et gestion des photos d'événements
  - Active Storage pour photos
  - Affichage dans les événements
- [ ] **Scope 5** : Interface admin pour valider les organisateurs
  - Panel admin minimal
  - Validation des organisateurs
- [ ] **Scope 6** : Notifications par email (inscription, rappel)
  - Emails d'inscription événement
  - Rappels événements
- [ ] **Ajustements** : Réduire scope si nécessaire (pas deadline)

#### 🔜 Semaine 4-6 : Downhill Execution (Phase 2)
- [ ] **Hill Chart tracking** : Position sur la montée/descente
- [ ] **Tests complets** : RSpec + Capybara (coverage >70%)
- [ ] **Performance** : Tests de charge basiques
- [ ] **Sécurité** : Audit Brakeman complet
- [ ] **Documentation** : Mise à jour avec module événements

#### 🔜 Semaine 6 : Shipping (Phase 2)
- [ ] **Déploiement production** : Application en ligne avec événements
- [ ] **Formation utilisateurs** : 2-3 membres testent
- [ ] **Feedback** : Collecter retours utilisateurs
- [ ] **Documentation** : Guide utilisateur complet

#### Output Phase 1
→ **E-commerce shippable** : Boutique fonctionnelle complète

#### Output Phase 2 (À venir)
→ **MVP complet shippable** : E-commerce + Événements en production

---

### **PHASE 4 : COOLDOWN** (Semaine 7-8)
**Objectif : Repos, amélioration, innovation**

#### Actions (Non Négociables)
1. **Bug fixes prioritaires**
   - Corriger problèmes signalés par utilisateurs
   - Tests manquants pour code critique
   - Documentation complète

2. **Technical debt paydown**
   - Refactoring code douteux identifié
   - Mise à jour dépendances obsolètes
   - Optimisations basiques identifiées

3. **R&D personnel**
   - Explorer nouvelles libs Rails 8
   - POCs techniques pour futures features
   - Formation : Apprendre nouvelles technos

4. **Rétrospective**
   - Process : Qu'améliorer dans Shape Up ?
   - Technique : Quels outils/processus améliorer ?
   - Équipe : Communication, collaboration
   - Documenter : Learnings pour prochain cycle

#### Règles
- ❌ **AUCUNE nouvelle feature** pendant cooldown
- ❌ **PAS de pression delivery**
- ✅ Temps pour créativité & innovation
- ✅ Santé mentale de l'équipe = priorité

#### Output
→ **Équipe reposée + learnings documentés**

---

## 🛠️ STACK TECHNIQUE SIMPLIFIÉ

### **Backend (Monolithe Rails)**
- **Rails 8** (dernière version)
- **Ruby 3.3+**
- **PostgreSQL** (base de données)
- **Redis** (cache et sessions)
- **Sidekiq** (background jobs)

### **Frontend (Bootstrap Simple)**
- **Bootstrap 5.5** (UI framework)
- **Stimulus** (JavaScript framework)
- **Turbo** (navigation SPA)

### **DevOps (Docker Simple)**
- **Docker Compose** (containerisation)
- **GitHub Actions** (CI/CD)
- **Let's Encrypt** (SSL)

### **Intégrations (Minimales)**
- **HelloAsso API** (paiements simples)
- **OpenStreetMap** (cartes basiques)

---

## 📊 HILL CHART TRACKING

### Position sur la Montée/Descente
```
Uphill (Montée) = Découverte, incertitude
Downhill (Descente) = Exécution, certitude
```

### Phase 1 - E-commerce (✅ TERMINÉ)
**Semaine 1-2** : ✅ Downhill (exécution, finition e-commerce)
- Setup Rails 8 : Terminé
- E-commerce : Terminé et fonctionnel
- Documentation : Terminé

### Phase 2 - Événements (🔜 À VENIR)
**Semaine 1-2** : Uphill (découverte module événements, CRUD)
**Semaine 3-4** : Transition (découverte complexité réelle)
**Semaine 5-6** : Downhill (exécution, finition)

**⚠️ Alarme** : Si encore "uphill" en S5 → revoir scope

---

## 🚨 RABBIT HOLES ÉVITÉS

### ❌ Ce qu'on ne fera PAS (No-Gos)
- **Microservices** → Monolithe Rails d'abord
- **Kubernetes** → Docker Compose simple
- **Internationalisation** → MVP français uniquement
- **API publique** → API interne uniquement
- **Mobile app** → Web responsive uniquement
- **Chat en temps réel** → Notifications email
- **Système de paiement complexe** → HelloAsso simple
- **Analytics avancées** → Google Analytics basique

### ✅ Ce qu'on fera (In-Scope)
- **Authentification** : Devise + rôles
- **CRUD événements** : Créer, lire, modifier, supprimer
- **Inscriptions** : S'inscrire aux événements
- **Photos** : Upload et affichage
- **Notifications** : Email basique
- **Admin** : Interface de gestion
- **Responsive** : Mobile-friendly

---

## 🎯 CRITÈRES DE "DONE"

### Phase 1 - E-commerce Shippable (✅ TERMINÉ)
- [X] Application fonctionnelle en développement
- [X] E-commerce complet (catalogue, panier, checkout, commandes)
- [X] Authentification et rôles fonctionnels
- [X] Documentation complète (README, setup, architecture)
- [X] Docker configuré (dev/staging/prod)
- [ ] Tests >70% coverage (à planifier)
- [ ] Performance acceptable (<2s chargement) (à tester)
- [ ] Déploiement production (à finaliser)

### Phase 2 - MVP Complet Shippable (🔜 À VENIR)
- [ ] Application déployée en production
- [ ] 2-3 utilisateurs peuvent tester
- [ ] Flux principal fonctionne (inscription → événement → participation)
- [ ] Tests >70% coverage
- [ ] Documentation utilisateur basique
- [ ] Performance acceptable (<2s chargement)

### Cooldown Réussi
- [ ] Bugs critiques corrigés
- [ ] Technical debt remboursée
- [ ] Équipe reposée et motivée
- [ ] Learnings documentés
- [ ] Prochain cycle planifié

---

## 📚 RESSOURCES

### Livre Officiel (Gratuit)
- [Shape Up](https://basecamp.com/shapeup) - Ryan Singer, Basecamp

### Outils Recommandés
- **Excalidraw** : Wireframes rapides
- **Linear** : Tracking scopes (pas user stories)
- **Hill Chart** : Plugin custom ou spreadsheet
- **Loom** : Vidéos async pour progrès

---

## 💡 RÈGLES D'OR

1. **YAGNI** : You Ain't Gonna Need It
2. **KISS** : Keep It Simple, Stupid
3. **Appetite fixe** : 6 semaines, scope flexible
4. **Cooldown obligatoire** : 2 semaines de repos
5. **Feature shippable** : Déployable en production
6. **Pas de backlog** : Projet unique, pas de sprint planning

---

*Guide créé selon la méthodologie Shape Up adaptée*  
*Version : 1.0 - Shape Up Compliant*  
*Équipe : 2 développeurs*
