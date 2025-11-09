# 🚀 GUIDE SHAPE UP - Méthodologie et Configuration Trello
## Référence complète de la méthodologie Shape Up et son implémentation avec Trello

> **📋 Pour le planning détaillé du projet** : Voir [`FIL_CONDUCTEUR_PROJET.md`](FIL_CONDUCTEUR_PROJET.md)

Ce document explique la **méthodologie Shape Up** et comment la mettre en pratique avec **Trello**.  
Pour les détails de planning, sprints et état d'avancement, consultez le fil conducteur principal.

---

## 🎯 PRINCIPE FONDAMENTAL

**Appetite fixe (3 semaines Building + 1 semaine Cooldown), scope flexible** - Si pas fini → réduire scope, pas étendre deadline.

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

#### Exemple de Structure Building (Référence)
> **📋 Pour le planning détaillé** : Voir [`FIL_CONDUCTEUR_PROJET.md`](FIL_CONDUCTEUR_PROJET.md) sections "PHASE 2 - ÉVÉNEMENTS"

**Semaine 1-2** : Get One Piece Done (CRUD Événements, Inscriptions, Calendrier)  
**Semaine 3** : Map Scopes (ActiveAdmin, Permissions, Notifications, ressources ecommerce secondaires + batch/exports)  
**Jour 15** : Downhill Execution (Tests, performance, sécurité)

**Principe** : Livrer une feature shippable à la fin des 3 semaines (15 jours exactement)

---

### **PHASE 4 : COOLDOWN** (Semaine 4)
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

## ✅ CHECKLIST SHAPING & BETTING TABLE

### ✅ PHASE 1 : SHAPING (Semaine -2 à 0)
- [ ] Problème utilisateur identifié
- [ ] Appetite défini (3 semaines Building)
- [ ] Breadboarding & Fat Marker Sketching
- [ ] Rabbit holes identifiés
- [ ] Pitch écrit (1 page A4 max)
- [ ] ER Diagram créé (Event → Route, User, Attendance)

### ✅ PHASE 2 : BETTING TABLE (Semaine 0)
- [ ] Pitch présenté (15 min)
- [ ] Questions/débat (10 min)
- [ ] Décision finale validée
- [ ] Projet validé pour cycle 3 semaines

---

## 📋 CONFIGURATION TRELLO

### Structure du Tableau

#### Colonnes Principales (Shape Up Adapté)

##### 📥 **Shaping** (2-3 jours)
- Épopées et User Stories en cours de définition
- Champs personnalisés : Priorité (P0-P3), Estimation (points), Assigné
- Labels : Front, Back, Design, Ops

##### 📋 **Betting Table** (1 jour)
- Pitches prêts pour validation
- Critères d'acceptation définis
- Estimation validée

##### 🔄 **Building** (3 semaines)
- Une carte = une feature active
- Limite : 1-2 cartes par développeur (4 personnes = 4-8 cartes max)
- Mise à jour quotidienne

##### 👀 **En Revue/QA**
- Tests unitaires et d'intégration
- Revue de code croisée
- Tests de régression

##### ✅ **Shippable**
- Feature complète déployable en production
- Tests de performance OK
- Documentation mise à jour

##### 🏁 **Terminé**
- Historique des livrables
- Métriques de vélocité

##### 🚫 **Cooldown** (1 semaine)
- Bug fixes prioritaires
- Technical debt paydown
- R&D personnel
- Formation

---

### Configuration Trello (4 personnes)

#### Rôles Équipe
- **Tech Lead** : Architecture, DevOps, coordination
- **Backend Dev** : Rails, API, base de données
- **Frontend Dev** : Bootstrap, JavaScript, UX
- **Fullstack Dev** : Polyvalent, support équipe

#### Champs Personnalisés
- **Priorité** : P0 (Critique), P1 (Haute), P2 (Moyenne), P3 (Basse)
- **Estimation** : Points (1, 2, 3, 5, 8)
- **Assigné** : Tech Lead, Backend Dev, Frontend Dev, Fullstack Dev
- **Phase** : Shaping, Betting, Building, Cooldown

#### Labels
- **Front** : Interface utilisateur
- **Back** : Backend, API
- **Design** : UX/UI, wireframes
- **Ops** : DevOps, déploiement
- **Test** : Tests, QA
- **Doc** : Documentation

#### Power-Ups Recommandés
- **Calendar** : Voir les deadlines
- **Custom Fields** : Priorité, estimation
- **Butler** : Automatisation basique

---

### Exemples de Cartes par Phase

> **📋 Pour les cartes détaillées et l'état d'avancement** : Voir [`FIL_CONDUCTEUR_PROJET.md`](FIL_CONDUCTEUR_PROJET.md)

#### **PHASE 1 : SHAPING** (2-3 jours)
Exemples de cartes :
- Identifier problème utilisateur
- Définir appetite
- Breadboarding solution
- Identifier rabbit holes
- Écrire pitch

#### **PHASE 2 : BETTING TABLE** (1 jour)
Exemples de cartes :
- Présenter pitch
- Décision finale

#### **PHASE 3 : BUILDING** (3 semaines)
> **📋 Pour le détail des cartes et l'état** : Voir [`FIL_CONDUCTEUR_PROJET.md`](FIL_CONDUCTEUR_PROJET.md) sections "PHASE 2 - ÉVÉNEMENTS"

#### **PHASE 4 : COOLDOWN** (1 semaine)
Exemples de cartes :
- Bug fixes prioritaires
- Technical debt paydown
- R&D personnel
- Formation
- Rétrospective

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

### Exemple d'Utilisation
> **📋 Pour l'état d'avancement actuel** : Voir [`FIL_CONDUCTEUR_PROJET.md`](FIL_CONDUCTEUR_PROJET.md) section "SUIVI D'AVANCEMENT"

**Principe** : Suivre la position sur la montée/descente pour chaque scope
- **Uphill** = Découverte, incertitude (OK en début)
- **Downhill** = Exécution, certitude (objectif fin de cycle)

**⚠️ Alarme** : Si encore "uphill" en fin de cycle → revoir scope

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

### Critères Généraux de "Done"
> **📋 Pour les critères spécifiques au projet** : Voir [`FIL_CONDUCTEUR_PROJET.md`](FIL_CONDUCTEUR_PROJET.md)

Une feature est "Done" quand :
- ✅ Tests passent (coverage >70%)
- ✅ Code review approuvé
- ✅ Documentation mise à jour
- ✅ Déployable en production
- ✅ Performance acceptable

### Cooldown Réussi
- [ ] Bugs critiques corrigés
- [ ] Technical debt remboursée
- [ ] Équipe reposée et motivée
- [ ] Learnings documentés
- [ ] Prochain cycle planifié

---

## 📊 MÉTRIQUES SHAPE UP

### Vélocité
- **Points par semaine** : 15-20 points par personne (60-80 points total)
- **Burndown chart** : Suivi quotidien
- **Hill Chart** : Position montée/descente

### Exemple de Répartition
> **📋 Pour l'état d'avancement actuel** : Voir [`FIL_CONDUCTEUR_PROJET.md`](FIL_CONDUCTEUR_PROJET.md) section "SUIVI D'AVANCEMENT"

**Principe** : Suivre les points par semaine et ajuster le scope si nécessaire

---

## 🚨 RÈGLES SHAPE UP

### ✅ À Faire
- **Appetite fixe** : 3 semaines Building, scope flexible
- **Cooldown obligatoire** : 1 semaine de repos
- **Feature shippable** : Déployable en production
- **Pas de backlog** : Projet unique
- **Limite cartes** : 1-2 cartes par personne max
- **Timeline stricte** : 15 jours exactement (Jour 1-15)

### ❌ À Éviter
- **Sprints fragmentés** : Pas de 1 semaine
- **Backlog infini** : Pas de sprint planning
- **Estimation en temps** : Utiliser points
- **Sauter cooldown** : Santé équipe prioritaire
- **Over-engineering** : MVP simple d'abord

---

## 📚 RESSOURCES

### Livre Officiel (Gratuit)
- [Shape Up](https://basecamp.com/shapeup) - Ryan Singer, Basecamp

### Outils Recommandés
- **Excalidraw** : Wireframes rapides
- **Trello** : Tracking scopes (configuration ci-dessus)
- **Hill Chart** : Plugin custom ou spreadsheet
- **Loom** : Vidéos async pour progrès

---

## 💡 RÈGLES D'OR

1. **YAGNI** : You Ain't Gonna Need It
2. **KISS** : Keep It Simple, Stupid
3. **Appetite fixe** : 3 semaines Building, scope flexible
4. **Cooldown obligatoire** : 1 semaine de repos
5. **Feature shippable** : Déployable en production
6. **Pas de backlog** : Projet unique, pas de sprint planning
7. **Timeline stricte** : 15 jours exactement (Jour 1-15)

---

*Guide créé selon la méthodologie Shape Up adaptée*  
*Version : 2.0 - Shape Up Compliant avec Configuration Trello*  
*Équipe : 2 développeurs*
