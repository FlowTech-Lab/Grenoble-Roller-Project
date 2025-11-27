# Flux Complet : Boutique → HelloAsso API

**Date** : 2025-01-27  
**Version** : 1.0  
**Status** : Actuel (à vérifier avec Perplexity)

---

## 📋 Vue d'ensemble

Notre application gère une boutique e-commerce qui utilise HelloAsso comme processeur de paiement. Le flux complet décrit ci-dessous correspond à l'implémentation actuelle.

---

## 🔄 FLUX COMPLET ÉTAPE PAR ÉTAPE

### **ÉTAPE 1 : Utilisateur valide son panier**

**Action** : `POST /orders` (OrdersController#create)

**Ce qui se passe** :
1. Vérification du stock pour chaque article du panier
2. Calcul du total des articles (sans don)
3. Récupération du don optionnel depuis `params[:donation_cents]`
4. Calcul du total final = articles + don

**Données calculées** :
- `total_cents` : somme des `subtotal_cents` de chaque article
- `donation_cents` : montant du don en centimes (0 si absent)
- `order_total_cents` : `total_cents + donation_cents`

---

### **ÉTAPE 2 : Création de la commande locale**

**Action** : Transaction ActiveRecord

**Ce qui est créé** :
```ruby
Order.create!(
  user: current_user,
  status: "pending",
  total_cents: order_total_cents,  # Inclut le don
  donation_cents: donation_cents,  # Stocké séparément
  currency: "EUR"
)
```

**Pour chaque article du panier** :
```ruby
OrderItem.create!(
  order: order,
  variant_id: variant.id,
  quantity: ci[:quantity],
  unit_price_cents: ci[:unit_price_cents]
)

# Déduction du stock
variant.decrement!(:stock_qty, ci[:quantity])
```

**Résultat** :
- ✅ Commande créée en base de données avec statut "pending"
- ✅ Stock déduit
- ✅ Panier vidé (`session[:cart] = {}`)
- ✅ Email de confirmation envoyé (`OrderMailer.order_confirmation`)

---

### **ÉTAPE 3 : Construction du payload HelloAsso**

**Action** : `HelloassoService.build_checkout_intent_payload`

**Ce qui est construit** :

1. **Récupération des articles** (si `order.order_items` disponibles) :
   ```ruby
   items = []
   order.order_items.each do |order_item|
     items << {
       name: product_name,           # Ex: "Veste Grenoble Roller"
       quantity: order_item.quantity, # Ex: 1
       amount: order_item.unit_price_cents, # Ex: 4000 (40€)
       type: "Product"
     }
   end
   ```

2. **Ajout du don** (si `donation_cents > 0`) :
   ```ruby
   items << {
     name: "Contribution à l'association",
     quantity: 1,
     amount: donation_cents,  # Ex: 500 (5€)
     type: "Donation"
   }
   ```

3. **Calcul du total** :
   ```ruby
   total_cents = items.sum { |item| item[:amount] * item[:quantity] }
   ```

4. **Construction du payload final** :
   ```ruby
   {
     totalAmount: total_cents,        # Ex: 4500 (45€)
     initialAmount: total_cents,      # Ex: 4500 (45€) - DOIT être égal à totalAmount
     itemName: "Veste Grenoble Roller x1, Contribution à l'association x1",
     backUrl: "https://dev-grenoble-roller.flowtech-lab.org/shop",
     errorUrl: "https://dev-grenoble-roller.flowtech-lab.org/orders/36",
     returnUrl: "https://dev-grenoble-roller.flowtech-lab.org/orders/36",
     containsDonation: true,          # true si donation > 0
     metadata: {
       localOrderId: 36,
       environment: "sandbox",
       donationCents: 500,
       items: items  # Tableau complet des items (pour référence)
     }
   }
   ```

**⚠️ PROBLÈME IDENTIFIÉ** :
- Les `items` sont construits mais **PAS envoyés dans le payload principal**
- Seul `itemName` (string concaténée) est envoyé
- Les détails individuels des articles sont dans `metadata.items` (mais HelloAsso ne les utilise peut-être pas)

---

### **ÉTAPE 4 : Appel API HelloAsso**

**Endpoint** : `POST /v5/organizations/{organizationSlug}/checkout-intents`

**URL** :
- Sandbox : `https://api.helloasso-sandbox.com/v5/organizations/grenoble-roller/checkout-intents`
- Production : `https://api.helloasso.com/v5/organizations/grenoble-roller/checkout-intents`

**Headers** :
```
Authorization: Bearer {access_token}
accept: application/json
content-type: application/json
```

**Body (JSON)** :
```json
{
  "totalAmount": 4500,
  "initialAmount": 4500,
  "itemName": "Veste Grenoble Roller x1, Contribution à l'association x1",
  "backUrl": "https://dev-grenoble-roller.flowtech-lab.org/shop",
  "errorUrl": "https://dev-grenoble-roller.flowtech-lab.org/orders/36",
  "returnUrl": "https://dev-grenoble-roller.flowtech-lab.org/orders/36",
  "containsDonation": true,
  "metadata": {
    "localOrderId": 36,
    "environment": "sandbox",
    "donationCents": 500,
    "items": [
      {
        "name": "Veste Grenoble Roller",
        "quantity": 1,
        "amount": 4000,
        "type": "Product"
      },
      {
        "name": "Contribution à l'association",
        "quantity": 1,
        "amount": 500,
        "type": "Donation"
      }
    ]
  }
}
```

**Réponse attendue** :
```json
{
  "id": 147293,
  "redirectUrl": "https://www.helloasso-sandbox.com/associations/grenoble-roller/checkout/..."
}
```

---

### **ÉTAPE 5 : Création du Payment local**

**Action** : Après réception de la réponse HelloAsso

**Ce qui est créé** :
```ruby
Payment.create!(
  provider: "helloasso",
  provider_payment_id: "147293",  # ID du checkout-intent
  amount_cents: 4500,
  currency: "EUR",
  status: "pending",
  created_at: Time.current
)

order.update!(payment: payment)
```

---

### **ÉTAPE 6 : Redirection vers HelloAsso**

**Action** : `redirect_to redirect_url, allow_other_host: true`

**URL de redirection** : `https://www.helloasso-sandbox.com/associations/grenoble-roller/checkout/...`

**Ce qui se passe côté utilisateur** :
1. L'utilisateur est redirigé vers la page de paiement HelloAsso
2. Il voit le montant total (45€) et peut modifier le don
3. Il complète le paiement sur HelloAsso
4. Après paiement, il est redirigé vers `returnUrl`

---

### **ÉTAPE 7 : Retour sur notre site**

**Action** : `GET /orders/:id` (OrdersController#show)

**Ce qui se passe** :
1. L'utilisateur revient sur notre site via `returnUrl`
2. La commande est toujours en statut "pending"
3. Un polling JavaScript vérifie le statut toutes les 5 secondes
4. Un cron job (toutes les 5 minutes) vérifie aussi le statut via l'API HelloAsso

---

### **ÉTAPE 8 : Vérification du statut (Polling)**

**Endpoint utilisé** : `GET /v5/organizations/{slug}/checkout-intents/{checkoutIntentId}`

**Ce qui est vérifié** :
1. Statut du checkout-intent
2. Présence d'un `order` dans la réponse
3. Si un `order` est présent, récupération de son statut via `GET /v5/organizations/{slug}/orders/{orderId}`

**Mise à jour locale** :
- Si `order.state == "Confirmed"` → `Payment.status = "succeeded"` et `Order.status = "paid"`
- Si `order.state == "Refused"` → `Payment.status = "failed"` et `Order.status = "failed"`
- Si pas d'`order` après 45 minutes → `Payment.status = "abandoned"`

---

## ❓ QUESTIONS À VÉRIFIER AVEC PERPLEXITY

### **1. Structure du payload checkout-intents**

**Question** : L'endpoint `POST /v5/organizations/{slug}/checkout-intents` accepte-t-il :
- ✅ `totalAmount` / `initialAmount` / `itemName` (ce qu'on envoie actuellement)
- ❓ `items` (tableau avec type "Product" et "Donation") - **ON NE L'ENVOIE PAS ACTUELLEMENT**

**Documentation à vérifier** : Est-ce que HelloAsso recommande d'envoyer les `items` individuellement plutôt qu'un `itemName` concaténé ?

---

### **2. Détails des articles**

**Question** : HelloAsso peut-il afficher les détails des articles (nom, quantité, prix) sur la page de paiement si on envoie les `items` ?

**Actuellement** : On envoie seulement `itemName: "Veste Grenoble Roller x1, Contribution à l'association x1"` (string)

**Souhaité** : Envoyer les articles individuellement pour un affichage détaillé côté HelloAsso

---

### **3. Structure metadata**

**Question** : HelloAsso utilise-t-il les données dans `metadata` pour quelque chose, ou c'est juste pour notre usage interne ?

**Actuellement** : On met `localOrderId`, `environment`, `donationCents`, et `items` dans metadata

---

### **4. Gestion du don**

**Question** : Est-ce que `containsDonation: true` + don dans `metadata` est suffisant, ou faut-il absolument envoyer un item de type "Donation" dans le payload principal ?

**Actuellement** : On utilise `containsDonation: true` mais les items (y compris le don) sont dans `metadata.items`, pas dans le payload principal

---

## 🔧 MODIFICATIONS POSSIBLES

### **Option A : Envoyer les items dans le payload principal**

Si HelloAsso accepte `items` dans le payload de `checkout-intents` :

```json
{
  "items": [
    {
      "name": "Veste Grenoble Roller",
      "quantity": 1,
      "amount": 4000,
      "type": "Product"
    },
    {
      "name": "Contribution à l'association",
      "quantity": 1,
      "amount": 500,
      "type": "Donation"
    }
  ],
  "successRedirectUrl": "...",
  "errorRedirectUrl": "...",
  "backUrl": "..."
}
```

**Avantages** :
- ✅ Détails des articles visibles sur la page HelloAsso
- ✅ Meilleure traçabilité
- ✅ Conforme à la doc HelloAsso pour `/orders`

**Inconvénients** :
- ❓ Peut-être pas supporté par `/checkout-intents` (à vérifier)

---

### **Option B : Garder la structure actuelle**

**Avantages** :
- ✅ Fonctionne actuellement (pas d'erreur 400)
- ✅ Simple

**Inconvénients** :
- ❌ Pas de détails des articles sur HelloAsso
- ❌ Seulement un `itemName` concaténé

---

## 📊 RÉSUMÉ TECHNIQUE

| Élément | Actuel | Recommandé ? |
|---------|--------|--------------|
| **Endpoint** | `POST /checkout-intents` | ✅ Correct |
| **Structure payload** | `totalAmount` + `itemName` | ❓ À vérifier si `items` est supporté |
| **Détails articles** | Dans `metadata.items` uniquement | ❓ Devrait être dans payload principal ? |
| **Don** | `containsDonation: true` + `metadata.donationCents` | ❓ Devrait être un item de type "Donation" ? |
| **Metadata** | `localOrderId`, `environment`, `items` | ✅ OK pour usage interne |

---

## 🎯 PROCHAINES ÉTAPES

1. **Vérifier avec Perplexity** si `/checkout-intents` accepte `items` dans le payload
2. **Tester** l'envoi de `items` au lieu de `itemName`
3. **Adapter** le code si nécessaire pour envoyer les détails des articles

---

**Note** : Ce document décrit l'état actuel du code. Les modifications suggérées doivent être testées avant d'être appliquées.

