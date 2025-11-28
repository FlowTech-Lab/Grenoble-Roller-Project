# Adhésions HelloAsso - Contexte (ARCHIVÉ)

**Date** : 2025-01-27  
**Version** : 2.1  
**Status** : ⚠️ ARCHIVÉ - Voir documents consolidés

---

## ⚠️ ATTENTION

**Ce document est archivé et remplacé par** :
- **`adhesions-strategie-complete.md`** : Stratégie complète consolidée
- **`adhesions-plan-implementation.md`** : Plan d'implémentation détaillé avec checklist

**Veuillez consulter ces nouveaux documents pour l'implémentation.**

---

## 📋 Vue d'ensemble (Ancien contenu)

Ce document rassemble toutes les informations nécessaires pour comprendre le contexte actuel de l'application, la communication avec HelloAsso (pour les commandes), et la **stratégie validée** pour implémenter la gestion des adhésions via HelloAsso.

**🎯 Approche retenue** : **SIMPLE & PRAGMATIQUE**
- HelloAsso gère **SEULEMENT le paiement** (checkout-intents, comme pour les commandes)
- L'application gère **TOUT le reste** (dates fixes, statuts, renouvellement, informations adhérents)
- Pas de synchronisation complexe, pas de formSlug, pas de custom fields HelloAsso
- **100x mieux pour une asso** : Simple, maîtrisé, 1 seul système

---

## 🎯 STRATÉGIE VALIDÉE - Résumé en 1 Phrase

> **HelloAsso = Juste le paiement. Ton app = Tout le reste (dates fixes, statuts, renouvellement). Simple et maintenable. ✅**

---

## 🏗️ CONTEXTE ACTUEL DE L'APPLICATION

### **1. Modèle User (Utilisateur)**

**Caractéristiques** :
- Authentification via Devise (email/password)
- Confirmation d'email requise (mais période de grâce activée)
- Système de rôles (7 niveaux) : USER, REGISTERED, INITIATION, ORGANIZER, MODERATOR, ADMIN, SUPERADMIN
- Champs obligatoires : `first_name`, `skill_level` (beginner/intermediate/advanced)
- Champs optionnels : `last_name`, `phone`

**Relations actuelles** :
- `belongs_to :role`
- `has_many :orders`
- `has_many :events` (via attendances)
- **PAS de relation `has_many :memberships` actuellement** (à créer)

**État actuel** :
- ✅ Utilisateurs peuvent s'inscrire
- ✅ Profils utilisateurs fonctionnels
- ❌ **PAS de gestion d'adhésions implémentée**

**Modifications nécessaires** :
- Ajouter relation `has_many :memberships`
- Ajouter helpers pour vérifier adhésion active
- Ajouter champs si manquants : `date_of_birth`, `address`, `postal_code`, `city`

---

### **2. Modèle Membership (Adhésion) - Structure validée**

**✅ STRATÉGIE VALIDÉE** : Structure simplifiée et pragmatique

**Catégories simplifiées** (3 types) :
- `adult` : Adulte : 50€
- `student` : Étudiant : 25€
- `family` : Famille : 80€

**Statuts simplifiés** (3 valeurs seulement) :
- `pending` : En attente de paiement
- `active` : Active (payée et dans la période de validité)
- `expired` : Expirée (end_date dépassée)

**Champs nécessaires** (validés) :
- `user_id` (référence, obligatoire)
- `category` (enum: adult, student, family)
- `status` (enum: pending, active, expired)
- `start_date` (date, obligatoire - calculée automatiquement)
- `end_date` (date, obligatoire - calculée automatiquement)
- `amount_cents` (integer, obligatoire - calculé selon catégorie)
- `currency` (string, default: "EUR")
- `payment_id` (référence vers Payment, optionnel)
- `provider_order_id` (string - ID de l'order HelloAsso pour réconciliation)
- `created_at`, `updated_at`

**Champs optionnels (pour plus tard)** :
- `metadata` (jsonb) : Pour stocker des infos supplémentaires (date naissance, certificat médical, etc.)

**Méthodes nécessaires** :
- `price_for_category(category)` : Calcul automatique du prix selon la catégorie
- `current_season_dates` : Calcul automatique des dates de saison (1er sept - 31 août)
- `active?` : Vérifier si l'adhésion est active (payée ET dans la période de validité)
- `expired?` : Vérifier si l'adhésion est expirée

**État actuel** :
- ❌ **Modèle Membership n'existe pas encore en base**
- ❌ **Migration non créée**
- ❌ **Controller non créé**
- ❌ **Vues non créées**

---

### **3. Types d'adhésions et tarifs**

**✅ STRATÉGIE VALIDÉE** : Approche simple avec 3 catégories et dates fixes

#### **Catégories d'adhésion**

| Catégorie | Code | Prix | Description |
|-----------|------|------|-------------|
| **Adulte** | `adult` | 50,00€ | Adhésion standard pour adulte |
| **Étudiant** | `student` | 25,00€ | Adhésion avec réduction étudiant |
| **Famille** | `family` | 80,00€ | Adhésion pour famille (1 responsable + membres) |

**Note** : Les types `ffrs` et `ffrs_insurance` peuvent être ajoutés plus tard si nécessaire, mais pour commencer, on se concentre sur ces 3 catégories simples.

#### **Périodes d'adhésion fixes (saisons)**

**✅ APPROCHE VALIDÉE** : Dates fixes par saison (pas de dates variables)

- **Saison 2025-2026** : du 1er septembre 2025 au 31 août 2026
- **Saison 2026-2027** : du 1er septembre 2026 au 31 août 2027
- **Saison 2027-2028** : du 1er septembre 2027 au 31 août 2028
- etc.

**Avantages** :
- ✅ Calcul simple et prévisible
- ✅ Pas de gestion de dates variables
- ✅ Cohérence pour tous les adhérents
- ✅ Facile à gérer en base de données

**Calcul automatique** :
- `start_date` = 1er septembre de l'année courante (ou suivante si on est après le 1er septembre)
- `end_date` = 31 août de l'année suivante

**Exemple** :
- Si on est le 15 janvier 2025 → Saison 2024-2025 (1er sept 2024 - 31 août 2025)
- Si on est le 15 octobre 2025 → Saison 2025-2026 (1er sept 2025 - 31 août 2026)

---

### **4. Système de rôles et adhésions**

**Rôles actuels** :
- `USER` : Utilisateur non adhérent
- `REGISTERED` : Utilisateur enregistré (adhérent ?)
- `INITIATION` : Utilisateur en initiation
- `ORGANIZER` : Organisateur d'événements
- `MODERATOR` : Modérateur
- `ADMIN` : Administrateur
- `SUPERADMIN` : Super administrateur

**Relation avec les adhésions** :
- ✅ **Recommandation** : Mettre à jour automatiquement le rôle lors de l'achat d'une adhésion
- ✅ **Recommandation** : Vérifier la validité de l'adhésion pour accéder à certaines fonctionnalités
- ❓ Le rôle `REGISTERED` correspond-il à un adhérent actif ? (À clarifier avec le client)

**Logique proposée** :
- Lors de l'activation d'une adhésion (`status = "active"`) → `user.role = Role.find_by(code: "REGISTERED")`
- Lors de l'expiration d'une adhésion (`status = "expired"`) → `user.role = Role.find_by(code: "USER")`

---

## 🔌 COMMUNICATION ACTUELLE AVEC HELLOASSO

### **1. Service HelloassoService**

**Fonctionnalités actuelles** :

#### **A. Authentification OAuth2**
- ✅ `fetch_access_token!` : Récupère un token d'accès via `client_credentials`
- ✅ Gestion sandbox/production automatique
- ✅ Retry automatique en cas d'expiration (401)
- ✅ Cache du token (évite les appels répétés)

**Endpoints utilisés** :
- Sandbox : `https://api.helloasso-sandbox.com/oauth2/token`
- Production : `https://api.helloasso.com/oauth2/token`

**Credentials stockés** :
- `client_id`, `client_secret`, `organization_slug`, `environment` (sandbox/production)

---

#### **B. Checkout Intents (Commandes boutique)**
- ✅ `create_checkout_intent` : Crée un checkout-intent pour une commande
- ✅ `build_checkout_intent_payload` : Construit le payload JSON
- ✅ `fetch_checkout_intent` : Récupère l'état d'un checkout-intent
- ✅ `checkout_redirect_url` : Helper pour obtenir directement l'URL de redirection

**Endpoint utilisé** :
- `POST /v5/organizations/{organizationSlug}/checkout-intents`

**Payload actuel (pour commandes)** :
- `totalAmount`, `initialAmount`, `itemName`
- `backUrl`, `errorUrl`, `returnUrl`
- `containsDonation` (boolean)
- `metadata` (objet JSON avec `localOrderId`, `environment`, `donationCents`, `items`)

**Réponse** :
- `id` : ID du checkout-intent
- `redirectUrl` : URL de redirection vers HelloAsso

**✅ Pour les adhésions** : On utilisera **EXACTEMENT le même endpoint et la même structure**, mais avec :
- `itemName` = "Adhésion Adulte Saison 2025-2026" (ou Étudiant, Famille)
- `totalAmount` = 5000 (ou 2500, 8000 selon catégorie)
- `metadata.membership_id` = ID de l'adhésion locale
- **PAS de formSlug, PAS de custom fields**

---

#### **C. Vérification des paiements (Polling)**
- ✅ `fetch_helloasso_order` : Récupère l'état d'une commande HelloAsso
- ✅ `fetch_and_update_payment` : Met à jour le statut local basé sur HelloAsso

**Endpoints utilisés** :
- `GET /v5/organizations/{slug}/checkout-intents/{checkoutIntentId}`
- `GET /v5/organizations/{slug}/orders/{orderId}`

**Logique de mise à jour** :
- `order.state == "Confirmed"` → `Payment.status = "succeeded"`, `Order.status = "paid"`
- `order.state == "Refused"` → `Payment.status = "failed"`, `Order.status = "failed"`
- Pas d'`order` après 45 min → `Payment.status = "abandoned"`

**✅ Pour les adhésions** : On utilisera **EXACTEMENT la même logique** :
- `order.state == "Confirmed"` → `Payment.status = "succeeded"`, `Membership.status = "active"`
- `order.state == "Refused"` → `Payment.status = "failed"`, `Membership.status = "expired"`

---

### **2. Modèle Payment**

**Structure actuelle** :
- `has_many :orders`
- `enum status` : pending, paid, failed, cancelled, expired, succeeded, abandoned, refunded
- `enum provider` : helloasso

**Champs** :
- `provider` : "helloasso"
- `provider_payment_id` : ID du checkout-intent ou de l'order HelloAsso
- `amount_cents` : Montant en centimes
- `currency` : "EUR"
- `status` : Statut du paiement

**✅ Relation avec les adhésions** :
- On utilisera le **même modèle `Payment`** pour commandes ET adhésions
- `Payment` aura une relation `has_one :membership` (optionnelle)
- Un `Payment` peut être lié soit à un `Order`, soit à un `Membership`

---

### **3. Flux actuel : Commande Boutique → HelloAsso**

**Voir** : `docs/09-product/flux-boutique-helloasso.md` pour le détail complet

**Résumé** :
1. Utilisateur valide son panier → `POST /orders`
2. Création de la commande locale (`Order` + `OrderItem`)
3. Appel `HelloassoService.create_checkout_intent`
4. Création du `Payment` local
5. Redirection vers HelloAsso
6. Retour sur notre site → Polling pour vérifier le statut
7. Mise à jour automatique via cron job (toutes les 5 minutes)

**Points clés** :
- ✅ Commande créée **AVANT** le paiement (statut "pending")
- ✅ Stock déduit immédiatement
- ✅ Payment créé avec `provider_payment_id` = ID du checkout-intent
- ✅ Polling JavaScript (5 secondes) + Cron job (5 minutes)

**✅ Pour les adhésions** : On utilisera **EXACTEMENT le même flux**, mais :
- Création de `Membership` au lieu de `Order`
- Pas de déduction de stock
- Même système de polling et cron job

---

## 🎯 STRATÉGIE VALIDÉE - Détail Complet

### **1. Configuration Initiale (Une fois)**

**Dans l'application Rails** :

1. **Définir les périodes d'adhésion fixes** :
   - Saison 2025-2026 : du 1er septembre 2025 au 31 août 2026
   - Saison 2026-2027 : du 1er septembre 2026 au 31 août 2027
   - etc.
   - Calcul automatique via méthode `current_season_dates`

2. **Définir les 3 tarifs (toujours les mêmes)** :
   - Adulte : 50€ (5000 centimes)
   - Étudiant : 25€ (2500 centimes)
   - Famille : 80€ (8000 centimes)
   - Calcul automatique via méthode `price_for_category(category)`

3. **HelloAsso** :
   - **RIEN à configurer côté adhésion**
   - On crée juste des checkout-intents comme pour la boutique
   - Pas de formulaire HelloAsso, pas de custom fields

---

### **2. Quand un User Adhère - Flux Complet**

#### **Étape 1 : User va sur `/memberships/new`**

**Vue** : Formulaire avec 3 choix (Adulte, Étudiant, Famille)

**Affichage** :
- Prix pour chaque catégorie
- Dates de validité : "Valide du 1er septembre 2025 au 31 août 2026"
- Informations légales (CGU, RGPD, attestation aptitude)

#### **Étape 2 : User sélectionne une catégorie**

**Exemple** : User clique sur "Adulte"

**L'application calcule automatiquement** :
- `category` = "adult"
- `amount_cents` = 5000 (50€)
- `start_date` = 1er septembre 2025 (via `current_season_dates`)
- `end_date` = 31 août 2026 (via `current_season_dates`)

#### **Étape 3 : User remplit les informations obligatoires**

**Champs obligatoires** (voir section "Champs Obligatoires" ci-dessous) :
- Prénom, Nom
- Date de naissance
- Email (déjà connu si connecté)
- Adresse complète (rue, CP, ville)
- Acceptations légales (CGU, RGPD, attestation aptitude)
- Si mineur : Autorisation parentale (voir `adhesions-mineurs-legislation.md`)

#### **Étape 4 : Création de l'adhésion locale**

**Action** : `POST /memberships` (MembershipsController#create)

**Ce qui est créé** :
- `Membership` avec `status = "pending"`
- `start_date` et `end_date` calculés automatiquement
- `amount_cents` calculé selon catégorie

#### **Étape 5 : Création du checkout-intent HelloAsso**

**Action** : `HelloassoService.create_checkout_intent` (même méthode que pour commandes)

**Payload envoyé** :
- `totalAmount` = montant en centimes
- `initialAmount` = même montant
- `itemName` = "Adhésion [Catégorie] Saison [Année]"
- `backUrl`, `errorUrl`, `returnUrl`
- `containsDonation` = false
- `metadata.membership_id` = ID de l'adhésion locale

**⚠️ IMPORTANT** :
- **PAS de formSlug**
- **PAS de custom fields**
- **PAS de gestion de périodes HelloAsso**
- Juste un checkout-intent simple comme pour une commande

#### **Étape 6 : Création du Payment local**

**Ce qui est créé** :
- `Payment` avec `provider = "helloasso"`
- `provider_payment_id` = ID du checkout-intent
- `status = "pending"`
- Liaison : `Membership.payment = Payment`

#### **Étape 7 : Redirection vers HelloAsso**

**Action** : Redirection vers `redirectUrl` avec `allow_other_host: true`

**Ce qui se passe** :
- User est redirigé vers la page de paiement HelloAsso
- Il voit le montant (50€)
- Il complète le paiement
- Après paiement, il est redirigé vers `returnUrl`

#### **Étape 8 : Retour sur notre site + Polling**

**Action** : `GET /memberships/:id` (MembershipsController#show)

**Ce qui se passe** :
1. L'adhésion est toujours en statut "pending"
2. Un polling JavaScript vérifie le statut toutes les 5 secondes
3. Un cron job (toutes les 5 minutes) vérifie aussi le statut via l'API HelloAsso

#### **Étape 9 : Mise à jour automatique**

**Quand le paiement est confirmé** :
- `Payment.status = "succeeded"`
- `Membership.status = "active"`
- Email de bienvenue envoyé
- Optionnel : `User.role = Role.find_by(code: "REGISTERED")`

**C'est terminé.** L'adhésion reste "active" jusqu'à `end_date`.

---

### **3. Renouvellement (L'année d'après)**

#### **Cas 1 : User renouvelle volontairement**

**30 jours avant expiration** :
- Rake task envoie un email : "Votre adhésion expire le 31 août 2026. Renouvelez maintenant"
- Lien "Renouveler" dans l'email

**Quand user clique** :
1. Crée une **NOUVELLE Membership** (même user, nouvelle période)
   - `start_date` = 1er septembre 2026
   - `end_date` = 31 août 2027
   - `status` = "pending"
2. Crée un **NOUVEAU Payment** (nouveau paiement)
3. Redirige vers HelloAsso
4. Boucle répète (polling, activation, etc.)

**L'ancienne Membership** reste en base avec `status = "expired"` (historique)

#### **Cas 2 : User oublie de renouveler**

**Quand `end_date` est dépassée** :
- Rake task quotidienne détecte les adhésions expirées
- Met à jour : `Membership.status = "expired"`
- Envoie email : "Votre adhésion a expiré"
- Optionnel : `User.role = Role.find_by(code: "USER")`

**User ne peut plus accéder aux zones "membres only"**

**À lui de renouveler quand il veut** (même processus que Cas 1)

---

## 📋 CHAMPS OBLIGATOIRES POUR UNE ADHÉSION

### **Légalement Obligatoires (Loi 1901 + Associations Sportives)**

#### **1. Identité de l'Adhérent**

- ✅ **Nom** (obligatoire)
- ✅ **Prénom** (obligatoire)
- ✅ **Date de naissance** (obligatoire - pour mineurs/majeurs)
- ⚠️ **Genre** (optionnel mais recommandé)

#### **2. Contact**

- ✅ **Email** (OBLIGATOIRE - pour recevoir confirmation + licence FFRS)
- ⚠️ **Téléphone** (recommandé mais pas obligatoire)

#### **3. Adresse**

- ✅ **Adresse complète** (obligatoire)
- ✅ **Code postal** (obligatoire)
- ✅ **Ville** (obligatoire)
- ⚠️ **Pays** (optionnel, "France" par défaut)

#### **4. Consentement & Acceptation**

- ✅ **Acceptation des conditions d'adhésion** (checkbox obligatoire)
- ✅ **Acceptation de la politique de confidentialité** (RGPD) (checkbox obligatoire)
- ✅ **Attestation d'aptitude physique** (checkbox obligatoire - "Je certifie être apte à la pratique du roller")
- ⚠️ **Acceptation de l'assurance FFRS** (si FFRS - checkbox obligatoire)

#### **5. Autorisation Parentale (Si Mineur)**

- ✅ **Si age < 18 ans** :
  - Nom/Prénom du représentant légal
  - Email du représentant légal
  - Signature de l'autorisation parentale (checkbox)
  - Attestation qu'au moins 1 représentant a accepté

**⚠️ IMPORTANT** : Voir `adhesions-mineurs-legislation.md` pour les détails complets sur la gestion des mineurs.

#### **6. Certificat Médical (Optionnel mais Recommandé)**

- ⚠️ **Upload de fichier** (optionnel mais collecté si fourni)
- ⚠️ **Déclaration sur l'honneur** (minimum requis) : "Je certifie avoir consulté un médecin et être apte à la pratique"

**Obligatoire légalement pour** :
- Mineurs
- Compétiteurs FFRS
- Recommandé pour tous (risques de responsabilité civile)

---

### **Résumé : Champs Minimum à Demander**

#### **Adhésion BASIC (Simple)**

**Identité** :
- ✅ Prénom *
- ✅ Nom *
- ✅ Date de naissance *

**Contact** :
- ✅ Email * (déjà connu si connecté)
- ⚠️ Téléphone (optionnel)

**Adresse** :
- ✅ Adresse *
- ✅ Code postal *
- ✅ Ville *

**Catégorie** :
- ✅ Choix d'adhésion (adult/student/family) - déjà sélectionné

**Légal** :
- ✅ ☑️ "J'accepte les conditions d'adhésion" *
- ✅ ☑️ "J'accepte la politique de confidentialité" *
- ✅ ☑️ "Je certifie être apte à la pratique du roller" * (attestation)

**Si Mineur** :
- ✅ Nom parent/tuteur *
- ✅ Email parent/tuteur *
- ✅ ☑️ Autorisation du représentant légal *

**\* = Champs obligatoires**

---

### **Stockage des Informations**

**Options** :

1. **Dans le modèle User** (si déjà présentes) :
   - `first_name`, `last_name` : Déjà présents
   - `email` : Déjà présent
   - `phone` : Déjà présent (optionnel)
   - `date_of_birth` : À ajouter si pas présent
   - `address`, `postal_code`, `city` : À ajouter si pas présents

2. **Dans le modèle Membership** (si spécifiques à l'adhésion) :
   - `metadata` (jsonb) : Pour stocker les informations supplémentaires
   - Exemple : `metadata: { date_of_birth: "1990-01-01", address: "...", parent_name: "..." }`

3. **Hybride** (recommandé) :
   - Informations permanentes → `User` (date_of_birth, address, etc.)
   - Informations spécifiques à l'adhésion → `Membership.metadata` (certificat médical upload, etc.)

---

## 🔄 FLUX TECHNIQUE DÉTAILLÉ

### **Step 1 : Créer une Adhésion (POST /memberships)**

**User soumet** : `category = "adult"`

**L'application** :

1. **Récupère la saison courante** : Calcul automatique via `current_season_dates`
2. **Calcule le prix** : Calcul automatique via `price_for_category(category)`
3. **Crée un record Membership** : Avec `status = "pending"`
4. **Crée un checkout-intent HelloAsso** : Même endpoint que pour commandes
5. **Crée un Payment** : Avec `provider = "helloasso"` et `status = "pending"`
6. **Redirect vers HelloAsso** : Via `redirectUrl` avec `allow_other_host: true`

---

### **Step 2 : Après Paiement (Polling)**

**Polling JavaScript** (chaque 5s) ou **Rake task** (chaque 5 min) :

1. **Récupère Payment.status via HelloAsso API** : Via `fetch_and_update_payment`
2. **Si status = "succeeded"** :
   - `Membership.status = "active"`
   - Email de bienvenue envoyé
   - Optionnel : Mise à jour du rôle utilisateur
3. **Si status = "failed"** :
   - `Membership.status = "expired"`
   - Email d'échec envoyé

---

### **Step 3 : Vérification Quotidienne (Rake task)**

**Rake task** : `daily:update_expired_memberships`

**Exécution** : Chaque jour à minuit

**Logique** :
- Sélectionner toutes les adhésions avec `status = "active"`
- Vérifier si `end_date < Date.today`
- Si oui : Mettre à jour `status = "expired"` et envoyer email

---

### **Step 4 : Renouvellement**

**30 jours avant expiration** : Rake task `daily:send_renewal_reminders`

**Email envoyé** :
- "Votre adhésion expire le 31 août 2026. Cliquez pour renouveler"
- Lien : `/memberships/new?renew=true`

**Si user clique** :

1. **Crée une NOUVELLE Membership** : Même user, nouvelle période
2. **Crée un NEW Payment** : Nouveau paiement
3. **Redirige vers HelloAsso**
4. **Boucle répète** : Polling, activation, etc.

**L'ancienne Membership** reste en base avec `status = "expired"` (historique)

---

## 🗄️ STRUCTURE DE BASE DE DONNÉES VALIDÉE

### **Table `memberships`**

**Champs principaux** :
- `user_id` (référence, obligatoire)
- `category` (enum: adult, student, family)
- `status` (enum: pending, active, expired)
- `start_date` (date, obligatoire)
- `end_date` (date, obligatoire)
- `amount_cents` (integer, obligatoire)
- `currency` (string, default: "EUR")
- `payment_id` (référence vers Payment, optionnel)
- `provider_order_id` (string - ID de l'order HelloAsso)
- `metadata` (jsonb - Informations supplémentaires)
- `created_at`, `updated_at`

**Index recommandés** :
- `[:user_id, :status]`
- `[:user_id, :category]`
- `:provider_order_id`
- `[:status, :end_date]` (pour la rake task d'expiration)

---

### **Modifications au modèle Payment**

**À ajouter** :
- Relation `has_one :membership` (optionnelle)
- Un `Payment` peut être lié soit à un `Order`, soit à un `Membership`

---

## 🔧 MODIFICATIONS NÉCESSAIRES AU CODE EXISTANT

### **1. Modèle User**

**À ajouter** :
- Relation `has_many :memberships`
- Helpers pour vérifier adhésion active
- Champs si manquants : `date_of_birth`, `address`, `postal_code`, `city`

---

### **2. Service HelloassoService**

**À adapter** :
- Adapter `create_checkout_intent` pour accepter `Membership` (en plus de `Order`)
- Créer `build_membership_checkout_payload` pour construire le payload spécifique aux adhésions
- Adapter `fetch_and_update_payment` pour mettre à jour `Membership` (en plus de `Order`)

---

### **3. Controller MembershipsController**

**À créer** :
- Actions : `index`, `new`, `create`, `show`, `pay`, `payment_status`
- Logique similaire à `OrdersController` mais adaptée aux adhésions
- Gestion des mineurs (voir `adhesions-mineurs-legislation.md`)

---

### **4. Routes**

**À ajouter** :
- `resources :memberships, only: [:index, :new, :create, :show]`
- Routes membres : `post :pay`, `get :payment_status`

---

### **5. Vues**

**À créer** :
- `memberships/index.html.erb` : Liste historique des adhésions
- `memberships/new.html.erb` : Formulaire avec 3 choix (Adulte/Étudiant/Famille)
- `memberships/show.html.erb` : Détail avec polling et bouton renouveler
- Polling JavaScript (comme pour commandes)

---

### **6. Rake Tasks**

**À créer** :
- `memberships:update_expired` : Mise à jour quotidienne des adhésions expirées
- `memberships:send_renewal_reminders` : Envoi d'emails 30 jours avant expiration
- Configuration cron (Whenever)

---

### **7. Mailers**

**À créer** : `MembershipMailer`

**Méthodes** :
- `membership_activated` : Email de bienvenue
- `membership_payment_failed` : Email d'échec de paiement
- `membership_expired` : Email d'expiration
- `membership_renewal_reminder` : Email de rappel de renouvellement

---

## 📊 COMPARAISON AVEC LE FLUX BOUTIQUE

| Aspect | Commandes Boutique | Adhésions (validé) |
|--------|-------------------|-------------------|
| **Modèle local** | `Order` + `OrderItem` | `Membership` |
| **Endpoint HelloAsso** | `/checkout-intents` | ✅ `/checkout-intents` (même) |
| **Type de paiement** | One-time | ✅ One-time (même) |
| **Stock** | Déduit immédiatement | ✅ N/A |
| **Renouvellement** | N/A | ✅ Manuel (Rake task) |
| **Durée** | Immédiat | ✅ Dates fixes (1er sept - 31 août) |
| **Informations supplémentaires** | N/A | ✅ Collectées dans formulaire (User ou metadata) |
| **Réconciliation** | Polling + Cron | ✅ Polling + Cron (même système) |
| **Payload HelloAsso** | `totalAmount` + `itemName` | ✅ `totalAmount` + `itemName` (même structure) |

---

## ✅ AVANTAGES DE CETTE APPROCHE

### **1. SIMPLE**
- ✅ Pas de synchronisation HelloAsso complexe
- ✅ Dates fixes = calculable d'avance
- ✅ HelloAsso = juste "accepter le paiement"
- ✅ Code réutilisable (même service que commandes)

### **2. MAINTENU**
- ✅ Tout en ta base de données
- ✅ Contrôle total
- ✅ Pas de surprise de HelloAsso
- ✅ Facile à déboguer

### **3. FLEXIBLE**
- ✅ Tu veux changer les dates ? Edit dans ton app
- ✅ Tu veux ajouter une catégorie ? Add en DB
- ✅ Tu veux gérer les réductions ? C'est toi qui code
- ✅ Pas de dépendance à la configuration HelloAsso

### **4. PERFORMANT**
- ✅ Pas d'appels API pour vérifier une adhésion
- ✅ Requête simple en base de données
- ✅ Rake task quotidienne = 0.1s même avec 10k adhérents

### **5. TESTABLE**
- ✅ Tests unitaires simples
- ✅ Pas de mock d'API HelloAsso complexe
- ✅ Tests d'intégration faciles

### **6. SCALABLE**
- ✅ Peut gérer 10k adhérents sans problème
- ✅ Une Rake task par jour = 0.1s
- ✅ Pas de limite côté HelloAsso

---

## ❌ INCONVÉNIENTS (Mineurs)

### **1. Pas de custom fields HelloAsso**
- ⚠️ Mais tu ne les stockes pas, pourquoi en avoir besoin ?
- ✅ Tu collectes tout dans ton formulaire

### **2. Gestion manuelle du renouvellement**
- ⚠️ Mais c'est ce que tu veux de toute façon
- ✅ Rake task automatique = transparent

### **3. Pas de "entrées/sorties" auto HelloAsso**
- ⚠️ Mais avec Rake task quotidienne, c'est transparent
- ✅ Tu contrôles tout

---

## 🎯 TIMELINE D'EXÉCUTION

### **Jour 1 : Base de données et modèles**
- Migration `create_memberships`
- Modèle `Membership` avec enums et méthodes
- Modifier `User` (ajouter `has_many :memberships`)
- Modifier `Payment` (ajouter `has_one :membership`)
- Tests unitaires du modèle

### **Jour 2 : Service HelloAsso**
- Adapter `HelloassoService` pour accepter `Membership`
- Créer `build_membership_checkout_payload`
- Tester en sandbox
- Adapter `fetch_and_update_payment` pour mettre à jour `Membership`

### **Jour 3 : Controller et routes**
- Créer `MembershipsController`
- Actions : `index`, `new`, `create`, `show`, `pay`, `payment_status`
- Routes
- Tests du controller

### **Jour 4 : Vues**
- `memberships/index.html.erb` : Liste historique
- `memberships/new.html.erb` : Formulaire avec 3 choix
- `memberships/show.html.erb` : Détail avec polling
- Polling JavaScript (comme pour commandes)

### **Jour 5 : Rake tasks et emails**
- Rake task `memberships:update_expired`
- Rake task `memberships:send_renewal_reminders`
- Configuration cron (Whenever)
- Mailer `MembershipMailer` avec 4 méthodes
- Templates emails

### **Jour 6 : Tests et polish**
- Tests d'intégration complets
- Test du flux complet (création → paiement → activation)
- Test du renouvellement
- Test de l'expiration
- Cleanup + refactor
- Documentation

### **Jour 7 : Déploiement**
- Migration en staging
- Tests en staging
- Migration en production
- Monitoring

---

## ✅ CHECKLIST FINALE

### **Core**
- [ ] Membership model avec statuts simples (pending/active/expired)
- [ ] Payment lié à Membership
- [ ] Controller memberships simplifié
- [ ] Checkout-intents SANS formSlug (comme commandes)

### **Checkout**
- [ ] Créer membership en pending
- [ ] Build payload simple (totalAmount + itemName, pas de formSlug)
- [ ] Create Payment
- [ ] Redirect HelloAsso

### **Synchronisation**
- [ ] Polling HelloAsso (même que commandes)
- [ ] Update Membership.status = active quand paid
- [ ] Rake task daily update_expired

### **Renouvellement**
- [ ] Rake task send_renewal_reminders (30j avant)
- [ ] Créer NEW membership + payment
- [ ] Email + link

### **Vues**
- [ ] new : 3 choices (adult/student/family)
- [ ] show : display membership + polling + renew btn
- [ ] index : historical list

### **Champs obligatoires**
- [ ] Formulaire avec tous les champs légaux
- [ ] Validation côté serveur
- [ ] Stockage dans User ou Membership.metadata

### **Mineurs**
- [ ] Gestion des mineurs (< 16 ans, 16-17 ans)
- [ ] Autorisation parentale
- [ ] Certificat médical / attestation santé
- [ ] Voir `adhesions-mineurs-legislation.md` pour détails

---

## 🎁 RÉSUMÉ EN 1 PHRASE

> **HelloAsso = Juste le paiement. Ton app = Tout le reste (dates fixes, statuts, renouvellement). Simple et maintenable. ✅**

---

## 🔗 RESSOURCES

### **Documentation HelloAsso**
- API v5 Docs : https://api.helloasso.com/v5/docs
- Dev Portal : https://dev.helloasso.com/
- Swagger Sandbox : https://api.helloasso-sandbox.com/v5/swagger/ui/index

### **Documentation interne**
- Flux boutique HelloAsso : `docs/09-product/flux-boutique-helloasso.md`
- Info API HelloAsso : `docs/09-product/helloasso-etape-1-api-info.md`
- Guide technique : `docs/02-shape-up/technical-implementation-guide.md`
- **Mineurs et législation** : `docs/09-product/adhesions-mineurs-legislation.md`

---

**Note** : Ce document décrit la stratégie validée avec Perplexity. L'implémentation peut commencer immédiatement.
