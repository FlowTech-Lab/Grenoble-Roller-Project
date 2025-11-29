# Adhésions - Écarts entre Doc et Formulaire HelloAsso Réel

**Date** : 2025-01-29  
**Status** : ✅ **Corrections appliquées**

---

## 📋 RÉSUMÉ DES ÉCARTS IDENTIFIÉS

### ❌ **1. Formulaire Multi-Étapes (Non prévu)**

**HelloAsso Réel** :
- Étape 1 : "Choix de l'adhésion" (avec options T-shirt)
- Étape 2 : "Adhérents" (formulaire complet)
- Étape 3 : "Coordonnées" (adresse, etc.)
- Étape 4 : "Récapitulatif"

**Doc Actuelle** :
- Formulaire simple en une seule page (`/memberships/new`)
- Pas de gestion multi-étapes

**Action** : Adapter le formulaire pour suivre le flux HelloAsso réel

---

### ❌ **2. Champs Manquants dans User**

**HelloAsso Réel collecte** :
- ✅ Prénom (déjà dans User)
- ✅ Nom (déjà dans User)
- ✅ Date de naissance (à ajouter - migration déjà créée)
- ✅ Numéro téléphone (à vérifier si présent)
- ✅ Email (déjà dans User)
- ✅ Adresse (à ajouter - migration déjà créée)
- ✅ Ville (à ajouter - migration déjà créée)
- ✅ Code postal (à ajouter - migration déjà créée)

**Options supplémentaires** :
- ☑️ "Je souhaite rejoindre la communauté WhatsApp"
- ☑️ "Réception de mail d'information (rando/initiation) ou d'évènement Grenoble Roller"

**Action** : 
- Vérifier si `phone` existe dans User
- Ajouter champs `wants_whatsapp` et `wants_email_info` dans User ou Membership

---

### ❌ **3. T-shirt à 14€ avec Tailles (Non prévu)**

**HelloAsso Réel** :
- Option : "T-shirt Grenoble Roller : 14 €"
- Choix de taille nécessaire
- Prix fixe : 14€ (1400 centimes)

**Shop Actuel** :
- T-shirt existe déjà dans le shop avec variantes de taille
- Prix peut être différent de 14€

**Action** :
- Ajouter option T-shirt dans le formulaire d'adhésion
- Lier au produit T-shirt du shop
- Permettre choix de taille
- Ajouter 14€ au montant total de l'adhésion
- Créer un `OrderItem` pour le T-shirt lors de la création de l'adhésion

---

### ❌ **4. Flux Mineurs Non Conforme**

**HelloAsso Réel** :
- Formulaire unique pour tous (pas de distinction mineur/adulte dans le formulaire)
- Les champs sont les mêmes pour tous
- Pas de formulaire séparé pour les parents

**Doc Actuelle** :
- Flux différent pour < 16 ans, 16-17 ans, 18+
- Formulaires séparés
- Collecte email parent obligatoire

**Action** :
- Simplifier le flux : formulaire unique
- Collecter les informations parentales dans les champs de la membership si mineur
- Adapter la validation selon l'âge

---

### ❌ **5. Catégories d'Adhésion Différentes**

**HelloAsso Réel** :
- "Cotisation Adhérent Grenoble Roller" : 10€
- "Cotisation Adhérent Grenoble Roller + Licence FFRS" : 56.55€

**Doc Actuelle** :
- Adulte : 50€
- Étudiant : 25€
- Famille : 80€

**Action** :
- Adapter les catégories et prix selon HelloAsso réel
- Ajouter catégorie "FFRS" pour la licence

---

## 🔧 CORRECTIONS À APPORTER

### **1. Migration User - Champs Manquants**

```ruby
# Migration déjà créée : AddPersonalFieldsToUsers
# Vérifier si phone existe, sinon ajouter
# Ajouter :
- wants_whatsapp (boolean, default: false)
- wants_email_info (boolean, default: true)
```

### **2. Migration Membership - T-shirt**

```ruby
# Ajouter :
- tshirt_variant_id (references product_variants, null: true)
- tshirt_price_cents (integer, default: 1400) # 14€
```

### **3. Modèle Membership - Catégories**

```ruby
enum :category, {
  standard: 0,    # 10€ - Cotisation Adhérent Grenoble Roller
  with_ffrs: 1    # 56.55€ - Cotisation + Licence FFRS
}
```

### **4. Controller - Formulaire Multi-Étapes**

Adapter `MembershipsController` pour gérer :
- Étape 1 : Choix catégorie + T-shirt (optionnel)
- Étape 2 : Informations adhérent (pré-remplir depuis User si connecté)
- Étape 3 : Coordonnées (adresse, etc.)
- Étape 4 : Récapitulatif + Paiement

### **5. Vue - Formulaire Multi-Étapes**

Créer un formulaire avec :
- Progress bar (comme HelloAsso)
- Étapes séparées
- Validation par étape
- Sauvegarde temporaire (session ou draft)

### **6. Service HelloAsso - T-shirt dans Checkout**

Adapter `create_membership_checkout_intent` pour inclure :
- Item 1 : Adhésion (10€ ou 56.55€)
- Item 2 : T-shirt (14€) si sélectionné

---

## 📊 STRUCTURE PROPOSÉE

### **Table `memberships` - Champs à ajouter**

```ruby
# T-shirt
t.references :tshirt_variant, foreign_key: { to_table: :product_variants }, null: true
t.integer :tshirt_price_cents, default: 1400

# Options
t.boolean :wants_whatsapp, default: false
t.boolean :wants_email_info, default: true
```

### **Table `users` - Champs à ajouter**

```ruby
# Déjà prévu dans migration AddPersonalFieldsToUsers :
t.date :date_of_birth
t.string :address
t.string :postal_code
t.string :city

# À ajouter :
t.boolean :wants_whatsapp, default: false
t.boolean :wants_email_info, default: true
```

### **Prix Adhésions**

```ruby
def self.price_for_category(category)
  case category.to_s
  when 'standard' then 1000      # 10€ en centimes
  when 'with_ffrs' then 5655     # 56.55€ en centimes
  else 0
  end
end
```

---

## 🎯 PLAN D'ACTION

### **Phase 1 : Corrections Urgentes (2h)**

1. ✅ Migration User (déjà créée)
2. ⏳ Migration Membership (ajouter T-shirt)
3. ⏳ Modifier catégories et prix
4. ⏳ Adapter formulaire pour collecter tous les champs
5. ⏳ Ajouter option T-shirt avec choix de taille

### **Phase 2 : Formulaire Multi-Étapes (2h)**

1. ⏳ Créer système d'étapes
2. ⏳ Progress bar
3. ⏳ Validation par étape
4. ⏳ Sauvegarde temporaire

### **Phase 3 : Flux Mineurs Simplifié (1h)**

1. ⏳ Formulaire unique pour tous
2. ⏳ Collecte infos parentales si mineur
3. ⏳ Validation selon âge

---

## ✅ CHECKLIST CORRECTIONS

- [x] Migration User : Vérifier `phone`, ajouter `wants_whatsapp`, `wants_email_info` ✅
- [x] Migration Membership : Ajouter `tshirt_variant_id`, `tshirt_price_cents` ✅
- [x] Modèle Membership : Changer catégories (standard, with_ffrs) et prix ✅
- [x] Controller : Adapter pour formulaire multi-étapes ✅
- [x] Vue : Créer formulaire avec progress bar et étapes ✅
- [x] Service HelloAsso : Inclure T-shirt dans checkout-intent ✅
- [x] Flux mineurs : Simplifier (formulaire unique) ✅
- [ ] Tests : Vérifier nouveau flux complet ⚠️ **À tester manuellement**

---

**Note** : Ce document doit être mis à jour après chaque correction.

