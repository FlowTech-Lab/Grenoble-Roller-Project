---
title: "Workflow Commandes - Statuts et Emails"
status: "active"
version: "1.0"
created: "2025-01-26"
tags: ["orders", "emails", "workflow", "status"]
---

# Workflow Commandes - Statuts et Emails

**Objectif** : Documenter le système complet de gestion des commandes, incluant les statuts, les emails automatiques, et le workflow de remboursement.

---

## 📋 Statuts des Commandes

### Statuts Disponibles

| Statut | Description | Email Envoyé | Déclencheur |
|--------|-------------|--------------|-------------|
| `pending` | En attente de paiement | ✅ `order_confirmation` | Création de la commande |
| `paid` / `payé` | Payée | ✅ `order_paid` | Paiement confirmé (HelloAsso) |
| `preparation` / `en préparation` | En préparation | ✅ `order_preparation` | Changement manuel (admin) |
| `shipped` / `expédié` | Expédiée | ✅ `order_shipped` | Changement manuel (admin) |
| `cancelled` / `annulé` | Annulée | ✅ `order_cancelled` | Annulation par l'utilisateur ou admin |
| `refund_requested` / `remboursement_demandé` | Demande de remboursement | ✅ `refund_requested` | Changement manuel (admin) |
| `refunded` / `remboursé` | Remboursée | ✅ `refund_confirmed` | Après remboursement HelloAsso |
| `failed` | Échouée (paiement refusé) | ❌ Pas d'email | Paiement refusé (HelloAsso) |

---

## 📧 Emails Automatiques

### Système de Notification

Les emails sont envoyés **automatiquement** via le callback `after_update :notify_status_change` dans le modèle `Order`.

**Fichiers** :
- `app/mailers/order_mailer.rb` - Mailer avec toutes les méthodes
- `app/views/order_mailer/*.html.erb` - Vues HTML des emails

### Liste des Emails

#### 1. `order_confirmation`
- **Déclencheur** : Création de la commande (statut `pending`)
- **Sujet** : `✅ Commande #X - Confirmation de commande`
- **Contenu** : Détails de la commande, lien pour finaliser le paiement

#### 2. `order_paid`
- **Déclencheur** : Statut passe à `paid` / `payé`
- **Sujet** : `💳 Commande #X - Paiement confirmé`
- **Contenu** : Confirmation du paiement, prochaines étapes

#### 3. `order_cancelled`
- **Déclencheur** : Statut passe à `cancelled` / `annulé`
- **Sujet** : `❌ Commande #X - Commande annulée`
- **Contenu** : Information sur l'annulation, restauration du stock

#### 4. `order_preparation`
- **Déclencheur** : Statut passe à `preparation` / `en préparation`
- **Sujet** : `⚙️ Commande #X - En préparation`
- **Contenu** : Information sur la préparation en cours

#### 5. `order_shipped`
- **Déclencheur** : Statut passe à `shipped` / `expédié`
- **Sujet** : `📦 Commande #X - Expédiée`
- **Contenu** : Confirmation d'expédition, suivi de livraison

#### 6. `refund_requested`
- **Déclencheur** : Statut passe à `refund_requested` / `remboursement_demandé`
- **Sujet** : `🔄 Commande #X - Demande de remboursement en cours`
- **Contenu** : Information sur la demande de remboursement en cours

#### 7. `refund_confirmed`
- **Déclencheur** : Statut passe à `refunded` / `remboursé`
- **Sujet** : `✅ Commande #X - Remboursement confirmé`
- **Contenu** : Confirmation du remboursement, délais bancaires

---

## 🔄 Workflow Complet

### 1. Création de Commande

```
Utilisateur → Panier → Créer commande
    ↓
Order créée (status: "pending")
    ↓
Email: order_confirmation ✅
    ↓
Redirection vers HelloAsso pour paiement
```

**Code** : `OrdersController#create`

### 2. Paiement HelloAsso

```
Utilisateur → HelloAsso → Paiement
    ↓
Retour sur l'app (returnUrl)
    ↓
Polling automatique (toutes les 5 min)
    ↓
HelloAsso API → Statut "Confirmed"
    ↓
Payment.status = "succeeded"
Order.status = "paid"
    ↓
Email: order_paid ✅
```

**Code** :
- `HelloassoService.fetch_and_update_payment`
- `lib/tasks/helloasso.rake` (cron toutes les 5 min)

### 3. Préparation et Expédition

```
Admin → Change status à "preparation"
    ↓
Email: order_preparation ✅
    ↓
Admin → Change status à "shipped"
    ↓
Email: order_shipped ✅
```

**Note** : À implémenter dans l'interface admin (futur)

### 4. Annulation

#### Annulation par l'utilisateur (pending)
```
Utilisateur → Annuler commande
    ↓
Order.status = "cancelled"
    ↓
Stock restauré automatiquement
    ↓
Email: order_cancelled ✅
```

**Code** : `OrdersController#cancel`

#### Annulation d'une commande payée
```
Utilisateur → Tente d'annuler
    ↓
Check HelloAsso (statut réel)
    ↓
Si payée → Message : "Contactez l'association pour remboursement"
    ↓
Pas d'annulation automatique
```

### 5. Remboursement

#### Demande de remboursement
```
Admin → Change status à "refund_requested"
    ↓
Email: refund_requested ✅
    ↓
Admin → Effectue remboursement sur HelloAsso
    ↓
Admin → Change status à "refunded"
    ↓
Email: refund_confirmed ✅
```

**Note** : Le remboursement HelloAsso doit être fait **manuellement** depuis l'interface HelloAsso.

---

## 🔍 Polling Automatique

### Système de Polling

**Deux niveaux de polling** :

1. **Cron (Backend)** : Toutes les 5 minutes
   - Fichier : `lib/tasks/helloasso.rake`
   - Commande : `bundle exec rake helloasso:sync_payments`
   - Scope : Paiements `pending` des dernières 24h

2. **Auto-poll JS (Frontend)** : Toutes les 5 secondes pendant 1 minute
   - Fichier : `app/views/orders/show.html.erb`
   - Déclencheur : Page détail commande avec statut `pending`
   - Endpoint : `GET /orders/:id/payment-status`

### Configuration Cron (Production)

```bash
# Installer Whenever
bundle install

# Générer la cron
bundle exec whenever --update-crontab --set environment=production

# Vérifier
crontab -l
```

**Fichier** : `config/schedule.rb`

---

## 🛡️ Sécurité et Vérifications

### Check Obligatoire avant Paiement

**Action** : `OrdersController#pay`

```ruby
# 1. Check HelloAsso AVANT de créer un nouveau checkout-intent
if payment&.provider == "helloasso" && payment.status == "pending"
  HelloassoService.fetch_and_update_payment(payment)
  @order.reload
  payment.reload
end

# 2. Vérifier les conditions APRÈS le check
unless @order.status == "pending" && payment.status == "pending"
  redirect_to orders_path, notice: "Le statut a été mis à jour..."
  return
end
```

**Pourquoi** : Évite de créer des checkout-intents inutiles si la commande est déjà payée.

### Check Obligatoire avant Annulation

**Action** : `OrdersController#cancel`

```ruby
# Si payée via HelloAsso, vérifier le statut réel
if @order.payment&.provider == "helloasso" && @order.payment.status != "pending"
  HelloassoService.fetch_and_update_payment(@order.payment)
  @order.reload
end
```

**Pourquoi** : S'assurer que le statut est à jour avant d'autoriser l'annulation.

---

## 📊 Modèle de Données

### Order

```ruby
class Order
  belongs_to :user
  belongs_to :payment, optional: true
  has_many :order_items
  
  # Statut : string (pending, paid, preparation, shipped, cancelled, refund_requested, refunded, failed)
  # Callbacks :
  #   - after_update :restore_stock_if_canceled
  #   - after_update :notify_status_change
end
```

### Payment

```ruby
class Payment
  has_many :orders
  
  # provider : string (helloasso, stripe, free)
  # status : string (pending, succeeded, failed, refunded, abandoned)
  # provider_payment_id : string (ID HelloAsso)
end
```

---

## 🧪 Tests Recommandés

### Scénarios à Tester

1. **Création commande**
   - ✅ Email `order_confirmation` envoyé
   - ✅ Statut `pending`
   - ✅ Redirection vers HelloAsso

2. **Paiement réussi**
   - ✅ Auto-poll détecte le paiement
   - ✅ Statut passe à `paid`
   - ✅ Email `order_paid` envoyé

3. **Paiement refusé**
   - ✅ Statut passe à `failed`
   - ✅ Pas d'email (normal)

4. **Annulation (pending)**
   - ✅ Stock restauré
   - ✅ Email `order_cancelled` envoyé

5. **Annulation (payée)**
   - ✅ Message explicite sur le remboursement
   - ✅ Pas d'annulation automatique

6. **Remboursement**
   - ✅ Statut `refund_requested` → Email envoyé
   - ✅ Statut `refunded` → Email envoyé

---

## 🔧 Configuration Email

### ActiveJob (Asynchrone)

Les emails sont envoyés avec `deliver_later` (asynchrone via ActiveJob).

**Configuration** : `config/application.rb` ou `config/environments/*.rb`

```ruby
# Exemple : Utiliser SolidQueue (déjà configuré)
config.active_job.queue_adapter = :solid_queue
```

### Adresse Expéditeur

**Fichier** : `app/mailers/application_mailer.rb`

```ruby
default from: "noreply@grenoble-roller.org"
```

**À configurer** selon l'environnement.

---

## 📝 Notes Importantes

### Remboursements HelloAsso

⚠️ **Le remboursement HelloAsso n'est PAS automatique**.

**Workflow** :
1. Admin change le statut à `refund_requested` → Email envoyé
2. Admin va sur l'interface HelloAsso
3. Admin effectue le remboursement manuellement
4. Admin change le statut à `refunded` → Email envoyé

**Pourquoi** : HelloAsso ne permet pas de rembourser automatiquement via l'API (sécurité).

### Polling et Performance

- **Cron** : Limité aux paiements des 24 dernières heures
- **Auto-poll JS** : Maximum 1 minute (12 tentatives × 5 secondes)
- **Gestion d'erreurs** : Continue même si un paiement échoue

### Statuts et Emails

- Les emails sont envoyés **uniquement** lors d'un **changement de statut**
- Pas d'email si le statut ne change pas
- Pas d'email pour le statut `failed` (paiement refusé)

---

## 🚀 Prochaines Étapes (Futur)

1. **Interface Admin** : Gestion des statuts depuis l'admin
2. **Webhooks HelloAsso** : Alternative au polling (plus rapide)
3. **Emails texte** : Créer les versions `.text.erb`
4. **Templates email** : Améliorer le design avec un template commun
5. **Notifications push** : Ajouter des notifications in-app

---

**Dernière mise à jour** : 2025-01-26  
**Version** : 1.0

