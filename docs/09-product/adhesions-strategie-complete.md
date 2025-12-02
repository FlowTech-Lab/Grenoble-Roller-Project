# Adhésions - Stratégie Complète et Plan d'Implémentation

**Date** : 2025-01-27  
**Version** : 3.0  
**Status** : ✅ Stratégie finale validée - Prêt pour implémentation

---

## 📋 Vue d'ensemble

Ce document consolide toute la stratégie d'implémentation des adhésions pour Grenoble Roller, incluant :
- La stratégie technique (HelloAsso = paiement uniquement)
- La gestion des mineurs (législation française)
- Le plan d'implémentation complet
- Les checklists détaillées

**🎯 Principe Fondamental** : **TOUT dans l'APP, HelloAsso = SEULEMENT paiement**

---

## 🎯 STRATÉGIE FINALE : TOUT DANS L'APP

### **Principes**

- **HelloAsso = SEULEMENT paiement** (checkout-intents)
- **Ton App = TOUT le reste** (adhésion, dates, gestion, renewal)
- **Résultat** :
  - ✅ Zéro complexité sync API
  - ✅ Single source of truth (ta base de données)
  - ✅ Contrôle 100% du flux
  - ✅ Admin dashboard pour tout
  - ✅ Automatisation année après année

---

## 🔄 FLUX FINAL SIMPLIFIÉ

### **ANNÉE N**

**1. Admin configure adhésion pour N+1**
- Dates fixes : 1er sept N → 31 août N+1
- Tarifs : 10€ standard, 56.55€ avec FFRS ✅ **Corrigé selon HelloAsso réel** (au lieu de 50€/25€/80€)
- Page `/memberships/new` disponible

**2. User adhère**
- **Étape 0** : Page de choix `/memberships/choose` - "Adhésion Simple" (10€) ou "Adhésion + T-shirt" (24€)
- **Étape 1** : Choisit catégorie (Standard 10€ ou FFRS 56.55€)
- **Étape 2** (si T-shirt) : Sélection T-shirt (taille, quantité) - Prix membre 14€ au lieu de 20€
- **Étape 3** : Remplit formulaire complet (informations, coordonnées, consentements)
- App crée Membership (pending)
- Paiement HelloAsso
- Membership → active
- Email "Bienvenue"

**3. Rake tasks automatiques (chaque jour)**
- `sync_payments` : fetch HelloAsso pour paiements
- `check_expiry` : Si `end_date < today` → `status = expired`
- `send_reminders` : 30j avant expiration → email "Renouveler"

**4. Admin Dashboard**
- Vue : "20 adhérents actifs"
- Tableau : Liste adhésions (statut, dates, paiement)
- Filtres : Actif, Expiré, Pending
- Export : CSV pour courrier/stats

**5. User Profile**
- Affiche : "Adhésion active jusqu'au 31 août N+1"
- Ou : "Adhésion expirée - Renouveler"
- Bouton "Renouveler adhésion" → Redirige vers `/memberships/choose` (avec option T-shirt pour renouvellement)
- **Gestion enfants** : Possibilité d'ajouter des enfants un par un, paiement groupé possible

**6. 31 Août N+1 (Auto)**
- Rake task : Toutes adhésions expirent
- Email : "Adhésion expirée"
- User voit : Status = "expired"
- **Renouvellement** : Possibilité de renouveler avec ou sans nouveau T-shirt

**7. Sept N+1 (Nouveau Cycle)**
- Adhésions N+2 disponibles
- Utilisateurs renouvellent
- Boucle recommence

---

## 🗄️ STRUCTURE DE BASE DE DONNÉES

### **Table `memberships`**

**Champs SIMPLES** :
- `id` (primary key)
- `user_id` (FK vers users)
- `category` : enum "standard" / "with_ffrs" ✅ **Corrigé selon HelloAsso réel** (au lieu de adult/student/family)
- `amount_cents` : 1000 / 5655 ✅ **Corrigé selon HelloAsso réel** (10€ / 56.55€ au lieu de 50€/25€/80€)
- `status` : enum "pending" → "active" → "expired"
- `start_date` : 1er sept N (date)
- `end_date` : 31 août N+1 (date)
- `season` : "2025-2026" (string, pour historique)
- `payment_id` (FK vers payments, optionnel)
- `provider_order_id` : ID HelloAsso pour réconciliation (string)
- `with_tshirt` (boolean, default: false) ✅ **Ajouté pour upsell T-shirt**
- `tshirt_size` (string, nullable) ✅ **Ajouté pour upsell T-shirt**
- `tshirt_qty` (integer, default: 0) ✅ **Ajouté pour upsell T-shirt**
- `tshirt_variant_id` (FK vers product_variants, optionnel) ✅ **Déprécié - Utiliser with_tshirt/tshirt_size/tshirt_qty**
- `tshirt_price_cents` (integer, default: 1400) ✅ **Déprécié - Prix calculé dynamiquement**
- `created_at`, `updated_at`

**Champs pour mineurs** (si nécessaire) :
- `is_minor` (boolean) : true si age < 16
- `parent_name` (string)
- `parent_email` (string)
- `parent_phone` (string)
- `parent_authorization` (boolean) : accord signé
- `parent_authorization_date` (date)
- `health_questionnaire_status` (string) : "ok" / "medical_required"
- `medical_certificate_provided` (boolean)
- `medical_certificate_url` (string) : lien PDF
- `emergency_contact_name` (string)
- `emergency_contact_phone` (string)
- `rgpd_consent` (boolean)
- `ffrs_data_sharing_consent` (boolean)
- `legal_notices_accepted` (boolean)

**Validations simples** :
- `user_id + season` : unique (pas 2 adhésions même user même saison)
- `start_date < end_date`

**Index recommandés** :
- `[:user_id, :status]`
- `[:user_id, :season]`
- `[:status, :end_date]` (pour rake task expiration)
- `:provider_order_id`

---

## 🏗️ MODÈLE MEMBERSHIP

**Structure validée** :

**Relations** :
- `belongs_to :user`
- `belongs_to :payment, optional: true`

**Enums** :
- `enum :status, { pending: 0, active: 1, expired: 2 }` ✅
- `enum :category, { standard: 0, with_ffrs: 1 }` ✅ **Corrigé selon HelloAsso réel** (au lieu de adult/student/family)

**Scopes** :
- `scope :active_now` : Adhésions actives (status = active ET end_date > today)
- `scope :expiring_soon` : Adhésions expirant dans 7 jours
- `scope :pending_payment` : Adhésions en attente de paiement

**Méthodes** :
- `active?` : Vérifier si l'adhésion est active (status = "active" ET end_date > Date.current)
- `expired?` : Vérifier si l'adhésion est expirée (end_date <= Date.current)
- `days_until_expiry` : Calculer jours restants avant expiration
- `price_for_category(category)` : Calcul automatique du prix selon catégorie
- `current_season_dates` : Calcul automatique des dates de saison (1er sept - 31 août)

**Validations** :
- `validates :user_id, uniqueness: { scope: :season }`
- `validates :start_date, :end_date, :amount_cents, presence: true`

---

## 🔌 INTÉGRATION HELLOASSO

### **Service HelloassoService**

**Méthodes à adapter/créer** :

**1. `create_membership_checkout(membership, back_url:, error_url:, return_url:)`**
- Crée un checkout-intent HelloAsso pour une adhésion
- Utilise le même endpoint que pour les commandes : `POST /v5/organizations/{slug}/checkout-intents`
- Payload simplifié :
  - `totalAmount` = `membership.amount_cents`
  - `initialAmount` = `membership.amount_cents`
  - `itemName` = "Adhésion [Catégorie] Saison [Année]"
  - `backUrl`, `errorUrl`, `returnUrl`
  - `containsDonation` = false
  - `metadata.membership_id` = ID de l'adhésion locale

**2. `fetch_and_update_payment(payment)`**
- Déjà existant pour les commandes
- À adapter pour mettre à jour `Membership.status` si le payment est lié à une adhésion
- Logique : `order.state == "Confirmed"` → `Membership.status = "active"`

---

## 📋 GESTION DES MINEURS

### **Règles par Âge**

| Âge | Adhésion | Paiement | Accord Parent | Certificat | Parent Informé |
|-----|----------|----------|---------------|------------|----------------|
| **< 16** | Libre* | Enfant ou parent | ✅ Écrit obligatoire | ✅ Attestation OU cert | Avant |
| **16-17** | Libre | Libre | ❌ Non obligatoire | ✅ Attestation OU cert | Après |
| **18+** | Libre | Libre | ❌ Non | ✅ Si FFRS compétition | Non |

**\* = Libre mais accord parent obligatoire pour adhérer**

### **Documents Requis**

**Pour Enfant < 16 ans** :
- ✅ Accord écrit des parents (formulaire d'autorisation parentale)
- ✅ Certificat médical OU attestation parentale de santé
- ✅ Identité du représentant légal (nom, email, téléphone)

**Pour Enfant ≥ 16 ans** :
- ✅ Certificat médical OU attestation de santé
- ⚠️ Notification aux parents (email recommandé)

**Pour Adulte** :
- ✅ Certificat médical OU attestation (si compétition FFRS)

### **Certificat Médical vs Attestation**

**Depuis 2021** :
- **Option 1 (Recommandé)** : Attestation parentale
  - Parent remplit questionnaire "Cerfa 15699*01"
  - Répond NON à toutes questions
  - **VALABLE 3 ANS**

- **Option 2 (Si problème de santé)** : Certificat médical
  - **VALABLE 6 MOIS** si réponse positive au questionnaire
  - **VALABLE 3 ANS** si renouvellement

**Dans l'app** :
- Question simple : "L'enfant a-t-il des problèmes de santé ?"
  - ☐ Non → Attestation parentale suffit
  - ☐ Oui → Certificat médical requis (< 6 mois)

---

## 🛠️ FLUX D'ADHÉSION PAR CATÉGORIE

### **ENFANT < 16 ans**

**ÉTAPE 0** : Page de choix `/memberships/choose?child=true`
- "Adhésion Simple" (10€ ou 56.55€ selon catégorie)
- "Adhésion + T-shirt" (24€ ou 70.55€ selon catégorie + T-shirt 14€)

**ÉTAPE 1** : Sélection catégorie
- L'app détecte : `age < 16` (calculé automatiquement)
- Message : "Vous êtes mineur, un accord parental est nécessaire"
- Catégorie Standard (10€) ou FFRS (56.55€)

**ÉTAPE 2** (si T-shirt sélectionné) : Sélection T-shirt
- Choix taille et quantité
- Prix membre : 14€ au lieu de 20€
- Total affiché dynamiquement

**ÉTAPE 3** : Formulaire avec accord parent
- Prénom, Nom (enfant)
- Date naissance (enfant) - 3 dropdowns (jour, mois, année)
- Email, Téléphone (parent)
- ☑️ "Le parent/tuteur accepte l'adhésion" (obligatoire si < 16 ans)
- ☑️ "Le parent/tuteur accepte le paiement"

**ÉTAPE 4** : Questionnaire de santé (9 questions)

**ADHÉSION STANDARD (10€)** :
- Questionnaire présent (9 questions)
- Pas obligatoire de tout cocher "NON" pour continuer
- Juste demander de répondre honnêtement
- Si réponse "OUI" → Pas d'upload certificat obligatoire
- Affichage : "Consultez votre médecin avant de pratiquer"

**LICENCE FFRS (56.55€)** :
- Questionnaire OBLIGATOIRE
- Si toutes réponses "NON" → Génération attestation automatique (si renouvellement)
- Si au moins 1 "OUI" → Upload certificat OBLIGATOIRE
- Si nouvelle licence FFRS → Upload certificat OBLIGATOIRE (même si toutes réponses NON)

**ÉTAPE 5** : Consentements
- RGPD, FFRS, Notices légales
- Préférences communication : `wants_initiation_mail`, `wants_events_mail` (dans User)

**ÉTAPE 6** : Paiement
- Parent paie (email parent saisi)
- Possibilité de payer plusieurs enfants en une seule transaction

**ÉTAPE 7** : Confirmation
- Email parent : "Adhésion enfant en attente de paiement"

---

### **MINEUR 16-17 ans**

**ÉTAPE 1** : Adhésion autonome
- Enfant peut adhérer SEUL
- BUT app doit collecter email PARENT (obligatoire)
- Message : "Vos parents seront informés de votre adhésion"

**ÉTAPE 2** : Formulaire complet
- Prénom, Nom (enfant)
- Date naissance (enfant)
- Email (enfant)
- Email Parent (OBLIGATOIRE)
- Téléphone (enfant optionnel)

**ÉTAPE 3** : Questionnaire de santé (même règles que < 16 selon catégorie)

**ÉTAPE 4** : Paiement
- Enfant peut payer SEUL (si cotisation modique)
- Ou parent paie

**ÉTAPE 5** : Notification Parents
- Email aux parents : "Votre enfant a adhéré à Grenoble Roller"
- Lien : "S'opposer à l'adhésion" (avant paiement)
- Mention : "Vous avez 14 jours pour vous opposer"

---

### **ADULTE >= 18 ans**

**ÉTAPE 0** : Page de choix `/memberships/choose`
- "Adhésion Simple" (10€ ou 56.55€ selon catégorie)
- "Adhésion + T-shirt" (24€ ou 70.55€ selon catégorie + T-shirt 14€)

**ÉTAPE 1** : Sélection catégorie
- Catégorie Standard (10€) ou FFRS (56.55€)

**ÉTAPE 2** (si T-shirt sélectionné) : Sélection T-shirt
- Choix taille et quantité
- Prix membre : 14€ au lieu de 20€
- Total affiché dynamiquement

**ÉTAPE 3** : Formulaire informations
- Prénom, Nom (pré-rempli depuis User)
- Date naissance (3 dropdowns)
- Email (pré-rempli, confirmation affichée)
- Téléphone

**ÉTAPE 4** : Coordonnées
- Adresse, Ville, Code postal
- Préférences communication : `wants_initiation_mail`, `wants_events_mail` (dans User)

**ÉTAPE 5** : Questionnaire de santé (9 questions)

**ADHÉSION STANDARD (10€)** :
- Questionnaire présent (9 questions)
- Pas obligatoire de tout cocher "NON" pour continuer
- Juste demander de répondre honnêtement
- Si réponse "OUI" → Pas d'upload certificat obligatoire
- Affichage : "Consultez votre médecin avant de pratiquer"

**LICENCE FFRS (56.55€)** :
- Questionnaire OBLIGATOIRE
- Si toutes réponses "NON" → Génération attestation automatique (si renouvellement)
- Si au moins 1 "OUI" → Upload certificat OBLIGATOIRE
- Si nouvelle licence FFRS → Upload certificat OBLIGATOIRE (même si toutes réponses NON)

**ÉTAPE 6** : Consentements
- RGPD, FFRS, Notices légales

**ÉTAPE 7** : Paiement
- Paiement HelloAsso

**Flux normal** :
- Pas de vérification parentale
- Pas d'email parent à collecter
- Autonomie complète

---

## 📊 ADMIN DASHBOARD

### **Vue Principale**

**Statistiques** :
- X Actifs
- Y Pending
- Z Expiring (cette semaine)
- € Revenue total

**Filtres** :
- Statut : Tous / Active / Pending / Expired
- Catégorie : Tous / Adult / Student / Family
- Saison : Toutes / 2025-2026 / etc.

**Actions** :
- Export CSV
- Envoyer rappel (expirant)
- Marquer comme "verified" si besoin

**Tableau** :
- USER | CATÉGORIE | DATES | STATUS | PAIEMENT
- Filtrable et triable

**Graphiques** (optionnel) :
- Répartition par catégorie (pie chart)
- Revenue par mois (line chart)
- Adhésions actives par jour (trend)

---

## ⚙️ AUTOMATISATION (RAKE TASKS)

### **1. `helloasso:sync_payments` (chaque 5 min)**

**Logique** :
- Fetch HelloAsso payments pour paiements pending
- Update `Membership.status = "active"` si paid
- Send email bienvenue

**Configuration cron** :
```ruby
every 5.minutes do
  runner 'Rake::Task["helloasso:sync_payments"].invoke'
end
```

---

### **2. `daily:update_expired_memberships` (chaque jour à 00h00)**

**Logique** :
- SELECT `memberships` WHERE `status = "active"` AND `end_date < today`
- UPDATE `status = "expired"`
- Send email "Adhésion expirée"

**Configuration cron** :
```ruby
every 1.day, at: '12:00 am' do
  runner 'Rake::Task["memberships:update_expired"].invoke'
end
```

---

### **3. `daily:send_renewal_reminders` (chaque jour à 10h00)**

**Logique** :
- SELECT `memberships` WHERE `status = "active"` AND `end_date` IN [today + 30 jours]
- Send email "Renouveler dans 30 jours"
- Lien : `/memberships/new?renew=true`

**Configuration cron** :
```ruby
every 1.day, at: '10:00 am' do
  runner 'Rake::Task["memberships:send_renewal_reminders"].invoke'
end
```

---

### **4. `yearly:prepare_new_season` (1er Sept à 08h00)**

**Logique** :
- Récupérer configs de la nouvelle saison
- Enable `/memberships/new`
- Send email à tous "Adhésion nouvelle saison ouverte"

**Configuration cron** :
```ruby
every 1.year, at: 'September 1st at 8:00 am' do
  runner 'Rake::Task["memberships:prepare_new_season"].invoke'
end
```

---

### **5. `daily:check_minor_authorizations` (chaque jour)**

**Logique** :
- Si `Membership.is_minor?` && `parent_authorization == false` après 7 jours
  - → Envoyer email : "Autorisation parentale manquante"
  - → Après 14 jours : `Membership.status = "expired"`

---

### **6. `daily:check_medical_certificates` (chaque jour)**

**Logique** :
- Si `health_questionnaire_status == "medical_required"` && `medical_certificate_provided == false`
  - → Envoyer email : "Certificat médical manquant"
  - → Membership **NOT activated** tant que certificat pas fourni

---

## 📧 EMAILS (TEMPLATES)

### **1. Email : Adhésion activée**

**Sujet** : "✅ Adhésion activée - Bienvenue !"

**Contenu** :
- "Bienvenue [User] !"
- "Adhésion active du 1er sept 2025 au 31 août 2026"
- "Accédez aux événements"

---

### **2. Email : Renouvellement dans 30j**

**Sujet** : "🔄 Renouvelez votre adhésion - Expiration dans 30 jours"

**Contenu** :
- "Bonjour [User],"
- "Votre adhésion expire le 31 août."
- "Renouveler : /memberships/new"

---

### **3. Email : Adhésion expirée**

**Sujet** : "⏰ Votre adhésion a expiré"

**Contenu** :
- "Votre adhésion a expiré le 31 août."
- "Renouveler : /memberships/new"

---

### **4. Email : Autorisation parentale manquante**

**Sujet** : "⚠️ Autorisation parentale manquante"

**Contenu** :
- "Bonjour [Parent],"
- "L'adhésion de [Enfant] nécessite votre autorisation."
- "Lien : /memberships/[id]/authorize"

---

### **5. Email : Certificat médical manquant**

**Sujet** : "⚠️ Certificat médical manquant"

**Contenu** :
- "Bonjour [User],"
- "Un certificat médical est requis pour activer votre adhésion."
- "Lien : /memberships/[id]/upload_certificate"

---

## 🎯 TIMELINE RÉELLE (ANNÉE N)

### **1er Sept N**

- Rake task `prepare_new_season`
- Email à tous : "Adhésions N+1 ouvertes"
- `/memberships/new` disponible

### **Sept-Août N+1**

- Users adhèrent progressivement
- Dashboard affiche stats real-time
- Rake tasks envoient rappels (30j avant fin)

### **31 Août N+1**

- Rake task `update_expired`
- TOUTES adhésions → expired
- Email : "Adhésion expirée, renouveler"

### **Sept N+1**

- Nouvelle saison N+2 ouvre
- Boucle recommence
- Aucune action manuelle requise

---

## ✅ AVANTAGES DE CETTE APPROCHE

### **1. SIMPLICITÉ**
- HelloAsso = paiement SEULEMENT
- App = tout le reste
- Zéro complexity

### **2. AUTOMATISATION**
- Rake tasks gèrent tout
- Admin ne fait rien
- Ça tourne seul année après année

### **3. CONTROL**
- Ta base = source of truth
- Dates fixes = calculables d'avance
- Dashboard pour overview

### **4. SCALABILITÉ**
- 100 adhérents : pas de problem
- 1000 adhérents : pas de problem
- Rake tasks = O(n) trivial

### **5. MAINTENANCE**
- Code centralisé dans ton app
- Pas de "double sync" HelloAsso
- Évolutions faciles

### **6. USER EXPERIENCE**
- User voit adhésion active immédiatement
- Pas d'attente
- Email automatique des rappels

### **7. COMPLIANCE**
- Tu as tout documenté
- Admin peut exporter list légale
- Traçabilité complète

---

## 🎁 TL;DR - LA SOLUTION FINALE

✅ Adhésion = 100% dans ton app  
✅ Dates fixes = pas de complexité  
✅ HelloAsso = paiement seulement  
✅ Rake tasks = automatisation complète  
✅ Admin dashboard = visibilité totale  
✅ Ça tourne seul année après année  
✅ Zero maintenance à faire

---

## 🆕 NOUVELLES FONCTIONNALITÉS (2025)

### **1. Page de Choix T-shirt (Upsell)**

**Route** : `/memberships/choose`

**Fonctionnalité** :
- Deux cartes cliquables : "Adhésion Simple" et "Adhésion + T-shirt"
- Prix T-shirt membre : 14€ au lieu de 20€ (réduction de 6€)
- Total affiché : "24€ au lieu de 30€" (économie de 6€)
- Disponible pour adultes et enfants
- Disponible lors du renouvellement (avec option de nouveau T-shirt)

**Flux** :
1. User clique sur "Adhérer" → Redirige vers `/memberships/choose`
2. User choisit "Adhésion Simple" ou "Adhésion + T-shirt"
3. Si T-shirt : Étape supplémentaire dans le formulaire pour sélection taille/quantité
4. Ordre des étapes : Catégorie d'abord, puis T-shirt (pour calcul dynamique du prix)

---

### **2. Gestion Enfants Simplifiée**

**Fonctionnalité** :
- Ajout d'enfants un par un (plus de formulaire multi-enfants)
- Page `/memberships` centralisée : affiche toutes les adhésions (personnelle + enfants)
- Possibilité de payer plusieurs enfants en attente en une seule transaction
- Modification et suppression des adhésions enfants en attente
- Renouvellement avec option T-shirt

**Routes RESTful** :
- `GET /memberships` : Liste toutes les adhésions
- `GET /memberships/choose` : Page de choix T-shirt
- `POST /memberships` : Créer adhésion (personnelle ou enfant)
- `GET /memberships/:id` : Détail adhésion
- `PATCH /memberships/:id` : Modifier adhésion enfant
- `DELETE /memberships/:id` : Supprimer adhésion enfant
- `POST /memberships/pay_multiple` : Payer plusieurs enfants en une fois

---

### **3. Préférences Communication**

**Champs dans User** (remplacement de `wants_whatsapp` et `wants_email_info`) :
- `wants_initiation_mail` (boolean) : Emails initiations et randos
- `wants_events_mail` (boolean) : Emails événements

**Gestion** :
- Collectées dans le formulaire d'adhésion (section "Communication")
- Modifiables dans le profil utilisateur (`/users/edit`)
- Stockées dans le modèle `User`, pas dans `Membership`

---

### **4. Questionnaire de Santé (9 Questions)**

**Fonctionnalité** :
- 9 questions spécifiques sur la santé (au lieu d'une simple question OUI/NON)
- Si au moins une réponse "OUI" → Upload certificat médical requis (Active Storage)
- Si toutes "NON" → Pas de certificat requis
- Certificat stocké via `has_one_attached :medical_certificate` dans `Membership`

**Champs dans Membership** :
- `health_q1` à `health_q9` (string, enum: "oui", "non")
- `health_questionnaire_status` (enum: "ok", "medical_required")
- `medical_certificate` (Active Storage attachment)

---

### **5. Ordre des Étapes Inversé**

**Ancien ordre** :
1. T-shirt (si sélectionné)
2. Catégorie

**Nouvel ordre** :
1. Catégorie (obligatoire)
2. T-shirt (si sélectionné)

**Raison** : Permet le calcul dynamique du prix total (adhésion + T-shirt) basé sur la catégorie sélectionnée.

---

### **6. Fusion Pages Index/New**

**Ancien** :
- `/memberships` : Liste des adhésions
- `/memberships/new` : Formulaire de création

**Nouveau** :
- `/memberships` : Liste des adhésions + options de création (tout en un)
- Hero section avec CTA "Adhérer maintenant"
- Sidebar avec actions rapides
- Section "Mes adhésions" avec cartes améliorées
- Section historique (adhésions expirées)

---

## 🔗 RESSOURCES

### **Documentation HelloAsso**
- API v5 Docs : https://api.helloasso.com/v5/docs
- Dev Portal : https://dev.helloasso.com/
- Swagger Sandbox : https://api.helloasso-sandbox.com/v5/swagger/ui/index

### **Documentation Légale**
- Loi 1901 - Article 2 bis : Adhésion des mineurs
- Décret 2021-564 : Simplification certificat médical
- Cerfa 15699*01 : Questionnaire de santé

### **Documentation interne**
- Flux boutique HelloAsso : `docs/09-product/flux-boutique-helloasso.md`
- Info API HelloAsso : `docs/09-product/helloasso-etape-1-api-info.md`

---

**Note** : Voir `adhesions-plan-implementation.md` pour le plan d'implémentation détaillé avec checklist complète.

