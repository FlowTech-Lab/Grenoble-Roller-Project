# Quick Wins & Intégration HelloAsso

**Date** : 2025-01-30  
**Version** : 2.0  
**Status** : ✅ Documentation consolidée

---

## 📋 Vue d'ensemble

Ce document consolide la synthèse des quick wins et l'intégration HelloAsso pour la boutique, incluant :
- État actuel des quick wins (terminés et restants)
- **État actuel de l'intégration HelloAsso : ✅ 100% INTÉGRÉ ET FONCTIONNEL**
- Plan d'action pour les quick wins boutique
- Plan d'action pour l'intégration HelloAsso (complété)

---

## ✅ **RÉCAPITULATIF INTÉGRATION HELLOASSO - 100%**

### **Fonctionnalités Implémentées**

| Fonctionnalité | Statut | Détails |
|----------------|--------|---------|
| **OAuth2 Authentification** | ✅ 100% | Sandbox/Production, gestion tokens automatique |
| **Checkout Commandes** | ✅ 100% | Création checkout-intent, redirection HelloAsso, gestion dons |
| **Checkout Adhésions** | ✅ 100% | Simple + multiples, gestion T-shirts |
| **Reprise Paiement** | ✅ 100% | Nouveau checkout-intent si expiration |
| **Polling Automatique** | ✅ 100% | Cron toutes les 5 min, auto-poll JS sur pages détail |
| **Mise à jour Statuts** | ✅ 100% | Payment, Order, Membership synchronisés automatiquement |
| **Gestion Erreurs** | ✅ 100% | Retry automatique, logs détaillés, fallbacks |
| **UX Optimisée** | ✅ 100% | Boutons "Payer" visibles, auto-reload, messages clairs |

### **Flux Complets Opérationnels**

- ✅ **Boutique** : Panier → Checkout → HelloAsso → Retour → Synchronisation automatique
- ✅ **Adhésions** : Formulaire → Paiement → HelloAsso → Retour → Synchronisation automatique
- ✅ **Adhésions multiples** : Plusieurs enfants → Un seul paiement → Synchronisation automatique

### **Points Techniques Clés**

- ✅ **Environnement** : Détection automatique sandbox/production selon `APP_ENV` et `Rails.env`
- ✅ **Tokens OAuth2** : Refresh automatique si 401, retry en cas d'erreur
- ✅ **Polling** : Cron backend (5 min) + Auto-poll JS frontend (10s pendant 1 min)
- ✅ **Statuts** : Synchronisation bidirectionnelle (HelloAsso → App)
- ✅ **Webhooks** : Non nécessaires (polling suffisant et plus fiable)

---

## 📊 ÉTAT ACTUEL - QUICK WINS

### ✅ **Quick Wins Terminés (11/41 - 27%)**

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

### ⏳ **Quick Wins Restants (30/41 - 73%)**

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

**Status Global** : ✅ **100% INTÉGRÉ ET FONCTIONNEL**

L'intégration HelloAsso est **complète et opérationnelle** pour :
- ✅ **Boutique** : Commandes avec checkout-intent HelloAsso
- ✅ **Adhésions** : Adhésions simples et multiples avec checkout-intent HelloAsso
- ✅ **Polling automatique** : Synchronisation des statuts toutes les 5 minutes (cron)
- ✅ **Auto-poll JavaScript** : Vérification automatique sur pages détail (1 minute)
- ✅ **Reprise paiement** : Création de nouveaux checkout-intents si expiration

### ✅ **Phase 0 – Fondations & Authentification** ✅ **100%**

- ✅ **Structure base de données**
  - Table `payments` avec `provider`, `provider_payment_id`, `amount_cents`, `currency`, `status`
  - Modèle `Payment` (`has_many :orders`, `has_many :memberships`, `has_one :membership`)
  - Modèle `Order` avec `belongs_to :payment, optional: true`
  - Modèle `Membership` avec `belongs_to :payment, optional: true`
- ✅ **Credentials Rails**
  - Section `helloasso` dans `credentials.yml.enc` :
    - `client_id`, `client_secret` (sandbox)
    - `client_id_production`, `client_secret_production` (production)
    - `organization_slug`
    - Détection automatique environnement (sandbox/production) selon `APP_ENV` et `Rails.env`
- ✅ **Service HelloAsso complet**
  - `HelloassoService` :
    - Gestion OAuth2 `client_credentials` (sandbox / production)
    - Helpers `sandbox?`, `production?`, `client_id`, `client_secret`, `organization_slug`
    - Gestion automatique des tokens (refresh si 401)
    - Retry automatique en cas d'erreur réseau

---

### ✅ **Phase 1 – Checkout HelloAsso** ✅ **100%**

#### **1.1 Boutique (Commandes)**

- ✅ **Initialisation checkout-intents HelloAsso**
  - `HelloassoService.build_checkout_intent_payload(order, donation_cents, ...)`
  - `HelloassoService.create_checkout_intent(order, ...)` → retourne `id` + `redirectUrl`
  - Gestion des dons optionnels intégrée dans le payload
- ✅ **Flux de création commande** (`OrdersController#create`)
  - Vérifie le stock et crée `Order` en `status: "pending"`
  - Crée les `OrderItem` + déduit le stock
  - Vide le panier `session[:cart]`
  - Appelle `HelloassoService.create_checkout_intent` avec don optionnel
  - Crée un `Payment` :
    - `provider: "helloasso"`
    - `provider_payment_id: <id checkout-intent>`
    - `status: "pending"`
    - `amount_cents: order.total_cents` (inclut le don)
  - Lie la commande au paiement (`order.update!(payment: payment)`)
  - Redirige vers `redirectUrl` HelloAsso (`allow_other_host: true`)
- ✅ **Reprise paiement** (`OrdersController#pay`)
  - Vérifie le statut réel via HelloAsso avant de créer un nouveau checkout-intent
  - Crée un **nouveau checkout-intent** à chaque clic (évite les erreurs 404 dues à l'expiration)
  - Mise à jour `provider_payment_id` avec le nouveau ID
  - Redirection vers HelloAsso avec URL toujours valide

#### **1.2 Adhésions**

- ✅ **Adhésion simple** (`MembershipsController#pay`)
  - `HelloassoService.create_membership_checkout_intent(membership, ...)`
  - Gestion T-shirt optionnel intégrée (taille, quantité, prix)
  - Création/mise à jour `Payment` avec `provider_payment_id`
  - Redirection vers HelloAsso
- ✅ **Adhésions multiples** (enfants groupés)
  - `HelloassoService.create_multiple_memberships_checkout_intent(memberships, ...)`
  - Un seul paiement pour plusieurs enfants
  - Gestion T-shirts multiples intégrée
  - Création `Payment` unique pour toutes les adhésions

#### **1.3 UX & Sécurité**

- ✅ **Bouton checkout désactive Turbo** (`data-turbo="false"`) pour éviter les problèmes CORS
- ✅ **Annulation commande** (`OrdersController#cancel`) :
  - Remet le stock
  - Passe `order.status` à `"cancelled"`
  - Message utilisateur neutre
- ✅ **Pages légales**
  - CGV / Confidentialité / Mentions légales à jour avec HelloAsso
- ✅ **UX Liste commandes** (2025-01-26)
  - **Bouton "Payer" dans la liste** : Visible directement pour commandes `pending` avec paiement HelloAsso `pending`
  - **Suppression bouton "Annuler" de la liste** : Réduit les annulations accidentelles
- ✅ **UX Page détail commande** (2025-01-26)
  - **Bouton principal "Finaliser le paiement"** : CTA unique et visible
  - **Bouton "Annuler" dans dropdown** : Friction élevée = moins d'annulations accidentelles
  - **Hiérarchie visuelle améliorée** : Mobile-first, sections claires

---

## 🔄 FLUX COMPLET - INTÉGRATION 100%

### ✅ **Flux Boutique (Commandes)**

```text
1. CRÉATION COMMANDE
Utilisateur → Panier → Page Checkout
          ↓
   POST /orders (OrdersController#create)
          ↓
 Vérification stock + Création Order(pending) + OrderItems
          ↓
 Déduction stock + Vidage panier
          ↓
 HelloassoService.create_checkout_intent(order, donation_cents)
          ↓
 Création Payment(provider: "helloasso", status: "pending")
          ↓
 Order.update!(payment: payment)
          ↓
 Redirection → redirectUrl HelloAsso (allow_other_host: true)
          ↓
 Navigateur → https://www.helloasso-sandbox.com/... (checkout)
          ↓
 Utilisateur paie (ou annule) sur HelloAsso
          ↓
 Retour vers l'app (returnUrl: /orders/:id)

2. SYNCHRONISATION STATUT (Polling)
Cron (toutes les 5 min) → helloasso:sync_payments
          ↓
 Payment.pending (provider: "helloasso", < 24h)
          ↓
 HelloassoService.fetch_and_update_payment(payment)
          ↓
 GET /v5/organizations/{slug}/checkout-intents/{id}
          ↓
 Si order présent → GET /v5/organizations/{slug}/orders/{orderId}
          ↓
 state: "Confirmed" → Payment.succeeded + Order.paid
state: "Refused" → Payment.failed + Order.failed

3. AUTO-POLL JAVASCRIPT (Page détail)
Page /orders/:id (si payment pending)
          ↓
 JavaScript : fetch('/orders/:id/payment_status') toutes les 10s (1 min max)
          ↓
 HelloassoService.fetch_and_update_payment(payment)
          ↓
 Si statut change → Recharge automatique de la page

4. REPRISE PAIEMENT
Utilisateur → Liste commandes → Clic "Payer"
          ↓
   POST /orders/:id/pay (OrdersController#pay)
          ↓
 Vérification statut réel via HelloAsso
          ↓
 Création NOUVEAU checkout-intent (évite expiration)
          ↓
 Mise à jour Payment.provider_payment_id
          ↓
 Redirection HelloAsso (URL toujours valide)
```

### ✅ **Flux Adhésions**

```text
1. CRÉATION ADHÉSION
Utilisateur → Formulaire adhésion → Soumission
          ↓
   POST /memberships (MembershipsController#create)
          ↓
 Création Membership(status: "pending")
          ↓
 Validation questionnaire santé (si FFRS)
          ↓
 Redirection → /memberships/:id

2. PAIEMENT ADHÉSION
Utilisateur → Page adhésion → Clic "Payer"
          ↓
   POST /memberships/:id/pay (MembershipsController#pay)
          ↓
 Vérification statut réel via HelloAsso
          ↓
 HelloassoService.create_membership_checkout_intent(membership)
          ↓
 Création/mise à jour Payment(provider: "helloasso", status: "pending")
          ↓
 Membership.update!(payment: payment, provider_order_id: checkout_id)
          ↓
 Redirection → redirectUrl HelloAsso

3. SYNCHRONISATION STATUT (Même mécanisme que commandes)
Cron (toutes les 5 min) → helloasso:sync_payments
          ↓
 Payment.pending → HelloassoService.fetch_and_update_payment
          ↓
 state: "Confirmed" → Payment.succeeded + Membership.active
state: "Refused" → Payment.failed + Membership.expired
          ↓
 Email si paiement échoué (MembershipMailer.payment_failed)

4. ADHÉSIONS MULTIPLES (Enfants groupés)
Utilisateur → Formulaire enfants → Soumission
          ↓
 Création plusieurs Membership(status: "pending")
          ↓
 POST /memberships/pay_multiple
          ↓
 HelloassoService.create_multiple_memberships_checkout_intent(memberships)
          ↓
 Un seul Payment pour toutes les adhésions
          ↓
 Redirection HelloAsso → Paiement unique
```

---

### ✅ **Phase 2 – Polling Automatique** ✅ **100%**

#### **2.1 Polling Cron (Backend)**

```text
Tâche (cron / Rake) helloasso:sync_payments (toutes les 5 min)
          ↓
 Payment.pending (provider: "helloasso", créé < 24h)
          ↓
 HelloassoService.fetch_and_update_payment(payment)
          ↓
 GET /v5/organizations/{slug}/checkout-intents/{id}
          ↓
 Si order présent → GET /v5/organizations/{slug}/orders/{orderId}
          ↓
 state: "Confirmed" → Payment.succeeded + Order.paid / Membership.active
state: "Refused" → Payment.failed + Order.failed / Membership.expired
state: "Pending" → on réessaie plus tard (cron suivant)
```

**Configuration** :
- ✅ Rake task `helloasso:sync_payments` créée (`lib/tasks/helloasso.rake`)
- ✅ Cron configuré (Whenever) : toutes les 5 minutes (`config/schedule.rb`)
- ✅ Filtre : uniquement les paiements `pending` créés dans les dernières 24h
- ✅ Gestion d'erreurs : logs détaillés, continue même si un paiement échoue

#### **2.2 Auto-poll JavaScript (Frontend)**

**Pages détail commande** (`app/views/orders/show.html.erb`) :
- ✅ Vérification automatique toutes les 10 secondes pendant 1 minute
- ✅ Appel `GET /orders/:id/payment_status` (appelle `HelloassoService.fetch_and_update_payment`)
- ✅ Recharge automatique de la page si statut change (`pending` → `succeeded`/`failed`)
- ✅ Bouton "Rafraîchir" manuel disponible

**Pages détail adhésion** (`app/views/memberships/show.html.erb`) :
- ✅ Même mécanisme que pour les commandes
- ✅ Appel `GET /memberships/:id/payment_status`
- ✅ Recharge automatique si statut change

#### **2.3 Mise à jour des Statuts**

**Méthode `HelloassoService.fetch_and_update_payment(payment)`** :
- ✅ Récupère le checkout-intent HelloAsso
- ✅ Si un order est présent, récupère son état via `/orders/{orderId}`
- ✅ Détermine le nouveau statut :
  - `"Confirmed"` → `Payment.succeeded`
  - `"Refused"` → `Payment.failed`
  - `"Refunded"` → `Payment.refunded`
  - Sinon → `Payment.pending` (ou `abandoned` si > 45 min)
- ✅ Met à jour `Payment.status`
- ✅ Met à jour `Order.status` (si commande associée) :
  - `succeeded` → `Order.paid`
  - `failed`/`refunded`/`abandoned` → `Order.failed`
- ✅ Met à jour `Membership.status` (si adhésion associée) :
  - `succeeded` → `Membership.active`
  - `failed`/`refunded`/`abandoned` → `Membership.expired`
- ✅ Envoie emails si paiement échoué (`MembershipMailer.payment_failed`)

---

### ✅ **Phase 3 – Webhooks** ⚠️ **NON NÉCESSAIRE**

**Note** : Les webhooks ne sont **pas implémentés** car le **polling automatique** (cron + auto-poll JS) couvre tous les cas d'usage :

- ✅ **Polling cron** : Synchronisation toutes les 5 minutes (fiable, pas de dépendance externe)
- ✅ **Auto-poll JavaScript** : Vérification immédiate sur pages détail (expérience utilisateur optimale)
- ✅ **Reprise paiement** : Création de nouveaux checkout-intents si expiration

**Avantages du polling vs webhooks** :
- ✅ Pas de configuration webhook côté HelloAsso
- ✅ Pas de gestion de signature HMAC
- ✅ Pas de dépendance à la disponibilité du serveur (webhooks peuvent échouer)
- ✅ Contrôle total sur la fréquence et la logique de synchronisation

**Si webhooks nécessaires plus tard** (optionnel) :
- Contrôleur webhook à créer
- Routes webhook à ajouter
- Validation signature HMAC
- Idempotence

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

#### 1.4 Zoom sur image produit (2h) ⚠️ **PRIORITÉ MOYENNE**

**Fichiers à modifier** :
- `app/views/shop/show.html.erb` - Page détail produit
- `app/assets/javascripts/shop.js` ou Stimulus controller
- `app/assets/stylesheets/_style.scss` - Styles lightbox

**Implémentation** :
- Lightbox simple (Bootstrap modal ou librairie légère)
- Clic sur image produit → agrandissement
- Navigation clavier (Escape pour fermer)

---

## 🎯 PLAN D'ACTION - INTÉGRATION HELLO ASSO

**Status Global** : ✅ **100% TERMINÉ - INTÉGRATION COMPLÈTE**

> 📋 **Voir le document détaillé** : [`helloasso-setup.md`](helloasso-setup.md)

### **Phase 0 : Récupération des Informations API** ✅ **100% TERMINÉ**

#### 0.1 Récupérer les identifiants Hello Asso ✅ **TERMINÉ**
- ✅ Accès au compte Hello Asso de l'association
- ✅ Section "Intégrations et API" consultée
- ✅ **Client ID** et **Client Secret** (OAuth2) récupérés et configurés
- ✅ **Organization Slug** noté et configuré
- ✅ Documentation API consultée : https://api.helloasso.com/v5/docs
- ✅ Flux OAuth2 compris et implémenté
- ✅ Authentification sandbox testée et fonctionnelle

**Livrables** :
- ✅ Identifiants OAuth2 configurés dans Rails credentials (sandbox + production)
- ✅ Organization Slug configuré
- ✅ Documentation API intégrée dans le code
- ✅ Authentification OAuth2 fonctionnelle (sandbox + production)

---

### **Phase 1 : Configuration & Service** ✅ **100% TERMINÉ**

- ✅ Credentials Hello Asso ajoutés (sandbox + production)
- ✅ Service `HelloassoService` créé et complet
- ✅ Authentification OAuth2 fonctionnelle
- ✅ Gestion automatique des tokens (refresh si 401)
- ✅ Détection automatique environnement (sandbox/production)

---

### **Phase 2 : Intégration Checkout** ✅ **100% TERMINÉ**

#### **2.1 Boutique (Commandes)**
- ✅ `OrdersController#create` modifié
- ✅ Checkout-intents HelloAsso fonctionnels
- ✅ Gestion des dons optionnels intégrée
- ✅ Redirection vers HelloAsso
- ✅ Reprise paiement implémentée (`OrdersController#pay`)

#### **2.2 Adhésions**
- ✅ `MembershipsController#pay` implémenté
- ✅ Checkout-intents adhésions simples fonctionnels
- ✅ Checkout-intents adhésions multiples fonctionnels
- ✅ Gestion T-shirts optionnels intégrée
- ✅ Redirection vers HelloAsso

---

### **Phase 3 : Polling Automatique** ✅ **100% TERMINÉ**

- ✅ Rake task `helloasso:sync_payments` créée (`lib/tasks/helloasso.rake`)
- ✅ Configuration cron (Whenever) : toutes les 5 minutes (`config/schedule.rb`)
- ✅ Auto-poll JavaScript sur page détail commande (`app/views/orders/show.html.erb`)
- ✅ Auto-poll JavaScript sur page détail adhésion (`app/views/memberships/show.html.erb`)
- ✅ Routes `check_payment` et `payment_status` ajoutées (Orders + Memberships)
- ✅ Méthode `HelloassoService.fetch_and_update_payment` complète
- ✅ Mise à jour automatique des statuts (Payment, Order, Membership)
- ✅ Envoi emails si paiement échoué

---

### **Phase 4 : Webhooks** ⚠️ **NON NÉCESSAIRE**

**Raison** : Le polling automatique (cron + auto-poll JS) couvre tous les cas d'usage de manière fiable et robuste.

**Avantages du polling vs webhooks** :
- ✅ Pas de configuration webhook côté HelloAsso
- ✅ Pas de gestion de signature HMAC
- ✅ Pas de dépendance à la disponibilité du serveur (webhooks peuvent échouer)
- ✅ Contrôle total sur la fréquence et la logique de synchronisation

**Si nécessaire plus tard** (optionnel, non prioritaire) :
- [ ] Contrôleur webhook créé
- [ ] Routes webhook ajoutées
- [ ] Validation signature HMAC
- [ ] Idempotence
- [ ] Traitement des événements

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
- `docs/09-product/helloasso-setup.md` - Guide de configuration HelloAsso
- `docs/09-product/flux-boutique-helloasso.md` - Flux boutique HelloAsso
- `docs/09-product/ux-improvements-backlog.md` - Backlog complet
- `app/views/orders/new.html.erb` - Page checkout actuelle
- `app/controllers/orders_controller.rb` - Contrôleur orders actuel
- `app/models/payment.rb` - Modèle Payment
- `app/models/order.rb` - Modèle Order

---

**Dernière mise à jour** : 2025-01-30  
**Version** : 3.0 (Intégration HelloAsso 100% - Polling complet, webhooks non nécessaires)

