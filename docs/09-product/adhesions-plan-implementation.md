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

- [ ] Créer migration `create_memberships`
- [ ] Champs principaux :
  - [ ] `user_id` (references, null: false)
  - [ ] `category` (integer, null: false) - enum
  - [ ] `status` (integer, null: false, default: 0) - enum
  - [ ] `start_date` (date, null: false)
  - [ ] `end_date` (date, null: false)
  - [ ] `amount_cents` (integer, null: false)
  - [ ] `currency` (string, default: "EUR")
  - [ ] `season` (string) - ex: "2025-2026"
  - [ ] `payment_id` (references, null: true)
  - [ ] `provider_order_id` (string)
  - [ ] `metadata` (jsonb)
- [ ] Champs mineurs (optionnels pour Phase 1) :
  - [ ] `is_minor` (boolean)
  - [ ] `parent_name` (string)
  - [ ] `parent_email` (string)
  - [ ] `parent_phone` (string)
  - [ ] `parent_authorization` (boolean)
  - [ ] `parent_authorization_date` (date)
  - [ ] `health_questionnaire_status` (string)
  - [ ] `medical_certificate_provided` (boolean)
  - [ ] `medical_certificate_url` (string)
  - [ ] `emergency_contact_name` (string)
  - [ ] `emergency_contact_phone` (string)
  - [ ] `rgpd_consent` (boolean)
  - [ ] `ffrs_data_sharing_consent` (boolean)
  - [ ] `legal_notices_accepted` (boolean)
- [ ] Index :
  - [ ] `add_index :memberships, [:user_id, :status]`
  - [ ] `add_index :memberships, [:user_id, :season]`
  - [ ] `add_index :memberships, [:status, :end_date]`
  - [ ] `add_index :memberships, :provider_order_id`
- [ ] Validation unique : `user_id + season`
- [ ] Tester migration en développement

---

#### **1.2 Model Membership**

- [ ] Créer `app/models/membership.rb`
- [ ] Relations :
  - [ ] `belongs_to :user`
  - [ ] `belongs_to :payment, optional: true`
- [ ] Enums :
  - [ ] `enum status: { pending: 0, active: 1, expired: 2 }`
  - [ ] `enum category: { adult: 0, student: 1, family: 2 }`
- [ ] Scopes :
  - [ ] `scope :active_now` : `active.where("end_date > ?", Date.current)`
  - [ ] `scope :expiring_soon` : `active.where("end_date BETWEEN ? AND ?", Date.current, 7.days.from_now)`
  - [ ] `scope :pending_payment` : `pending`
- [ ] Méthodes :
  - [ ] `active?` : Vérifier si active (status = "active" ET end_date > today)
  - [ ] `expired?` : Vérifier si expirée (end_date <= today)
  - [ ] `days_until_expiry` : Calculer jours restants
  - [ ] `self.price_for_category(category)` : Retourner prix en centimes
  - [ ] `self.current_season_dates` : Retourner [start_date, end_date]
- [ ] Validations :
  - [ ] `validates :user_id, uniqueness: { scope: :season }`
  - [ ] `validates :start_date, :end_date, :amount_cents, presence: true`
- [ ] Tests unitaires du modèle

---

#### **1.3 Update User Model**

- [ ] Ajouter relation `has_many :memberships, dependent: :destroy`
- [ ] Helpers :
  - [ ] `has_active_membership?` : Vérifier si adhésion active
  - [ ] `current_membership` : Retourner adhésion active actuelle
- [ ] Champs à ajouter (si manquants) :
  - [ ] Migration `add_date_of_birth_to_users` (date)
  - [ ] Migration `add_address_fields_to_users` (address, postal_code, city)
- [ ] Tests unitaires

---

#### **1.4 Update Payment Model**

- [ ] Ajouter relation `has_one :membership`
- [ ] Vérifier que `Payment` peut être lié soit à `Order`, soit à `Membership`
- [ ] Tests unitaires

---

### **Phase 2 : Flow Adhésion (2h)**

#### **2.1 Service HelloassoService**

- [ ] Créer méthode `create_membership_checkout(membership, back_url:, error_url:, return_url:)`
- [ ] Créer méthode `build_membership_checkout_payload(membership, back_url:, error_url:, return_url:)`
- [ ] Payload :
  - [ ] `totalAmount` = `membership.amount_cents`
  - [ ] `initialAmount` = `membership.amount_cents`
  - [ ] `itemName` = "Adhésion [Catégorie] Saison [Année]"
  - [ ] `backUrl`, `errorUrl`, `returnUrl`
  - [ ] `containsDonation` = false
  - [ ] `metadata.membership_id` = ID de l'adhésion
- [ ] Adapter `fetch_and_update_payment` pour mettre à jour `Membership.status` si payment lié à adhésion
- [ ] Tests en sandbox HelloAsso

---

#### **2.2 Controller MembershipsController**

- [ ] Créer `app/controllers/memberships_controller.rb`
- [ ] `before_action :authenticate_user!`
- [ ] `before_action :ensure_email_confirmed, only: [:create]`
- [ ] Action `index` :
  - [ ] Liste des adhésions de l'utilisateur
  - [ ] Ordre : `created_at: :desc`
- [ ] Action `new` :
  - [ ] Afficher 3 catégories (Adulte, Étudiant, Famille)
  - [ ] Afficher dates de saison courante
  - [ ] Afficher prix pour chaque catégorie
- [ ] Action `create` :
  - [ ] Récupérer `category` depuis params
  - [ ] Calculer `start_date`, `end_date` via `current_season_dates`
  - [ ] Calculer `amount_cents` via `price_for_category`
  - [ ] Créer `Membership` avec `status = "pending"`
  - [ ] Créer checkout-intent HelloAsso
  - [ ] Créer `Payment`
  - [ ] Rediriger vers HelloAsso
  - [ ] Gestion erreurs
- [ ] Action `show` :
  - [ ] Afficher détails adhésion
  - [ ] Afficher statut
  - [ ] Afficher dates
  - [ ] Bouton "Payer" si pending
  - [ ] Bouton "Renouveler" si expired
- [ ] Action `pay` :
  - [ ] Vérifier statut (doit être pending)
  - [ ] Créer nouveau checkout-intent
  - [ ] Rediriger vers HelloAsso
- [ ] Action `payment_status` :
  - [ ] Endpoint JSON pour polling JavaScript
  - [ ] Retourner statut du paiement
- [ ] Tests du controller

---

#### **2.3 Routes**

- [ ] Ajouter dans `config/routes.rb` :
  ```ruby
  resources :memberships, only: [:index, :new, :create, :show] do
    member do
      post :pay
      get :payment_status
    end
  end
  ```
- [ ] Vérifier routes avec `bin/rails routes | grep memberships`

---

#### **2.4 Vues**

- [ ] `app/views/memberships/index.html.erb` :
  - [ ] Liste historique des adhésions
  - [ ] Affichage : Catégorie, Dates, Statut, Prix
  - [ ] Bouton "Renouveler" si expired
- [ ] `app/views/memberships/new.html.erb` :
  - [ ] 3 cards (Adulte / Étudiant / Famille)
  - [ ] Chaque card affiche : Prix, Dates validité, Bouton "Adhérer"
  - [ ] Formulaire avec champs obligatoires (si pas déjà dans User)
  - [ ] Checkboxes d'acceptation (CGU, RGPD, attestation aptitude)
- [ ] `app/views/memberships/show.html.erb` :
  - [ ] Détail adhésion
  - [ ] Badge statut (pending/active/expired)
  - [ ] Dates adhésion
  - [ ] Prix payé
  - [ ] Bouton "Payer" si pending
  - [ ] Bouton "Renouveler" si expired
  - [ ] Polling JavaScript si pending (comme pour commandes)
- [ ] Polling JavaScript :
  - [ ] Vérifier statut toutes les 5 secondes
  - [ ] Recharger page si statut changé
  - [ ] Max 12 tentatives (1 minute)

---

### **Phase 3 : Automation (1h)**

#### **3.1 Rake Tasks**

- [ ] Créer `lib/tasks/memberships.rake`
- [ ] Task `memberships:update_expired` :
  - [ ] Sélectionner adhésions actives avec `end_date < today`
  - [ ] Mettre à jour `status = "expired"`
  - [ ] Envoyer email expiration
  - [ ] Log résultats
- [ ] Task `memberships:send_renewal_reminders` :
  - [ ] Sélectionner adhésions actives avec `end_date` dans 30 jours
  - [ ] Envoyer email rappel
  - [ ] Log résultats
- [ ] Task `memberships:check_minor_authorizations` :
  - [ ] Vérifier adhésions mineurs sans autorisation après 7 jours
  - [ ] Envoyer email rappel
  - [ ] Après 14 jours : `status = "expired"`
- [ ] Task `memberships:check_medical_certificates` :
  - [ ] Vérifier adhésions avec `medical_required` sans certificat
  - [ ] Envoyer email rappel
- [ ] Task `memberships:prepare_new_season` :
  - [ ] Calculer nouvelle saison
  - [ ] Activer `/memberships/new`
  - [ ] Envoyer email à tous "Nouvelle saison ouverte"

---

#### **3.2 Configuration Cron (Whenever)**

- [ ] Mettre à jour `config/schedule.rb`
- [ ] `helloasso:sync_payments` : Toutes les 5 minutes
- [ ] `memberships:update_expired` : Chaque jour à 00h00
- [ ] `memberships:send_renewal_reminders` : Chaque jour à 10h00
- [ ] `memberships:check_minor_authorizations` : Chaque jour à 09h00
- [ ] `memberships:check_medical_certificates` : Chaque jour à 09h00
- [ ] `memberships:prepare_new_season` : 1er septembre à 08h00
- [ ] Tester cron en développement

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

- [ ] Créer `app/mailers/membership_mailer.rb`
- [ ] Méthode `membership_activated(membership)` :
  - [ ] Sujet : "✅ Adhésion activée - Bienvenue !"
  - [ ] Contenu : Dates, accès événements
- [ ] Méthode `membership_payment_failed(membership)` :
  - [ ] Sujet : "❌ Échec du paiement de votre adhésion"
  - [ ] Contenu : Lien pour réessayer
- [ ] Méthode `membership_expired(membership)` :
  - [ ] Sujet : "⏰ Votre adhésion a expiré"
  - [ ] Contenu : Lien pour renouveler
- [ ] Méthode `membership_renewal_reminder(membership)` :
  - [ ] Sujet : "🔄 Renouvelez votre adhésion - Expiration dans 30 jours"
  - [ ] Contenu : Date expiration, lien renouveler
- [ ] Méthode `minor_authorization_missing(membership)` :
  - [ ] Sujet : "⚠️ Autorisation parentale manquante"
  - [ ] Contenu : Lien pour autoriser
- [ ] Méthode `medical_certificate_missing(membership)` :
  - [ ] Sujet : "⚠️ Certificat médical manquant"
  - [ ] Contenu : Lien pour uploader

---

#### **5.2 Templates Emails**

- [ ] `app/views/membership_mailer/membership_activated.html.erb`
- [ ] `app/views/membership_mailer/membership_payment_failed.html.erb`
- [ ] `app/views/membership_mailer/membership_expired.html.erb`
- [ ] `app/views/membership_mailer/membership_renewal_reminder.html.erb`
- [ ] `app/views/membership_mailer/minor_authorization_missing.html.erb`
- [ ] `app/views/membership_mailer/medical_certificate_missing.html.erb`
- [ ] Templates avec design cohérent (Bootstrap)

---

### **Phase 6 : Gestion Mineurs (Optionnel - Phase 2)**

#### **6.1 Détection Âge**

- [ ] Ajouter méthode `age` dans `User` model
- [ ] Calculer à partir de `date_of_birth`
- [ ] Méthode `is_minor?` : `age < 18`
- [ ] Méthode `is_child?` : `age < 16`

---

#### **6.2 Formulaire Mineurs**

- [ ] Adapter `memberships/new.html.erb` :
  - [ ] Détecter si user est mineur
  - [ ] Afficher formulaire différent si < 16 ans
  - [ ] Collecter email parent obligatoire si < 18 ans
  - [ ] Checkbox autorisation parentale si < 16 ans
  - [ ] Question santé : "Problèmes de santé ?"
  - [ ] Upload certificat médical si nécessaire

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
- [ ] Migration `memberships`
- [ ] Model `Membership` avec enums
- [ ] Controller `MembershipsController` (new, create, show, index)
- [ ] Service `HelloassoService.create_membership_checkout`
- [ ] Vues basiques (new, show, index)
- [ ] Routes
- [ ] Polling JavaScript

### **Automation**
- [ ] Rake task `update_expired`
- [ ] Rake task `send_renewal_reminders`
- [ ] Cron configuration

### **Admin**
- [ ] Admin dashboard (statistiques, tableau)
- [ ] Export CSV

### **Emails**
- [ ] Mailer `MembershipMailer`
- [ ] Templates (activated, expired, renewal_reminder)

### **Mineurs (Phase 2)**
- [ ] Détection âge
- [ ] Formulaire mineurs
- [ ] Validations
- [ ] Upload certificat médical

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

