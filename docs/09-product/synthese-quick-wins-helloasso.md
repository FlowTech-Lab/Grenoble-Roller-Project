---
title: "Synthèse Quick Wins & Intégration Hello Asso"
status: "active"
version: "1.1"
created: "2025-01-20"
updated: "2025-01-20"
tags: ["product", "quick-wins", "helloasso", "boutique", "paiement"]
---

# Synthèse Quick Wins & Intégration Hello Asso

**Objectif** : Documenter l'état actuel et les actions à mener pour finaliser les quick wins et l'intégration Hello Asso pour la boutique.

---

## 📊 ÉTAT ACTUEL - QUICK WINS

### ✅ **Quick Wins Terminés (9/38 - 24%)**

#### Parcours 1 : Découverte de l'Association
- [x] **Section "À propos" sur homepage** ✅
  - Section "Pourquoi nous rejoindre ?" + lien vers `/a-propos`
  - Bloc "Chiffres clés" (4 stats) sur homepage et `/a-propos`
- [x] **Bouton "Adhérer" plus clair** ✅
  - Texte changé pour non connecté : "S'inscrire pour adhérer"
- [x] **Compteur social proof** ✅
  - Bloc "Chiffres clés" avec 4 statistiques

#### Parcours 2 : Inscription
- [x] **Astérisques champs obligatoires** ✅
  - Classe `.required` sur labels + légende "Champs obligatoires" avec `*`
- [x] **Améliorer messages d'erreur Devise** ✅
  - `devise.fr.yml` créé avec toutes les traductions
- [x] **Message de bienvenue après inscription** ✅
  - Implémenté dans `RegistrationsController`
- [x] **Indicateur de force du mot de passe** ✅
  - Ajouté au formulaire d'inscription (2025-11-24)

#### Parcours 3 : Découverte des Événements
- [x] **Badge "Nouveau" sur événements** ✅
  - Méthode `recent?` (7 derniers jours) + badge `badge-liquid-success`
- [x] **Compteur d'événements à venir** ✅
  - Compteur en haut de `events/index.html.erb`
- [x] **Refactorisation highlighted_event** ✅
  - Badge "Prochain" aligné avec badge de date, grille Bootstrap fonctionnelle

#### Parcours 8 : Administration
- [x] **Dashboard avec statistiques basiques** ✅
  - Cards avec compteurs : Événements, Utilisateurs, Commandes, Revenus, Boutique
- [x] **Actions rapides dans liste Events** ✅
  - Boutons "Refuser", "Voir", "Accepter" dans colonne Actions
- [x] **Vue "À valider" améliorée** ✅
  - Panel dédié sur dashboard avec liste

#### Parcours 9 : Navigation via Footer
- [x] **Corriger liens existants** ✅
  - "À propos" → `/a-propos`, "Événements" → `/events`, "Créer événement" → `/events/new`
- [🟡] **Masquer sections non implémentées** 🟡 PARTIELLEMENT
  - Contact/CGU/Confidentialité toujours vers `#` (à masquer complètement)

---

### ⏳ **Quick Wins Restants (30/38 - 79%)**

#### Parcours 3 : Découverte des Événements
- [ ] Améliorer troncature lieu (Augmenter à 50 caractères ou afficher sur 2 lignes)
- [ ] Lien "Voir tous les événements passés" (Si >6 événements passés)

#### Parcours 4 : Inscription à un Événement
- [ ] Ajouter résumé dans modal (Afficher date, heure, lieu avant confirmation)
- [ ] Message de succès personnalisé ("Inscription confirmée ! À bientôt le [date] à [heure]")
- [ ] Indicateur de chargement (Spinner/loader pendant soumission)
- [ ] Alerte "Presque complet" (Si ≤5 places, alerte dans la modal)

#### Parcours 5 : Gestion de Mes Inscriptions
- [ ] Séparer événements à venir et passés (Section "À venir" et "Passés" avec compteurs)
- [ ] Badge "Passé" (Badge distinctif pour les événements passés)
- [ ] Indicateur rappel dans la liste (Badge "Rappel activé" / "Rappel désactivé" sur chaque card)
- [ ] Compteur d'inscriptions ("X sorties à venir" visible en haut)

#### Parcours 6 : Création d'un Événement
- [ ] Sauvegarde automatique (localStorage) (Sauvegarder les champs pendant la saisie)
- [ ] Validation en temps réel (Vérifier les champs au blur)
- [ ] Indicateur de progression (Barre "Étape 1/1" ou compteur de champs remplis)
- [ ] Message de confirmation avant soumission ("Votre événement sera en attente de validation. Continuer ?")

#### Parcours 7 : Achat en Boutique ⚠️ **PRIORITÉ BOUTIQUE**
- [x] **Message "Article ajouté" plus visible** (Toast/notification persistante) ✅ **TERMINÉ** (2025-01-20)
  - Toast vert (success) avec nom du produit
  - Bouton "Voir le panier" dans le toast
  - Redirection vers boutique après ajout (logique améliorée)
- [ ] **Zoom sur image produit** (Lightbox pour agrandir l'image au clic) ⚠️ **PRIORITÉ MOYENNE**
- [ ] ~~**Améliorer image par défaut**~~ ✅ **DÉJÀ GÉRÉ** - Image obligatoire à la création (validation `presence: true`)
- [ ] ~~**Filtres par catégories**~~ ❌ **DÉPRIORISÉ** - Peu de produits (~6-7), pas nécessaire
- [ ] ~~**Barre de recherche**~~ ❌ **DÉPRIORISÉ** - Peu de produits (~6-7), pas nécessaire

#### Parcours 8 : Administration
- [ ] Exports CSV basiques (Bouton "Exporter CSV" sur chaque resource - ActiveAdmin natif)

#### Parcours 9 : Navigation via Footer
- [ ] ⚠️ **URGENT : Masquer temporairement sections non implémentées** (Liens Contact/CGU/Confidentialité toujours vers `#`)
- [ ] Désactiver newsletter temporairement (Masquer ou message "Bientôt disponible")

---

## 🛒 ÉTAT ACTUEL - INTÉGRATION HELLO ASSO

### ✅ **Ce qui est déjà en place**

#### 1. **Structure Base de Données**
- ✅ Table `payments` créée avec colonne `provider` (stripe, helloasso, free)
- ✅ Modèle `Payment` avec associations (`has_many :orders`, `has_many :attendances`)
- ✅ Modèle `Order` avec `belongs_to :payment, optional: true` (prêt pour Hello Asso)
- ✅ Migration `20251104110828_create_payments.rb` appliquée

#### 2. **Interface Utilisateur**
- ✅ Page checkout (`app/views/orders/new.html.erb`) avec :
  - Bouton "Payer Via HelloAsso*"
  - Section don (2€, 3€, 5€, montant personnalisé)
  - Info box HelloAsso expliquant le service
  - Calcul dynamique du total avec don (JavaScript)
- ✅ Styles CSS pour `.helloasso-info` (mode clair/sombre)

#### 3. **Contrôleur Orders**
- ✅ `OrdersController#create` crée la commande avec statut "pending"
- ✅ Gestion du stock (déduction automatique)
- ✅ Validation du stock avant création
- ⚠️ **MANQUE** : Intégration Hello Asso après création de la commande

#### 4. **Pages Légales**
- ✅ CGV mentionnent HelloAsso comme mode de paiement
- ✅ Politique de confidentialité mentionne HelloAsso comme sous-traitant
- ✅ Mentions légales conformes

#### 5. **Documentation**
- ✅ Guide technique (`docs/02-shape-up/technical-implementation-guide.md`) avec exemple de service HelloAsso
- ✅ Credentials Rails configurés (structure prête pour `helloasso_token`)

---

### ❌ **Ce qui manque pour finaliser l'intégration**

#### 1. **Service Hello Asso** ⚠️ **CRITIQUE**
- ❌ Pas de service `HelloassoService` créé
- ❌ Pas d'intégration API Hello Asso
- ❌ Pas de gestion des webhooks Hello Asso

**Fichier à créer** : `app/services/helloasso_service.rb`

**Structure attendue** (basée sur la doc technique) :
```ruby
# app/services/helloasso_service.rb
class HelloassoService
  include HTTParty
  base_uri 'https://api.helloasso.com/v5'
  
  def initialize
    @headers = {
      'Authorization' => "Bearer #{Rails.application.credentials.dig(:helloasso, :token)}",
      'Content-Type' => 'application/json'
    }
  end
  
  def create_order(order_data)
    # Créer une commande Hello Asso
  end
  
  def get_order_status(order_id)
    # Récupérer le statut d'une commande
  end
end
```

#### 2. **Modification OrdersController#create** ⚠️ **CRITIQUE**
- ❌ Pas de création de `Payment` après création de `Order`
- ❌ Pas de redirection vers Hello Asso
- ❌ Pas de gestion du don dans la commande

**Actions à ajouter** :
1. Récupérer le montant du don depuis les paramètres
2. Créer un `Payment` avec `provider: 'helloasso'`
3. Créer la commande Hello Asso via `HelloassoService`
4. Rediriger vers l'URL de paiement Hello Asso
5. Stocker l'ID de commande Hello Asso dans `Payment.external_id`

#### 3. **Webhooks Hello Asso** ⚠️ **CRITIQUE**
- ❌ Pas de contrôleur webhook
- ❌ Pas de gestion des notifications Hello Asso (paiement réussi, échoué, annulé)

**Fichier à créer** : `app/controllers/webhooks/helloasso_controller.rb`

**Actions à gérer** :
- `payment.succeeded` → Mettre `Order.status = 'paid'`, `Payment.status = 'completed'`
- `payment.failed` → Mettre `Order.status = 'failed'`, restaurer le stock
- `payment.cancelled` → Mettre `Order.status = 'cancelled'`, restaurer le stock

#### 4. **Routes Webhooks**
- ❌ Pas de route pour recevoir les webhooks Hello Asso

**Route à ajouter** : `config/routes.rb`
```ruby
namespace :webhooks do
  post 'helloasso', to: 'helloasso#webhook'
end
```

#### 5. **Gestion du Don**
- ⚠️ Le don est calculé côté client (JavaScript) mais pas envoyé au serveur
- ❌ Pas de colonne `donation_cents` dans `Order`
- ❌ Pas de stockage du don dans la commande

**Migration à créer** :
```ruby
add_column :orders, :donation_cents, :integer, default: 0
```

#### 6. **Credentials Rails**
- ❌ `helloasso_token` pas encore ajouté aux credentials

**Commande à exécuter** :
```bash
bin/rails credentials:edit
# Ajouter :
# helloasso:
#   token: "votre_token_helloasso"
```

#### 7. **Page de Confirmation**
- ❌ Pas de page de retour après paiement Hello Asso
- ❌ Pas de gestion du retour utilisateur (succès/échec)

**Route à ajouter** :
```ruby
get 'orders/:id/confirm', to: 'orders#confirm', as: 'confirm_order'
```

---

## 🎯 PLAN D'ACTION - QUICK WINS BOUTIQUE

> ⚠️ **NOTE IMPORTANTE** : Avec seulement ~6-7 produits dans la boutique, les filtres et la barre de recherche ne sont **pas prioritaires**. Mieux vaut se concentrer sur l'intégration Hello Asso et des améliorations UX simples et impactantes.

### **Phase 1 : Quick Wins Boutique (Priorité Révisée)**

#### 1.1 Message "Article ajouté" plus visible ✅ **TERMINÉ** (2025-01-20)
**Fichiers modifiés** :
- `app/controllers/carts_controller.rb` - Messages améliorés avec nom du produit
- `app/views/layouts/_flash.html.erb` - Toast success (vert) + bouton "Voir le panier"

**Implémentation réalisée** :
- ✅ Toast notification en haut à droite (vert pour succès, bleu pour info, rouge pour erreur)
- ✅ Animation slide-in (Bootstrap Toast)
- ✅ Auto-dismiss après 6 secondes
- ✅ Bouton "Voir le panier" dans le toast de succès
- ✅ Message personnalisé avec nom du produit : "Casque LED ajouté au panier"
- ✅ Gestion des quantités : "3x T-shirt ajoutés au panier"
- ✅ Redirection vers boutique après ajout (logique améliorée)
- ✅ Layout responsive (bouton en dessous sur mobile, à côté sur desktop)

#### 1.2 Zoom sur image produit (2h) ⚠️ **PRIORITÉ MOYENNE**
**Fichiers à modifier** :
- `app/views/shop/show.html.erb` - Page détail produit
- `app/assets/javascripts/shop.js` ou Stimulus controller
- `app/assets/stylesheets/_style.scss` - Styles lightbox

**Implémentation** :
- Lightbox simple (Bootstrap modal ou librairie légère)
- Clic sur image produit → agrandissement
- Navigation clavier (Escape pour fermer)

#### ~~1.3 Améliorer image par défaut~~ ✅ **DÉJÀ GÉRÉ**
**Raison** : L'image est obligatoire à la création du produit ou de la variante (validation `presence: true` dans `Product`). Pas besoin de placeholder.

#### ~~1.4 Filtres par catégories~~ ❌ **DÉPRIORISÉ**
**Raison** : Avec seulement ~6-7 produits, les filtres ne sont pas nécessaires. Tous les produits sont visibles d'un coup d'œil.

#### ~~1.5 Barre de recherche~~ ❌ **DÉPRIORISÉ**
**Raison** : Avec seulement ~6-7 produits, la recherche n'apporte pas de valeur. Mieux vaut améliorer l'affichage des produits existants.

---

## 🎯 PLAN D'ACTION - INTÉGRATION HELLO ASSO

### **Phase 1 : Configuration & Service (2-3h)**

#### 1.1 Ajouter credentials Hello Asso
```bash
bin/rails credentials:edit
# Ajouter :
# helloasso:
#   token: "votre_token_helloasso"
#   organization_slug: "grenoble-roller"  # À confirmer avec Hello Asso
```

#### 1.2 Créer le service Hello Asso
**Fichier** : `app/services/helloasso_service.rb`

**Fonctionnalités** :
- Authentification avec token
- Création de commande Hello Asso
- Récupération du statut d'une commande
- Gestion des erreurs API

#### 1.3 Créer la migration pour le don
```bash
bin/rails generate migration AddDonationToOrders donation_cents:integer
```

**Migration** :
```ruby
class AddDonationToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :donation_cents, :integer, default: 0, null: false
  end
end
```

---

### **Phase 2 : Intégration Checkout (3-4h)**

#### 2.1 Modifier OrdersController#create
**Fichier** : `app/controllers/orders_controller.rb`

**Modifications** :
1. Récupérer `donation_cents` depuis les paramètres
2. Créer `Payment` avec `provider: 'helloasso'`
3. Appeler `HelloassoService#create_order` avec :
   - Items de la commande
   - Montant total (produits + don)
   - Informations utilisateur
   - URL de retour (succès/échec)
4. Rediriger vers l'URL de paiement Hello Asso
5. Stocker `external_id` (ID Hello Asso) dans `Payment`

#### 2.2 Modifier la vue checkout
**Fichier** : `app/views/orders/new.html.erb`

**Modifications** :
- Envoyer `donation_cents` dans le formulaire (hidden field)
- S'assurer que le JavaScript met à jour le champ hidden

---

### **Phase 3 : Webhooks (3-4h)**

#### 3.1 Créer le contrôleur webhook
**Fichier** : `app/controllers/webhooks/helloasso_controller.rb`

**Fonctionnalités** :
- Vérifier la signature Hello Asso (sécurité)
- Gérer les événements :
  - `payment.succeeded` → Mettre à jour `Order` et `Payment`
  - `payment.failed` → Restaurer le stock, mettre à jour statuts
  - `payment.cancelled` → Restaurer le stock, mettre à jour statuts
- Envoyer email de confirmation (si paiement réussi)

#### 3.2 Ajouter les routes webhook
**Fichier** : `config/routes.rb`

```ruby
namespace :webhooks do
  post 'helloasso', to: 'helloasso#webhook'
end
```

#### 3.3 Page de confirmation
**Fichier** : `app/controllers/orders_controller.rb`

**Action** : `confirm`
- Récupérer l'ID de commande depuis les paramètres Hello Asso
- Vérifier le statut du paiement
- Afficher la page de confirmation ou d'échec

**Route** :
```ruby
get 'orders/:id/confirm', to: 'orders#confirm', as: 'confirm_order'
```

---

### **Phase 4 : Tests & Validation (2-3h)**

#### 4.1 Tests unitaires
- Tests `HelloassoService`
- Tests `OrdersController#create` avec Hello Asso
- Tests webhook controller

#### 4.2 Tests d'intégration
- Parcours complet : Panier → Checkout → Hello Asso → Retour
- Gestion des erreurs (paiement échoué, annulé)
- Vérification du stock (restauration si échec)

#### 4.3 Tests en sandbox Hello Asso
- Créer compte sandbox Hello Asso
- Tester le flux complet en environnement de test
- Valider les webhooks

---

## 📋 CHECKLIST FINALE

### Quick Wins Boutique (Priorité Révisée)
- [x] Message "Article ajouté" plus visible ✅ **TERMINÉ** (2025-01-20)
- [ ] Zoom sur image produit ⚠️ **PRIORITÉ MOYENNE**
- [ ] ~~Améliorer image par défaut~~ ✅ **DÉJÀ GÉRÉ** (image obligatoire)
- [ ] ~~Filtres par catégories~~ ❌ **DÉPRIORISÉ** (peu de produits)
- [ ] ~~Barre de recherche~~ ❌ **DÉPRIORISÉ** (peu de produits)

### Intégration Hello Asso
- [ ] Credentials Hello Asso ajoutés
- [ ] Service `HelloassoService` créé
- [ ] Migration `donation_cents` appliquée
- [ ] `OrdersController#create` modifié
- [ ] Webhook controller créé
- [ ] Routes webhook ajoutées
- [ ] Page de confirmation créée
- [ ] Tests unitaires écrits
- [ ] Tests d'intégration écrits
- [ ] Tests sandbox Hello Asso effectués

---

## 📚 RESSOURCES & DOCUMENTATION

### Documentation Hello Asso
- **API Documentation** : https://api.helloasso.com/v5/docs
- **Webhooks** : https://api.helloasso.com/v5/docs/webhooks
- **Sandbox** : https://www.helloasso.com/associations/grenoble-roller (à confirmer)

### Fichiers de référence dans le projet
- `docs/02-shape-up/technical-implementation-guide.md` - Exemple service Hello Asso
- `docs/09-product/plan-action-quick-wins.md` - Plan d'action quick wins
- `docs/09-product/ux-improvements-backlog.md` - Backlog complet
- `app/views/orders/new.html.erb` - Page checkout actuelle
- `app/controllers/orders_controller.rb` - Contrôleur orders actuel
- `app/models/payment.rb` - Modèle Payment
- `app/models/order.rb` - Modèle Order

---

## 💡 RÉFLEXION SHAPE UP - PRIORISATION

### Pourquoi déprioriser filtres et recherche ?

**Contexte** : La boutique contient seulement ~6-7 produits actifs.

**Principe Shape Up** : Ne pas sur-engineerer. Se concentrer sur ce qui apporte de la valeur réelle.

**Analyse** :
- ✅ **Filtres** : Avec 6-7 produits, tous sont visibles d'un coup d'œil. Les filtres n'apportent pas de valeur.
- ✅ **Recherche** : Avec 6-7 produits, la recherche est inutile. L'utilisateur voit tous les produits immédiatement.
- ✅ **Alternatives plus pertinentes** :
  - Message "Article ajouté" visible → Améliore l'UX immédiatement
  - Zoom sur images → Aide à la décision d'achat
  - **Intégration Hello Asso** → **CRITIQUE** pour finaliser la boutique
  - Images obligatoires → Déjà géré (validation `presence: true`)

**Recommandation** : Se concentrer sur l'intégration Hello Asso (valeur business critique) et les quick wins UX simples.

---

## ⚠️ POINTS D'ATTENTION

### Sécurité
- ✅ Vérifier la signature des webhooks Hello Asso (éviter les faux webhooks)
- ✅ Ne jamais stocker les tokens Hello Asso en clair
- ✅ Utiliser HTTPS pour les webhooks en production

### Gestion des erreurs
- Gérer les cas où Hello Asso est indisponible
- Gérer les timeouts API
- Gérer les paiements en double (idempotence)

### UX
- Afficher un loader pendant la redirection vers Hello Asso
- Message clair si le paiement échoue
- Email de confirmation après paiement réussi

---

**Dernière mise à jour** : 2025-01-20  
**Version** : 1.1

## 📝 CHANGELOG

### Version 1.1 (2025-01-20)
- ✅ Quick Win "Message Article ajouté" terminé
  - Toast vert (success) avec nom du produit
  - Bouton "Voir le panier" dans le toast
  - Redirection vers boutique après ajout (logique améliorée)
  - Messages améliorés pour toutes les actions du panier
- ✅ Validation `image_url` ajoutée à `ProductVariant`
- ✅ Priorisation révisée : filtres et recherche dépriorisés (peu de produits)

