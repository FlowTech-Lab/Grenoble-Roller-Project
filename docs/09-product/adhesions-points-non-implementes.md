# Adhésions - Points Non Implémentés

**Date** : 2025-01-30  
**Status** : Liste à valider pour suppression ou report

---

## 📋 RÉSUMÉ

**Total points non implémentés** : 12 points

**Catégories** :
- ✅ **Déjà implémenté mais marqué comme non implémenté** : 2 points
- ⚠️ **Optionnel / Peut être ajouté plus tard** : 6 points
- ❌ **Non implémenté (à décider)** : 4 points

---

## ✅ DÉJÀ IMPLÉMENTÉ (À CORRIGER DANS LA DOC)

### **1. ActiveAdmin Dashboard pour Memberships**
- **Status dans doc** : ⚠️ Non implémenté
- **Réalité** : ✅ **DÉJÀ IMPLÉMENTÉ**
- **Fichier** : `app/admin/memberships.rb`
- **Fonctionnalités présentes** :
  - ✅ Liste des adhésions avec filtres
  - ✅ Scopes (Actives, En attente, Expirées, Personnelles, Enfants, Expirent bientôt)
  - ✅ Vue détaillée avec toutes les informations
  - ✅ Formulaire d'édition
  - ✅ Affichage questionnaire de santé
  - ✅ Affichage certificat médical (upload/downloa
d)
- **Action** : ✅ **Corriger la doc** - Marquer comme implémenté

---

### **2. Upload Certificat Médical (Active Storage)**
- **Status dans doc** : ⚠️ Non implémenté
- **Réalité** : ✅ **DÉJÀ IMPLÉMENTÉ**
- **Fichier** : `app/models/membership.rb` ligne 7
- **Fonctionnalités présentes** :
  - ✅ `has_one_attached :medical_certificate` dans Membership
  - ✅ Upload dans le formulaire enfant (`child_form.html.erb`)
  - ✅ Affichage dans ActiveAdmin
  - ✅ Validation conditionnelle (si questionnaire santé = "medical_required")
- **Action** : ✅ **Corriger la doc** - Marquer comme implémenté

---

## ⚠️ OPTIONNEL / PEUT ÊTRE AJOUTÉ PLUS TARD

### **3. Rake Task `memberships:prepare_new_season`**
- **Status** : ⚠️ Non implémenté
- **Description** : Task annuelle pour préparer automatiquement la nouvelle saison (1er septembre)
- **Réalité** : ✅ **PAS NÉCESSAIRE** - Les dates et saisons sont **automatiquement calculées** dans `Membership.current_season_dates` et `Membership.current_season_name`
- **Utilité** : Aucune - Le système calcule automatiquement la saison courante
- **Complexité** : N/A
- **Recommandation** : 🟢 **SUPPRIMER** - Pas nécessaire, tout est automatique

---

### **4. Email `minor_authorization_missing`**
- **Status** : ⚠️ Non implémenté
- **Description** : Email envoyé aux parents si autorisation parentale manquante après 7 jours
- **Réalité** : ✅ **PAS NÉCESSAIRE** - L'autorisation parentale est **automatiquement donnée dans le formulaire d'inscription d'un enfant** (`child_form.html.erb`)
- **Utilité** : Aucune - Le formulaire gère déjà l'autorisation parentale obligatoire pour < 16 ans
- **Complexité** : N/A
- **Recommandation** : 🟢 **SUPPRIMER** - Pas nécessaire, géré dans le formulaire

---

### **5. Email `medical_certificate_missing`**
- **Status** : ⚠️ Non implémenté
- **Description** : Email envoyé si certificat médical requis mais non fourni
- **Réalité** : ✅ **UPLOAD DÉJÀ IMPLÉMENTÉ** - L'upload sécurisé dans Active Storage est **déjà fonctionnel** dans le formulaire (`child_form.html.erb` et `adult_form.html.erb`)
- **Point à réfléchir** : 
  - ✅ Upload sécurisé déjà en place
  - 💡 **NOUVELLE IDÉE** : Vérifier que si pas de licence FFRS (category = "standard"), le questionnaire de santé est obligatoire ?
- **Utilité** : Email de rappel optionnel (mais validation déjà en place dans le formulaire)
- **Complexité** : Faible (1h pour l'email)
- **Recommandation** : 🟡 **REPORTER** - Upload déjà fonctionnel, email de rappel optionnel. **À DISCUTER** : Rendre questionnaire obligatoire pour Standard ?

---

### **6. Templates Emails pour Mineurs**
- **Status** : ⚠️ Non implémenté
- **Description** : Templates d'emails spécifiques pour les mineurs (différents de ceux des adultes)
- **Réalité** : ✅ **PAS NÉCESSAIRE** - C'est le **parent qui inscrit son enfant**, donc les emails sont envoyés au parent (pas à l'enfant)
- **Utilité** : Aucune - Les emails sont déjà adaptés (envoyés au parent)
- **Complexité** : N/A
- **Recommandation** : 🟢 **SUPPRIMER** - Pas nécessaire, les emails sont déjà envoyés aux bons destinataires (parents)

---

### **7. Validations Conditionnelles selon Âge**
- **Status** : ⚠️ Partiellement implémenté
- **Description** : Validations automatiques selon l'âge (ex: parent_authorization REQUIRED si < 16)
- **Réalité** : ✅ **DÉJÀ IMPLÉMENTÉ** - `validates :parent_authorization, inclusion: { in: [true] }, if: -> { is_child_membership? && child_age < 16 }`
- **Clarification** : Les validations conditionnelles sont déjà en place. L'utilisateur demande clarification.
- **Utilité** : Déjà fonctionnel
- **Complexité** : N/A
- **Recommandation** : ✅ **DÉJÀ FAIT** - Les validations conditionnelles sont déjà implémentées

---

### **8. Export CSV des Adhésions**
- **Status** : ⚠️ Non implémenté (prévu pour plus tard)
- **Description** : Export CSV de toutes les adhésions pour statistiques/courrier
- **Réalité** : ✅ **DÉJÀ DISPONIBLE** - ActiveAdmin permet **l'export CSV par défaut** (bouton "Export" dans l'interface)
- **Utilité** : Déjà fonctionnel via ActiveAdmin
- **Complexité** : N/A
- **Recommandation** : ✅ **DÉJÀ FAIT** - L'export CSV est disponible dans ActiveAdmin

---

## ❌ NON IMPLÉMENTÉ (À DÉCIDER)

### **9. Tests Unitaires et Intégration**
- **Status** : ⚠️ Non implémenté (Phase 7)
- **Description** : Tests complets pour Membership, User, flux complet, renouvellement, expiration
- **Utilité** : Assurance qualité, prévention de régressions
- **Complexité** : Élevée (8h)
- **Recommandation** : 🟡 **À PRÉVOIR** - Important mais peut être fait progressivement

---

### **10. Tests Sandbox HelloAsso**
- **Status** : ⚠️ À tester manuellement
- **Description** : Tests en conditions réelles avec HelloAsso sandbox
- **Utilité** : Validation du flux complet de paiement
- **Complexité** : Faible (2h)
- **Recommandation** : 🟡 **À PRÉVOIR** - À faire avant mise en production

---

### **11. Graphiques Dashboard Admin**
- **Status** : ⚠️ Non implémenté (optionnel)
- **Description** : Graphiques (pie chart répartition catégories, line chart revenue par mois)
- **Utilité** : Visualisation des statistiques
- **Complexité** : Moyenne (4h)
- **Recommandation** : 🟢 **SUPPRIMER** - Optionnel, peut être ajouté plus tard si vraiment nécessaire

---

## 📊 RÉCAPITULATIF PAR RECOMMANDATION

### ✅ **À CORRIGER DANS LA DOC** (5 points)
1. ActiveAdmin Dashboard pour Memberships
2. Upload Certificat Médical (Active Storage)
3. Validations Conditionnelles selon Âge (déjà implémenté)
4. Export CSV des Adhésions (déjà disponible dans ActiveAdmin)
5. Rake Task `prepare_new_season` (pas nécessaire, calcul automatique)

### 🟡 **À PRÉVOIR / REPORTER** (2 points)
1. Email `medical_certificate_missing` (optionnel, upload déjà fonctionnel)
   - 💡 **À DISCUTER** : Rendre questionnaire obligatoire pour Standard (sans FFRS) ?
2. Tests Unitaires et Intégration (à prévoir)
3. Tests Sandbox HelloAsso (à prévoir avant production)

### 🟢 **SUPPRIMER** (4 points)
1. Rake Task `memberships:prepare_new_season` (pas nécessaire, calcul automatique)
2. Email `minor_authorization_missing` (pas nécessaire, géré dans formulaire)
3. Templates Emails pour Mineurs (pas nécessaire, emails déjà envoyés aux parents)
4. Graphiques Dashboard Admin (optionnel, peut être ajouté plus tard)

---

## 🎯 ACTIONS RECOMMANDÉES

### **Immédiat**
1. ✅ Corriger la doc pour les 5 points déjà implémentés :
   - ActiveAdmin Dashboard
   - Upload Certificat Médical
   - Validations Conditionnelles
   - Export CSV
   - Calcul automatique saisons
2. 🟢 Supprimer les 4 points non pertinents de la doc

### **Court terme (1-2 mois)**
1. 🟡 **À DISCUTER** : Rendre questionnaire de santé obligatoire pour Standard (sans FFRS) ?
2. 🟡 Ajouter email `medical_certificate_missing` (optionnel, upload déjà fonctionnel)

### **Moyen terme (3-6 mois)**
1. 🟡 Écrire les tests unitaires et intégration

### **Avant production**
1. 🟡 Tests Sandbox HelloAsso complets

---

## 📝 NOTES

- **ActiveAdmin** : Déjà complètement fonctionnel, juste besoin de corriger la doc
- **Upload Certificat** : Déjà implémenté avec Active Storage, juste besoin de corriger la doc
- **Calcul Saisons** : Automatique via `current_season_dates` et `current_season_name`, pas besoin de rake task
- **Autorisation Parentale** : Gérée automatiquement dans le formulaire enfant, pas besoin d'email séparé
- **Emails Mineurs** : Les emails sont déjà envoyés aux parents (pas aux enfants), pas besoin de templates séparés
- **Export CSV** : Disponible par défaut dans ActiveAdmin
- **Validations Conditionnelles** : Déjà implémentées dans le modèle Membership
- **Questionnaire Santé** : 💡 **IDÉE À DISCUTER** : Rendre obligatoire pour Standard (sans FFRS) ?
- **Graphiques** : Optionnel, peut être ajouté plus tard si vraiment nécessaire
- **Tests** : Important mais peut être fait progressivement

---

**Date de création** : 2025-01-30  
**Dernière mise à jour** : 2025-01-30

