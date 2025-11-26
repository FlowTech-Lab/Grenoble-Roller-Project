---
title: "Synthèse Quick Wins & Intégration Hello Asso"
status: "active"
version: "1.3"
created: "2025-01-20"
updated: "2025-01-26"
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

### ✅ **Phase 0 – Fondations & Authentification**

- ✅ **Structure base de données**
  - Table `payments` avec `provider`, `provider_payment_id`, `amount_cents`, `currency`, `status`
  - Modèle `Payment` (`has_many :orders`, `has_many :attendances`)
  - Modèle `Order` avec `belongs_to :payment, optional: true`
- ✅ **Credentials Rails**
  - Section `helloasso` dans `credentials.yml.enc` :
    - `client_id`, `client_secret`, `organization_slug`, `environment: "sandbox"`
- ✅ **Service HelloAsso de base**
  - `HelloassoService` :
    - Gestion OAuth2 `client_credentials` (sandbox / production)
    - Helpers `sandbox?`, `production?`, `client_id`, `client_secret`, `organization_slug`

### ✅ **Phase 1 – Checkout HelloAsso (MVP fonctionnel)**

- ✅ **Initialisation checkout-intents HelloAsso**
  - `HelloassoService.build_checkout_intent_payload(order, ...)`
  - `HelloassoService.create_checkout_intent(order, ...)` → retourne `id` + `redirectUrl`
- ✅ **Flux de création commande**
  - `OrdersController#create` :
    - Vérifie le stock et crée `Order` en `status: "pending"`
    - Crée les `OrderItem` + déduit le stock
    - Vide le panier `session[:cart]`
    - Appelle `HelloassoService.create_checkout_intent`
    - Crée un `Payment` :
      - `provider: "helloasso"`
      - `provider_payment_id: <id checkout-intent>`
      - `status: "pending"`
    - Lie la commande au paiement (`order.update!(payment: payment)`)
    - Redirige vers `redirectUrl` HelloAsso (`allow_other_host: true`)
- ✅ **UX & sécurité**
  - Bouton checkout désactive Turbo (`data-turbo="false"`) pour éviter les problèmes CORS
  - Annulation commande (`OrdersController#cancel`) :
    - Remet le stock
    - Passe `order.status` à `"cancelled"`
    - Message utilisateur neutre ("Commande annulée avec succès.")
- ✅ **Pages légales**
  - CGV / Confidentialité / Mentions légales à jour avec HelloAsso
- ✅ **UX Liste commandes & Reprise paiement** (2025-01-26)
  - **Bouton "Payer" dans la liste** : Visible directement dans `orders/index` pour les commandes `pending` avec paiement HelloAsso `pending`
  - **Suppression bouton "Annuler" de la liste** : Réduit les annulations accidentelles, l'annulation se fait uniquement depuis la page détail
  - **Action `OrdersController#pay`** : Crée un **nouveau checkout-intent** à chaque clic (évite les erreurs 404 dues à l'expiration)
  - **Mise à jour `provider_payment_id`** : Le nouveau checkout-intent ID remplace l'ancien dans le `Payment`
- ✅ **UX Page détail commande** (2025-01-26)
  - **Alerte paiement pending supprimée** : Plus de redondance, focus sur l'action principale
  - **Bouton principal "Finaliser le paiement"** : CTA unique et visible pour les paiements en attente
  - **Bouton "Annuler" dans dropdown** : Caché dans menu "Plus d'actions" (friction élevée = moins d'annulations accidentelles)
  - **Hiérarchie visuelle améliorée** : Titre séparé du status badge, sections claires, mobile-first

---

## 🔄 FLUX COMPLET (État actuel + À venir)

### ✅ Phase 1 – Implémenté

```text
Utilisateur → Panier → Page Checkout
          ↓
   POST /orders (OrdersController#create)
          ↓
 Order(pending) + Payment(pending: helloasso)
          ↓
 HelloassoService.create_checkout_intent
          ↓
  redirectUrl HelloAsso
          ↓
 Navigateur → https://www.helloasso-sandbox.com/... (checkout)
          ↓
 Utilisateur paie (ou annule) sur HelloAsso
          ↓
 Retour vers l'app (backUrl / returnUrl)

ÉTAT ACTUEL : Order & Payment restent `pending` après paiement.
La validation se fait côté HelloAsso uniquement (back-office).

REPRISE PAIEMENT (nouveau - 2025-01-26) :
Utilisateur → Liste commandes → Clic "Payer"
          ↓
   POST /orders/:id/pay (OrdersController#pay)
          ↓
 Création NOUVEAU checkout-intent (évite expiration)
          ↓
 Mise à jour Payment.provider_payment_id
          ↓
 Redirection HelloAsso (URL toujours valide)
```

### 🔜 Phase 2 – Polling (lecture API HelloAsso)

```text
Tâche (cron / Rake) helloasso:check_payments
          ↓
 Payment.pending (provider: "helloasso")
          ↓
 HelloassoService.fetch_and_update_payment(payment)
          ↓
 GET /v5/organizations/{slug}/orders/{id} ou /payments/{id}
          ↓
 state: "Confirmed" → Payment.paid + Order.paid
 state: "Refused"/"Cancelled" → Payment.failed + Order.failed
 state: "Pending" → on réessaie plus tard
```

### 🔮 Phase 3 – Webhooks (temps réel)

```text
HelloAsso → POST /webhooks/helloasso
          ↓
 HelloassoWebhooksController#handle
          ↓
 Vérification signature + idempotence
          ↓
 Mise à jour Payment + Order (paid / failed / cancelled)
          ↓
 (Optionnel) Notifications / emails / logs
```

---

### ⏳ **Phase 2 – Suivi Paiement (Polling)** (à implémenter)

Objectif : passer les commandes de `pending` → `paid` / `failed` en lisant l'API HelloAsso.

- 🔜 **Modèle `Payment`**
  - Ajouter éventuellement un `enum` `status` (`pending`, `paid`, `failed`, `cancelled`, `expired`)
  - Méthode de classe :
    - `Payment.check_and_update_helloasso_orders` :
      - Boucle sur les paiements `helloasso` `pending` récents
      - Appelle `HelloassoService.fetch_and_update_payment(payment)`
- 🔜 **Service HelloAsso**
  - `HelloassoService.fetch_order_status(provider_payment_id)` ou équivalent
  - Met à jour :
    - `payment.status` (`paid`, `failed`, ...)
    - `order.status` (`paid`, `failed`, ...)
- 🔜 **Infrastructure**
  - Tâche Rake `helloasso:check_payments` (lançable manuellement ou via cron)
  - Optionnel : page de confirmation avec polling JS sur le statut du paiement

#### ✅ Pré‑conditions avant Phase 2

- [ ] Flux sandbox complet validé :
  - [ ] Création commande → checkout-intent généré
  - [ ] Redirection vers HelloAsso OK
  - [ ] Retour vers l'app après paiement OK
  - [ ] `Payment.provider_payment_id` correspond bien à l'id HelloAsso
- [ ] API HelloAsso confirmée :
  - [ ] Endpoint GET de lecture (`/orders/{id}` ou `/payments/{id}`) identifié dans la doc officielle
  - [ ] États possibles (`Confirmed`, `Pending`, `Refused`, `Cancelled`, …) documentés
  - [ ] Limites de rate limiting connues
- [ ] Erreurs attendues listées :
  - [ ] Token expiré (401/403)
  - [ ] Order introuvable (404)
  - [ ] Timeout / erreurs 5xx HelloAsso

#### 🛠️ Plan d'implémentation (résumé)

- **Modèle `Payment`**
  - Scope `pending_helloasso` pour récupérer les paiements HelloAsso en attente récents
  - Méthode de classe `check_and_update_helloasso_orders` qui boucle sur ce scope et appelle le service
- **Service `HelloassoService`**
  - Méthode `fetch_and_update_payment(payment)` :
    - Appelle l’API HelloAsso (GET)
    - Interprète l’état (`Confirmed`, `Refused`, …)
    - Met à jour `payments.status` et `orders.status`
    - Loggue les erreurs éventuelles
- **Infra**
  - Tâche Rake `helloasso:check_payments`
  - Intégration future dans un cron / scheduler (toutes les 5–10 minutes)

---

### 🔮 **Phase 3 – Webhooks HelloAsso** (future)

Objectif : mise à jour temps réel et robuste des paiements.

- 🔜 **Contrôleur webhooks**
  - `HelloassoWebhooksController` avec endpoint `/webhooks/helloasso`
  - Validation de la signature HMAC
  - Idempotence (ne pas traiter deux fois le même événement)
- 🔜 **Routes**
  - Ajout dans `routes.rb` :
    - `post "/webhooks/helloasso", to: "helloasso_webhooks#handle"`
- 🔜 **Traitement des événements**
  - Exemples (à confirmer avec la doc officielle) :
    - Paiement confirmé → `payment.status = "paid"`, `order.status = "paid"`
    - Paiement refusé / annulé → `payment.status = "failed"`, `order.status = "failed"` + éventuel rollback stock
- 🔜 **Opérations**
  - Queue de retry (Sidekiq) si le traitement échoue
  - Monitoring minimal des échecs de webhooks

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

#### 1.2 UX Liste commandes & Reprise paiement ✅ **TERMINÉ** (2025-01-26)
**Fichiers modifiés** :
- `app/views/orders/index.html.erb` - Ajout bouton "Payer", suppression bouton "Annuler"
- `app/controllers/orders_controller.rb` - Action `pay` créant un nouveau checkout-intent
- `config/routes.rb` - Route `POST /orders/:id/pay`

**Implémentation réalisée** :
- ✅ **Bouton "Payer" dans la liste** : Visible directement pour les commandes `pending` avec paiement HelloAsso `pending`
  - Bouton orange (`btn-warning`) pour visibilité
  - Placé avant le bouton "Détails"
  - Redirige directement vers HelloAsso (1 clic pour payer)
- ✅ **Suppression bouton "Annuler" de la liste** : Réduit les annulations accidentelles
  - L'annulation se fait uniquement depuis la page détail (dans dropdown "Plus d'actions")
  - Friction élevée = moins d'annulations par erreur
- ✅ **Action `OrdersController#pay`** : Crée un **nouveau checkout-intent** à chaque clic
  - Évite les erreurs 404 dues à l'expiration des checkout-intents
  - URL de redirection toujours valide
  - Mise à jour automatique du `Payment.provider_payment_id` avec le nouveau ID
- ✅ **Gestion d'erreurs** : Messages clairs si la création du checkout-intent échoue

**Résultat UX** :
- **Payer** : 1 clic depuis la liste → redirection HelloAsso ✅
- **Annuler** : 3-4 clics (Détails → Plus d'actions → Annuler → Confirmer) ⬆️
- **Objectif atteint** : Encourager les paiements, réduire les annulations accidentelles

#### 1.3 UX Page détail commande ✅ **TERMINÉ** (2025-01-26)
**Fichiers modifiés** :
- `app/views/orders/show.html.erb` - Refactorisation complète selon bonnes pratiques UX

**Implémentation réalisée** :
- ✅ **Alerte paiement pending supprimée** : Plus de redondance, focus sur l'action principale
- ✅ **Bouton principal "Finaliser le paiement"** : CTA unique et visible pour les paiements en attente
  - Bouton orange (`btn-warning`) full-width sur mobile, auto sur desktop
  - Visible uniquement si `payment.status == "pending"` et `payment.provider == "helloasso"`
- ✅ **Bouton "Annuler" dans dropdown** : Caché dans menu "Plus d'actions"
  - Friction élevée = moins d'annulations accidentelles
  - Visible uniquement pour les commandes cancellables (`pending` ou `preparation`)
- ✅ **Hiérarchie visuelle améliorée** :
  - Titre séparé du status badge (plus clair)
  - Status badges avec icônes + texte clair (pas de jargon technique)
  - Couleurs cohérentes : Jaune (pending), Bleu (préparation), Vert (payé/expédié), Rouge (annulé)
- ✅ **Actions contextuelles** : Une action principale par contexte
  - Pending + payment pending → "Finaliser le paiement"
  - Paid → "Paiement confirmé" (disabled)
  - Préparation → "Préparation en cours" (disabled)
  - Expédié → "Colis en route" (disabled)
  - Annulé → "Commande annulée" (disabled)
- ✅ **Mobile-first** : Boutons full-width sur mobile, stacking vertical logique
- ✅ **Accessibilité** : Labels ARIA, icônes avec `aria-hidden`, contraste respecté

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

### **Phase 0 : Récupération des Informations API** ⚠️ **PREMIÈRE ÉTAPE**

> 📋 **Voir le document détaillé** : [`helloasso-etape-1-api-info.md`](helloasso-etape-1-api-info.md)

#### 0.1 Récupérer les identifiants Hello Asso
- [ ] Accéder au compte Hello Asso de l'association
- [ ] Aller dans "Mon compte" → "Intégrations et API"
- [ ] Récupérer **Client ID** et **Client Secret** (OAuth2)
- [ ] Noter l'**Organization Slug** (ex: "grenoble-roller")
- [ ] Consulter la documentation API : https://api.helloasso.com/v5/docs
- [ ] Comprendre le flux OAuth2 (obtention du token)
- [ ] Tester l'authentification en sandbox

**Livrables** :
- Identifiants OAuth2 notés (Client ID, Client Secret)
- Organization Slug identifié
- Documentation API consultée
- Test d'authentification OAuth2 réussi

**Durée estimée** : 1-2h (selon familiarité avec Hello Asso)

---

### **Phase 1 : Configuration & Service (2-3h)**

#### 1.1 Ajouter credentials Hello Asso
```bash
bin/rails credentials:edit
# Ajouter :
# helloasso:
#   client_id: "votre_client_id"           # OAuth2 Client ID
#   client_secret: "votre_client_secret"  # OAuth2 Client Secret
#   organization_slug: "grenoble-roller"  # À confirmer avec Hello Asso
#   environment: "sandbox"                 # ou "production"
```

> ⚠️ **IMPORTANT** : Ces identifiants doivent être récupérés depuis le compte Hello Asso (voir Phase 0)

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
- **⚠️ SANDBOX (Tests obligatoires)** :
  - OAuth2 : https://api.helloasso-sandbox.com/oauth2
  - API v5 : https://api.helloasso-sandbox.com/v5
- **Production** :
  - OAuth2 : https://api.helloasso.com/oauth2
  - API v5 : https://api.helloasso.com/v5

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

**Dernière mise à jour** : 2025-01-26  
**Version** : 1.3

## 📝 CHANGELOG

### Version 1.3 (2025-01-26)
- ✅ **UX Liste commandes améliorée**
  - Bouton "Payer" visible directement dans la liste pour les commandes `pending`
  - Suppression bouton "Annuler" de la liste (réduit annulations accidentelles)
  - Action `OrdersController#pay` créant un nouveau checkout-intent à chaque clic
  - Mise à jour automatique du `provider_payment_id` avec le nouveau checkout-intent
- ✅ **UX Page détail commande optimisée**
  - Alerte paiement pending supprimée (plus de redondance)
  - Bouton principal "Finaliser le paiement" comme CTA unique
  - Bouton "Annuler" déplacé dans dropdown "Plus d'actions" (friction élevée)
  - Hiérarchie visuelle améliorée (titre/status séparés, mobile-first)
- ✅ **Logique reprise paiement robuste**
  - Création d'un nouveau checkout-intent évite les erreurs 404 (expiration)
  - URL de redirection toujours valide
  - Gestion d'erreurs améliorée dans `OrdersController#pay`

### Version 1.2 (2025-01-20)
- ✅ Quick Win "Message Article ajouté" terminé
  - Toast vert (success) avec nom du produit
  - Bouton "Voir le panier" dans le toast
  - Redirection vers boutique après ajout (logique améliorée)
  - Messages améliorés pour toutes les actions du panier
- ✅ Validation `image_url` ajoutée à `ProductVariant`
- ✅ Priorisation révisée : filtres et recherche dépriorisés (peu de produits)

