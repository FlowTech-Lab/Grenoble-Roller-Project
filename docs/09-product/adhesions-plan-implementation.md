# Adhésions - Plan d'Implémentation Détaillé

**Date** : 2025-01-27  
**Version** : 1.0  
**Status** : Plan d'action prêt pour développement

---

## 📋 Vue d'ensemble

Ce document détaille le plan d'implémentation complet de la feature "Adhésions" pour Grenoble Roller, avec des checklists précises pour chaque phase.

**Référence** : Voir `adhesions-strategie-complete.md` pour la stratégie complète.

**Estimation totale** : ~8h de développement

---

## ✅ CHECKLIST IMPLÉMENTATION COMPLÈTE

### **Phase 1 : Database & Model (1h)**

#### **1.1 Migration Membership**

- [x] Créer migration `create_memberships` ✅
- [x] Champs principaux :
  - [x] `user_id` (references, null: false) ✅
  - [x] `category` (integer, null: false) - enum ✅
  - [x] `status` (integer, null: false, default: 0) - enum ✅
  - [x] `start_date` (date, null: false) ✅
  - [x] `end_date` (date, null: false) ✅
  - [x] `amount_cents` (integer, null: false) ✅
  - [x] `currency` (string, default: "EUR") ✅
  - [x] `season` (string) - ex: "2025-2026" ✅
  - [x] `payment_id` (references, null: true) ✅
  - [x] `provider_order_id` (string) ✅
  - [x] `metadata` (jsonb) ✅
- [x] Champs mineurs (optionnels pour Phase 1) :
  - [x] `is_minor` (boolean) ✅
  - [x] `parent_name` (string) ✅
  - [x] `parent_email` (string) ✅
  - [x] `parent_phone` (string) ✅
  - [x] `parent_authorization` (boolean) ✅
  - [x] `parent_authorization_date` (date) ✅
  - [x] `health_questionnaire_status` (string) ✅
  - [x] `medical_certificate_provided` (boolean) ✅
  - [x] `medical_certificate_url` (string) ✅
  - [x] `emergency_contact_name` (string) ✅
  - [x] `emergency_contact_phone` (string) ✅
  - [x] `rgpd_consent` (boolean) ✅
  - [x] `ffrs_data_sharing_consent` (boolean) ✅
  - [x] `legal_notices_accepted` (boolean) ✅
- [x] **Champs supplémentaires (HelloAsso réel)** :
  - [x] `with_tshirt` (boolean, default: false) ✅ **Nouveau système upsell**
  - [x] `tshirt_size` (string, nullable) ✅ **Nouveau système upsell**
  - [x] `tshirt_qty` (integer, default: 0) ✅ **Nouveau système upsell**
  - [x] `health_q1` à `health_q9` (string, enum: "oui", "non") ✅ **Questionnaire 9 questions**
  - [x] `health_questionnaire_status` (enum: "ok", "medical_required") ✅ **Statut questionnaire**
  - [x] `medical_certificate` (Active Storage attachment) ✅ **Upload certificat**
- [x] Index :
  - [x] `add_index :memberships, [:user_id, :status]` ✅
  - [x] `add_index :memberships, [:user_id, :season]` ✅
  - [x] `add_index :memberships, [:status, :end_date]` ✅
  - [x] `add_index :memberships, :provider_order_id` ✅
  - [x] `add_index :memberships, [:user_id, :season], unique: true` ✅
- [x] Validation unique : `user_id + season` ✅

---

#### **1.2 Model Membership**

- [x] Créer `app/models/membership.rb` ✅
- [x] Relations :
  - [x] `belongs_to :user` ✅
  - [x] `belongs_to :payment, optional: true` ✅
  - [x] `belongs_to :tshirt_variant, optional: true` ✅ **Ajouté pour HelloAsso réel**
- [x] Enums :
  - [x] `enum :status, { pending: 0, active: 1, expired: 2 }` ✅
  - [x] `enum :category, { standard: 0, with_ffrs: 1 }` ✅ **Corrigé selon HelloAsso réel** (au lieu de adult/student/family)
- [x] Scopes :
  - [x] `scope :active_now` : `active.where("end_date > ?", Date.current)` ✅
  - [x] `scope :expiring_soon` : `active.where("end_date BETWEEN ? AND ?", Date.current, 30.days.from_now)` ✅
  - [x] `scope :pending_payment` : `pending` ✅
- [x] Méthodes :
  - [x] `active?` : Vérifier si active (status = "active" ET end_date > today) ✅
  - [x] `expired?` : Vérifier si expirée (end_date <= today) ✅
  - [x] `days_until_expiry` : Calculer jours restants ✅
  - [x] `self.price_for_category(category)` : Retourner prix en centimes ✅ **Corrigé : 10€ et 56.55€**
  - [x] `self.current_season_dates` : Retourner [start_date, end_date] ✅
  - [x] `self.current_season_name` : Retourner "2025-2026" ✅
  - [x] `total_amount_cents` : Calculer adhésion + T-shirt ✅ **Ajouté pour HelloAsso réel**
  - [x] `is_minor?` : Vérifier si mineur ✅
  - [x] `requires_parent_authorization?` : Vérifier si < 16 ans ✅
- [x] Validations :
  - [x] `validates :user_id, uniqueness: { scope: :season }` ✅
  - [x] `validates :start_date, :end_date, :amount_cents, presence: true` ✅
  - [x] `validates :start_date, comparison: { less_than: :end_date }` ✅

---

#### **1.3 Update User Model**

- [x] Ajouter relation `has_many :memberships, dependent: :destroy` ✅
- [x] Helpers :
  - [x] `has_active_membership?` : Vérifier si adhésion active ✅
  - [x] `current_membership` : Retourner adhésion active actuelle ✅
  - [x] `age` : Calculer l'âge ✅
  - [x] `is_minor?` : Vérifier si mineur (< 18) ✅
  - [x] `is_child?` : Vérifier si enfant (< 16) ✅
- [x] Champs à ajouter (si manquants) :
  - [x] Migration `add_date_of_birth_to_users` (date) ✅
  - [x] Migration `add_address_fields_to_users` (address, postal_code, city) ✅
  - [x] Migration `add_email_preferences_to_users` (wants_initiation_mail, wants_events_mail) ✅ **Remplace wants_whatsapp/wants_email_info**
- [x] `phone` : ✅ **Déjà présent dans schema**

---

#### **1.4 Update Payment Model**

- [x] Ajouter relation `has_one :membership` ✅
- [x] Vérifier que `Payment` peut être lié soit à `Order`, soit à `Membership` ✅

---

### **Phase 2 : Flow Adhésion (2h)**

#### **2.1 Service HelloassoService**

- [x] Créer méthode `create_membership_checkout_intent(membership, back_url:, error_url:, return_url:)` ✅
- [x] Payload :
  - [x] `totalAmount` = `membership.total_amount_cents` ✅ **Inclut T-shirt**
  - [x] `initialAmount` = `membership.total_amount_cents` ✅ **Inclut T-shirt**
  - [x] `items` : Array avec adhésion + T-shirt si présent ✅ **Conforme HelloAsso réel**
  - [x] `itemName` = "Cotisation Adhérent Grenoble Roller [Saison]" ✅ **Corrigé selon HelloAsso réel**
  - [x] `backUrl`, `errorUrl`, `returnUrl` ✅
  - [x] `metadata.membership_id` = ID de l'adhésion ✅
  - [x] `metadata.tshirt_variant_id` = ID du T-shirt si présent ✅ **Ajouté**
- [x] Adapter `fetch_and_update_payment` pour mettre à jour `Membership.status` si payment lié à adhésion ✅
- [x] Helper `membership_checkout_redirect_url` ✅

---

#### **2.2 Controller MembershipsController**

- [x] Créer `app/controllers/memberships_controller.rb` ✅
- [x] `before_action :authenticate_user!` ✅
- [x] `before_action :ensure_email_confirmed, only: [:create, :step2, :step3]` ✅
- [x] Action `choose` :
  - [x] Page de choix T-shirt (Adhésion Simple vs Adhésion + T-shirt) ✅ **Nouvelle fonctionnalité**
  - [x] Gestion paramètre `renew_from` pour renouvellement ✅ **Nouvelle fonctionnalité**
  - [x] Adaptation texte pour renouvellement ✅ **Nouvelle fonctionnalité**
- [x] Action `index` :
  - [x] Liste des adhésions de l'utilisateur (personnelle + enfants) ✅
  - [x] Hero section avec CTA ✅ **Nouvelle fonctionnalité**
  - [x] Sidebar avec actions rapides ✅ **Nouvelle fonctionnalité**
  - [x] Section historique (adhésions expirées) ✅ **Nouvelle fonctionnalité**
  - [x] Paiement groupé enfants ✅ **Nouvelle fonctionnalité**
- [x] Action `new` :
  - [x] Afficher 2 catégories (Standard, FFRS) ✅ **Corrigé selon HelloAsso réel**
  - [x] Afficher dates de saison courante ✅
  - [x] Afficher prix pour chaque catégorie (10€, 56.55€) ✅ **Corrigé**
  - [x] Étape T-shirt (si `with_tshirt=true`) avec choix taille/quantité ✅ **Nouveau système**
  - [x] Ordre inversé : Catégorie d'abord, puis T-shirt ✅ **Nouvelle fonctionnalité**
- [x] Action `step2` (Étape 2) :
  - [x] Formulaire informations adhérent (Prénom, Nom, Date naissance, Téléphone, Email) ✅ **Ajouté pour HelloAsso réel**
  - [x] Pré-remplir depuis User si connecté ✅
- [x] Action `step3` (Étape 3) :
  - [x] Formulaire coordonnées (Adresse, Ville, Code postal) ✅ **Ajouté pour HelloAsso réel**
  - [x] Options (WhatsApp, Emails) ✅ **Ajouté pour HelloAsso réel**
- [x] Action `create` :
  - [x] Récupérer `category` depuis params ✅
  - [x] Récupérer `with_tshirt`, `tshirt_size`, `tshirt_qty` depuis params ✅ **Nouveau système**
  - [x] Récupérer `health_q1` à `health_q9` depuis params ✅ **Questionnaire 9 questions**
  - [x] Gérer upload `medical_certificate` si requis ✅ **Active Storage**
  - [x] Calculer `start_date`, `end_date` via `current_season_dates` ✅
  - [x] Calculer `amount_cents` via `price_for_category` ✅
  - [x] Calculer `total_amount_cents` (adhésion + T-shirt si présent) ✅ **Nouveau système**
  - [x] Mettre à jour User avec informations fournies ✅
  - [x] Mettre à jour User avec `wants_initiation_mail`, `wants_events_mail` ✅ **Nouveaux champs**
  - [x] Créer `Membership` avec `status = "pending"` ✅
  - [x] Créer checkout-intent HelloAsso ✅
  - [x] Créer `Payment` ✅
  - [x] Rediriger vers HelloAsso ✅
  - [x] Gestion erreurs ✅
- [x] Action `pay_multiple` :
  - [x] Payer plusieurs enfants en attente en une seule transaction ✅ **Nouvelle fonctionnalité**
- [x] Action `show` :
  - [x] Afficher détails adhésion ✅
  - [x] Afficher statut ✅
  - [x] Afficher dates ✅
  - [x] Afficher T-shirt si présent ✅ **Ajouté**
  - [x] Bouton "Payer" si pending ✅
  - [x] Bouton "Renouveler" si expired ✅
- [x] Action `pay` :
  - [x] Vérifier statut (doit être pending) ✅
  - [x] Créer nouveau checkout-intent ✅
  - [x] Rediriger vers HelloAsso ✅
- [x] Action `payment_status` :
  - [x] Endpoint JSON pour polling JavaScript ✅
  - [x] Retourner statut du paiement ✅

---

#### **2.3 Routes**

- [x] Ajouter dans `config/routes.rb` :
  ```ruby
  resources :memberships, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
    collection do
      get :choose
      post :pay_multiple
    end
    member do
      post :pay
      get :payment_status
    end
  end
  ```
  ✅ **Routes RESTful complètes + page choose + paiement groupé**
- [x] Vérifier routes avec `bin/rails routes | grep memberships` ✅

---

#### **2.4 Vues**

- [x] `app/views/memberships/index.html.erb` :
  - [x] Hero section avec CTA "Adhérer maintenant" ✅ **Nouvelle fonctionnalité**
  - [x] Sidebar avec actions rapides (Adhérer, Ajouter enfant) ✅ **Nouvelle fonctionnalité**
  - [x] Section "Mes adhésions" avec cartes améliorées ✅ **Nouvelle fonctionnalité**
  - [x] Section historique (adhésions expirées) ✅ **Nouvelle fonctionnalité**
  - [x] Paiement groupé enfants ✅ **Nouvelle fonctionnalité**
  - [x] Affichage : Catégorie, Dates, Statut, Prix ✅
  - [x] Indication T-shirt si présent ✅
  - [x] Bouton "Renouveler" si expired (redirige vers `/memberships/choose`) ✅ **Mis à jour**
- [x] `app/views/memberships/choose.html.erb` :
  - [x] Page de choix T-shirt (2 cartes cliquables) ✅ **Nouvelle fonctionnalité**
  - [x] Adaptation pour renouvellement ✅ **Nouvelle fonctionnalité**
  - [x] Adaptation pour enfants ✅ **Nouvelle fonctionnalité**
- [x] `app/views/memberships/adult_form.html.erb` :
  - [x] Formulaire multi-étapes avec stepper ✅
  - [x] Étape 1 : Catégorie (Standard / FFRS) ✅ **Ordre inversé**
  - [x] Étape 2 : T-shirt (si sélectionné) avec choix taille/quantité ✅ **Ordre inversé**
  - [x] Étape 3 : Informations adhérent ✅
  - [x] Étape 4 : Coordonnées ✅
  - [x] Étape 5 : Consentements + Préférences communication ✅ **wants_initiation_mail, wants_events_mail**
  - [x] Progress bar ✅
- [x] `app/views/memberships/child_form.html.erb` :
  - [x] Formulaire multi-étapes avec stepper ✅
  - [x] Étape 1 : Catégorie (Standard / FFRS) ✅ **Ordre inversé**
  - [x] Étape 2 : T-shirt (si sélectionné) avec choix taille/quantité ✅ **Ordre inversé**
  - [x] Étape 3 : Informations enfant ✅
  - [x] Étape 4 : Autorisation parentale (si < 16 ans) ✅
  - [x] Étape 5 : Questionnaire de santé (9 questions) ✅ **Nouvelle fonctionnalité**
  - [x] Étape 6 : Upload certificat médical (si requis) ✅ **Nouvelle fonctionnalité**
  - [x] Étape 7 : Consentements + Préférences communication ✅ **wants_initiation_mail, wants_events_mail**
  - [x] Pré-remplissage pour renouvellement ✅ **Nouvelle fonctionnalité**
  - [x] Progress bar ✅
- [x] `app/views/memberships/show.html.erb` :
  - [x] Détail adhésion ✅
  - [x] Badge statut (pending/active/expired) ✅
  - [x] Dates adhésion ✅
  - [x] Prix payé ✅
  - [x] Affichage T-shirt si présent ✅ **Ajouté**
  - [x] Bouton "Payer" si pending ✅
  - [x] Bouton "Renouveler" si expired ✅
  - [x] Polling JavaScript si pending (comme pour commandes) ✅
- [x] Polling JavaScript :
  - [x] Vérifier statut toutes les 5 secondes ✅
  - [x] Recharger page si statut changé ✅
  - [x] Max 12 tentatives (1 minute) ✅

---

### **Phase 3 : Automation (1h)**

#### **3.1 Rake Tasks**

- [x] Créer `lib/tasks/memberships.rake` ✅
- [x] Task `memberships:update_expired` :
  - [x] Sélectionner adhésions actives avec `end_date < today` ✅
  - [x] Mettre à jour `status = "expired"` ✅
  - [x] Envoyer email expiration ✅
  - [x] Log résultats ✅
- [x] Task `memberships:send_renewal_reminders` :
  - [x] Sélectionner adhésions actives avec `end_date` dans 30 jours ✅
  - [x] Envoyer email rappel ✅
  - [x] Log résultats ✅
- [x] Task `memberships:check_minor_authorizations` :
  - [x] Vérifier adhésions mineurs sans autorisation ✅
  - [x] Log pour suivi admin ✅
- [x] Task `memberships:check_medical_certificates` :
  - [x] Vérifier adhésions avec `medical_required` sans certificat ✅
  - [x] Log pour suivi admin ✅
- [ ] Task `memberships:prepare_new_season` : ⚠️ **Non implémenté** (peut être ajouté plus tard)

---

#### **3.2 Configuration Cron (Whenever)**

- [x] Mettre à jour `config/schedule.rb` ✅
- [x] `helloasso:sync_payments` : Toutes les 5 minutes ✅ **Déjà présent**
- [x] `memberships:update_expired` : Chaque jour à 00h00 ✅
- [x] `memberships:send_renewal_reminders` : Chaque jour à 09h00 ✅ **Légèrement différent (09h au lieu de 10h)**
- [x] `memberships:check_minor_authorizations` : Tous les lundis à 10h ✅
- [x] `memberships:check_medical_certificates` : Tous les lundis à 10h30 ✅
- [ ] `memberships:prepare_new_season` : 1er septembre à 08h00 ⚠️ **Non implémenté**

---

### **Phase 4 : Admin Dashboard (2h)**

#### **4.1 Controller Admin::MembershipsController**

- [ ] Créer `app/controllers/admin/memberships_controller.rb`
- [ ] `before_action :authenticate_user!`
- [ ] `before_action :ensure_admin!` (vérifier rôle admin)
- [ ] Action `index` :
  - [ ] Statistiques : Actifs, Pending, Expiring, Revenue
  - [ ] Liste filtrable : Statut, Catégorie, Saison
  - [ ] Pagination
- [ ] Action `export` :
  - [ ] Export CSV avec toutes les adhésions
  - [ ] Colonnes : User, Catégorie, Dates, Statut, Paiement

---

#### **4.2 Routes Admin**

- [ ] Ajouter dans `config/routes.rb` :
  ```ruby
  namespace :admin do
    resources :memberships, only: [:index] do
      collection do
        get :export
      end
    end
  end
  ```

---

#### **4.3 Vues Admin**

- [ ] `app/views/admin/memberships/index.html.erb` :
  - [ ] Section Statistiques (cards)
  - [ ] Section Filtres (dropdowns)
  - [ ] Tableau adhésions (triable)
  - [ ] Bouton "Export CSV"
  - [ ] Bouton "Envoyer rappel" (pour expirant)
- [ ] Graphiques (optionnel) :
  - [ ] Répartition par catégorie (pie chart)
  - [ ] Revenue par mois (line chart)

---

### **Phase 5 : Emails (1h)**

#### **5.1 Mailer MembershipMailer**

- [x] Créer `app/mailers/membership_mailer.rb` ✅
- [x] Méthode `activated(membership)` :
  - [x] Sujet : "✅ Adhésion activée - Bienvenue !" ✅
  - [x] Contenu : Dates, accès événements ✅
- [x] Méthode `payment_failed(membership)` :
  - [x] Sujet : "❌ Échec du paiement de votre adhésion" ✅
  - [x] Contenu : Lien pour réessayer ✅
- [x] Méthode `expired(membership)` :
  - [x] Sujet : "⏰ Votre adhésion a expiré" ✅
  - [x] Contenu : Lien pour renouveler ✅
- [x] Méthode `renewal_reminder(membership)` :
  - [x] Sujet : "🔄 Renouvellement d'adhésion - Dans 30 jours" ✅
  - [x] Contenu : Date expiration, lien renouveler ✅
- [ ] Méthode `minor_authorization_missing(membership)` : ⚠️ **Non implémenté** (peut être ajouté plus tard)
- [ ] Méthode `medical_certificate_missing(membership)` : ⚠️ **Non implémenté** (peut être ajouté plus tard)

---

#### **5.2 Templates Emails**

- [x] `app/views/membership_mailer/activated.html.erb` ✅
- [x] `app/views/membership_mailer/activated.text.erb` ✅
- [x] `app/views/membership_mailer/payment_failed.html.erb` ✅
- [x] `app/views/membership_mailer/payment_failed.text.erb` ✅
- [x] `app/views/membership_mailer/expired.html.erb` ✅
- [x] `app/views/membership_mailer/expired.text.erb` ✅
- [x] `app/views/membership_mailer/renewal_reminder.html.erb` ✅
- [x] `app/views/membership_mailer/renewal_reminder.text.erb` ✅
- [ ] Templates pour mineurs ⚠️ **Non implémenté** (peut être ajouté plus tard)

---

### **Phase 6 : Gestion Mineurs (Optionnel - Phase 2)**

#### **6.1 Détection Âge**

- [x] Ajouter méthode `age` dans `User` model ✅
- [x] Calculer à partir de `date_of_birth` ✅
- [x] Méthode `is_minor?` : `age < 18` ✅
- [x] Méthode `is_child?` : `age < 16` ✅

---

#### **6.2 Formulaire Mineurs**

- [x] Formulaire unique pour tous ✅ **Simplifié selon HelloAsso réel** (pas de distinction dans le formulaire)
- [x] Collecter informations parentales si mineur ✅ **Champs présents dans Membership**
- [ ] Formulaire différent si < 16 ans ⚠️ **Non implémenté** (simplifié selon HelloAsso réel)
- [ ] Upload certificat médical ⚠️ **Non implémenté** (peut être ajouté plus tard)

---

#### **6.3 Validations Mineurs**

- [ ] Dans `Membership` model :
  - [ ] Si `is_minor?` : `parent_name`, `parent_email`, `parent_authorization` REQUIRED
  - [ ] Si `health_questionnaire_status == "medical_required"` : `medical_certificate_provided` REQUIRED

---

#### **6.4 Upload Certificat Médical**

- [ ] Ajouter ActiveStorage pour upload fichiers
- [ ] Action `upload_certificate` dans `MembershipsController`
- [ ] Validation : Fichier PDF, taille max, date < 6 mois
- [ ] Stocker URL dans `medical_certificate_url`

---

### **Phase 7 : Testing (1h)**

#### **7.1 Tests Unitaires**

- [ ] Tests `Membership` model :
  - [ ] Validations
  - [ ] Scopes
  - [ ] Méthodes `active?`, `expired?`, `days_until_expiry`
  - [ ] `price_for_category`
  - [ ] `current_season_dates`
- [ ] Tests `User` model :
  - [ ] `has_active_membership?`
  - [ ] `current_membership`

---

#### **7.2 Tests Intégration**

- [ ] Test flux complet :
  - [ ] Créer adhésion (pending)
  - [ ] Créer checkout-intent HelloAsso
  - [ ] Simuler paiement (mock HelloAsso)
  - [ ] Vérifier `status = "active"`
  - [ ] Vérifier email bienvenue envoyé
- [ ] Test renouvellement :
  - [ ] Créer nouvelle adhésion pour même user
  - [ ] Vérifier ancienne adhésion = "expired"
- [ ] Test expiration :
  - [ ] Créer adhésion avec `end_date` passée
  - [ ] Lancer rake task `update_expired`
  - [ ] Vérifier `status = "expired"`
- [ ] Test mineurs :
  - [ ] Créer adhésion enfant < 16 : accord parent requis
  - [ ] Créer adhésion mineur 16-17 : parent informé
  - [ ] Créer adhésion adulte 18+ : autonomous

---

#### **7.3 Tests Sandbox HelloAsso**

- [ ] Tester création checkout-intent en sandbox
- [ ] Tester redirection vers HelloAsso
- [ ] Tester polling après paiement
- [ ] Tester réconciliation paiement

---

### **Phase 8 : Polish & Documentation (30min)**

#### **8.1 Cleanup**

- [ ] Vérifier tous les fichiers créés
- [ ] Refactor si nécessaire
- [ ] Vérifier cohérence avec code existant

---

#### **8.2 Documentation**

- [ ] Mettre à jour README si nécessaire
- [ ] Documenter rake tasks
- [ ] Documenter endpoints API (si nécessaire)

---

### **Phase 9 : Déploiement (30min)**

#### **9.1 Staging**

- [ ] Migration en staging
- [ ] Tests en staging
- [ ] Vérifier cron jobs
- [ ] Tester flux complet en staging

---

#### **9.2 Production**

- [ ] Migration en production
- [ ] Vérifier credentials HelloAsso production
- [ ] Activer cron jobs
- [ ] Monitoring

---

## 📊 RÉCAPITULATIF PAR PHASE

| Phase | Description | Estimation | Priorité |
|-------|-------------|------------|----------|
| **1** | Database & Model | 1h | 🔴 Critique |
| **2** | Flow Adhésion | 2h | 🔴 Critique |
| **3** | Automation | 1h | 🟡 Important |
| **4** | Admin Dashboard | 2h | 🟡 Important |
| **5** | Emails | 1h | 🟡 Important |
| **6** | Gestion Mineurs | 2h | 🟢 Optionnel (Phase 2) |
| **7** | Testing | 1h | 🔴 Critique |
| **8** | Polish & Doc | 30min | 🟡 Important |
| **9** | Déploiement | 30min | 🔴 Critique |

**Total Phase 1-5, 7-9** : ~8h  
**Total avec Phase 6** : ~10h

---

## 🎯 ORDRE D'IMPLÉMENTATION RECOMMANDÉ

### **Sprint 1 : Core (Phases 1-2) - 3h**
- Database, Model, Controller, Routes, Vues basiques
- Flow adhésion fonctionnel (sans mineurs)

### **Sprint 2 : Automation (Phase 3) - 1h**
- Rake tasks
- Cron configuration

### **Sprint 3 : Admin & Emails (Phases 4-5) - 3h**
- Admin dashboard
- Templates emails

### **Sprint 4 : Testing & Deploy (Phases 7-9) - 2h**
- Tests complets
- Déploiement

### **Sprint 5 : Mineurs (Phase 6) - 2h**
- Gestion mineurs (optionnel, peut être fait plus tard)

---

## ✅ CHECKLIST FINALE RAPIDE

### **Core (Minimum Viable)**
- [x] Migration `memberships` ✅
- [x] Model `Membership` avec enums ✅
- [x] Controller `MembershipsController` (new, step2, step3, create, show, index, pay, payment_status) ✅
- [x] Service `HelloassoService.create_membership_checkout_intent` ✅
- [x] Vues basiques (new, step2, step3, show, index) ✅
- [x] Routes ✅
- [x] Polling JavaScript ✅

### **Automation**
- [x] Rake task `update_expired` ✅
- [x] Rake task `send_renewal_reminders` ✅
- [x] Rake task `check_minor_authorizations` ✅
- [x] Rake task `check_medical_certificates` ✅
- [x] Cron configuration ✅

### **Admin**
- [ ] Admin dashboard (statistiques, tableau) ⚠️ **Non implémenté** (prévu pour plus tard)
- [ ] Export CSV ⚠️ **Non implémenté** (prévu pour plus tard)

### **Emails**
- [x] Mailer `MembershipMailer` ✅
- [x] Templates (activated, expired, renewal_reminder, payment_failed) ✅

### **Mineurs (Phase 2)**
- [x] Détection âge ✅
- [x] Formulaire unique pour tous ✅ **Simplifié selon HelloAsso réel**
- [ ] Validations conditionnelles ⚠️ **Non implémenté** (peut être ajouté plus tard)
- [ ] Upload certificat médical ⚠️ **Non implémenté** (peut être ajouté plus tard)

### **Adaptations HelloAsso Réel**
- [x] Catégories corrigées (Standard 10€, FFRS 56.55€) ✅
- [x] Page de choix T-shirt (upsell) ✅ **Nouvelle fonctionnalité**
- [x] T-shirt à 14€ (prix membre) avec choix taille/quantité ✅ **Nouveau système**
- [x] Formulaire multi-étapes avec stepper ✅
- [x] Ordre inversé : Catégorie d'abord, puis T-shirt ✅ **Nouvelle fonctionnalité**
- [x] Champs collectés (Prénom, Nom, Date naissance, Téléphone, Email, Adresse, Ville, Code postal) ✅
- [x] Préférences communication (wants_initiation_mail, wants_events_mail) ✅ **Remplace wants_whatsapp/wants_email_info**
- [x] Questionnaire de santé (9 questions) ✅ **Nouvelle fonctionnalité**
- [x] Upload certificat médical (Active Storage) ✅ **Nouvelle fonctionnalité**
- [x] Gestion enfants simplifiée (ajout un par un) ✅ **Nouvelle fonctionnalité**
- [x] Paiement groupé enfants ✅ **Nouvelle fonctionnalité**
- [x] Renouvellement avec option T-shirt ✅ **Nouvelle fonctionnalité**
- [x] Routes RESTful complètes ✅ **Nouvelle fonctionnalité**
- [x] Fusion pages index/new ✅ **Nouvelle fonctionnalité**
- [x] Progress bar ✅

---

## 🔗 RESSOURCES

### **Documentation**
- Stratégie complète : `docs/09-product/adhesions-strategie-complete.md`
- Législation mineurs : `docs/09-product/adhesions-mineurs-legislation.md` (ancien fichier, à archiver)

### **Code existant à réutiliser**
- `HelloassoService` : Service existant pour commandes
- `Payment` model : Modèle existant
- `OrdersController` : Logique similaire pour adhésions

---

**Note** : Ce plan peut être ajusté selon les priorités. La Phase 6 (Mineurs) peut être reportée à plus tard si nécessaire.

