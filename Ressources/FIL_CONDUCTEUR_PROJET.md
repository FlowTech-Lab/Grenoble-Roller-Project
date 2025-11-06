# 🎯 FIL CONDUCTEUR - Projet Site Web Grenoble Roller
## Rails 8 + Bootstrap - Plan de développement structuré

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
- [ ] User Stories détaillées avec critères d'acceptation
- [ ] Diagrammes d'architecture technique
- [ ] Personas et parcours utilisateurs
- [ ] Plan d'infrastructure (serveur, DB, CI/CD)
- [ ] Conventions de développement

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
- [ ] Wireframes desktop et mobile
- [ ] Prototype interactif (Figma)
- [ ] Design system Bootstrap
- [ ] Validation UX/UI

#### 🛠️ **Actions**
1. **Wireframes** (3 jours)
   - Pages principales
   - Responsive design
   - Navigation

2. **Prototype interactif** (4 jours)
   - Interactions utilisateur
   - Flux de navigation
   - Validation

3. **Design system** (2 jours)
   - Composants Bootstrap
   - Thème personnalisé
   - Guidelines

---

### **PHASE 3 - ENVIRONNEMENT & CI/CD** (intégré Semaine 1)

#### 🎯 **Objectifs**
- Mettre en place l'environnement de développement
- Configurer CI/CD
- Implémenter le monitoring

#### 📋 **Livrables**
- [ ] Repository GitHub structuré
- [ ] Pipeline CI (tests, linting, audit)
- [ ] Pipeline CD (staging/prod)
- [ ] Monitoring initial

#### 🛠️ **Actions**
1. **Repository GitHub** (1 jour)
   - Structure de branches (main/develop/feature/hotfix)
   - .gitignore et conventions
   - Documentation README

2. **Pipeline CI** (2 jours)
   - Tests RSpec automatisés
   - Linting RuboCop
   - Audit de sécurité
   - Tests de performance

3. **Pipeline CD** (2 jours)
   - Déploiement staging automatique
   - Déploiement prod manuel
   - Rollback automatique

4. **Monitoring** (1 jour)
   - Prometheus + Grafana
   - Alertes critiques
   - Métriques de performance

---

### **PHASE 4 - DÉVELOPPEMENT ITÉRATIF** (Cycle unique de 3 semaines)

#### 🎯 **Objectifs**
- Développement TDD avec revues de code
- Tests automatisés et performance
- Déploiement continu

#### 📋 **Sprint 1-2 : Authentification & Base**
- [ ] Système d'authentification (Devise)
- [ ] Gestion des rôles (Pundit)
- [ ] Dashboard de base
- [ ] Présentation association
- [ ] Prestations de base

#### 📋 **Sprint 3-4 : Événements & Paiement**
- [ ] CRUD événements complet
- [ ] Calendrier interactif (FullCalendar)
- [ ] Intégration HelloAsso
- [ ] Système de paiement
- [ ] Gestion des inscriptions

#### 📋 **Sprint 5 : Initiation & Admin**
- [ ] Module initiation
- [ ] Gestion des créneaux
- [ ] Système de prêt matériel
- [ ] Panel admin (statistiques)
- [ ] Gestion des membres

#### 📋 **Sprint 6 : Réseaux Sociaux & Finalisation**
- [ ] API Twitter/X et Facebook
- [ ] Posts automatiques (cron)
- [ ] Ajustements UI/UX
- [ ] Accessibilité WCAG 2.2
- [ ] Tests de régression

#### 🛠️ **Actions par Sprint**
1. **Planification** (1h)
   - Sélection des User Stories
   - Estimation des tâches
   - Répartition des rôles

2. **Développement** (4 jours)
   - TDD avec RSpec
   - Revues de code croisées
   - Tests d'intégration

3. **Déploiement** (1 jour)
   - Tests en staging
   - Démonstration
   - Feedback et ajustements

---

### **PHASE 5 - TESTS & OPTIMISATION** (Semaine 3)

#### 🎯 **Objectifs**
- Tests de montée en charge
- Optimisation des performances
- Mise en cache

#### 📋 **Livrables**
- [ ] Tests de charge (JMeter/k6)
- [ ] Optimisation des requêtes
- [ ] Mise en cache Redis
- [ ] CDN et compression

#### 🛠️ **Actions**
1. **Tests de charge** (3 jours)
   - Scénarios 10→1000 utilisateurs
   - Identification des goulots
   - Optimisation des requêtes

2. **Mise en cache** (2 jours)
   - Cache fragment Rails
   - Redis pour sessions
   - CDN pour assets

3. **Optimisation** (2 jours)
   - Compression Brotli
   - Minification assets
   - Optimisation images

---

### **PHASE 6 - DÉPLOIEMENT PRODUCTION** (fin Semaine 3 ou début Cooldown)

#### 🎯 **Objectifs**
- Déploiement en production
- Formation des administrateurs
- Documentation opérationnelle

#### 📋 **Livrables**
- [ ] Déploiement production
- [ ] SSL automatisé (Let's Encrypt)
- [ ] Documentation runbook
- [ ] Formation administrateurs

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

### **✅ Bonnes Pratiques**
1. **Architecture claire** → Diagrammes et documentation
2. **Tests complets** → Unitaires, intégration, e2e
3. **CI/CD robuste** → Déploiement automatisé
4. **Performance** → Tests de charge réguliers
5. **Sécurité** → Audit et mise à jour
6. **Monitoring** → Métriques et alertes
7. **Documentation** → Toujours à jour

---

## 📅 TIMELINE 3 SEMAINES

| Semaine | Phase | Objectifs | Livrables |
|---------|-------|-----------|-----------|
| 1 | Building (S1) | Setup Rails 8, Auth (Devise), Rôles (Pundit), 1er CRUD Événements | Auth complète, CRUD Événements fonctionnel, base UI |
| 2 | Building (S2) | Permissions fines, Upload photos (Active Storage), Interface admin, Notifications email | Rôles/permissions, gestion médias, admin minimal, mails |
| 3 | Building (S3) | Tests (>70%), Performance, Sécurité (Brakeman), Doc, Déploiement | Coverage OK, audit sécurité, README/runbooks, staging+prod |

---

## 🎯 CONCLUSION

Ce fil conducteur garantit une livraison progressive, un maximum de visibilité et un contrôle qualité continu. L'utilisation de Trello optimise la collaboration à deux, tandis que Rails 8, Bootstrap et les pipelines automatisés assurent rapidité, sécurité et maintenabilité.

**Prochaines étapes** :
1. ✅ Validation du fil conducteur
2. 🔄 Création du tableau Trello
3. 🚀 Lancement de la Phase 1

---

## ✅/🔜 SUIVI D'AVANCEMENT (Semaine 1)

- [✅] Base Users (Devise) + détails (`first_name`, `last_name`, etc.)
- [✅] Table `roles` conforme (ajout `code` unique + `level`) et FK `users.role_id`
- [✅] Seeds rôles (USER→SUPERADMIN) et Florian en SUPERADMIN
- [✅] Boutique: `product_categories`, `products`, `product_variants`, `option_types`, `option_values`, `variant_option_values`
- [✅] Paiements (`payments`) et commandes (`orders`, `order_items`)
- [✅] FK `order_items.variant_id → product_variants.id` + seeds corrigés
- [🔜] Auth complète (Devise: vues + flows)
- [🔜] Permissions (Pundit: politiques + intégration)
- [🔜] Événements: `routes`, `events`, `attendances`, `organizer_applications`
- [🔜] Interface admin minimale
- [🔜] Upload photos (Active Storage)

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

3. **Exemple structure** :
   ```
   Product: "Veste Grenoble Roller"
   ├─ Variant 1 (Noir, S) → image: "veste_noir.avif"
   ├─ Variant 2 (Noir, M) → image: "veste_noir.avif"
   ├─ Variant 3 (Bleu, S) → image: "veste_bleu.avif"
   └─ Variant 4 (Blanc, L) → image: "veste.png"
   ```

4. **Avantages** :
   - Un seul produit à gérer au lieu de N produits (N = nombre de couleurs)
   - Image change automatiquement selon la sélection
   - Meilleure organisation des stocks et prix
   - URL produit unique (SEO amélioré)

**Priorité** : Moyenne (amélioration structurelle importante, mais fonctionnel actuellement)

---

*Document créé le : $(date)*  
*Version : 1.0*  
*Équipe : 2 développeurs*
