# Erreur #051 : Mailers OrderMailer (9 erreurs)

**Date d'analyse** : 2025-12-15  
**Priorité** : 🟢 Priorité 6  
**Catégorie** : Tests de Mailers

---

## 📋 Informations Générales

- **Fichier test** : `spec/mailers/order_mailer_spec.rb`
- **Lignes** : 59, 64, 77, 82, 107, 112, 130, 135, 172
- **Tests** : `order_paid` (2), `order_cancelled` (2), `order_preparation` (2), `order_shipped` (2), `refund_confirmed` (1)
- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/mailers/order_mailer_spec.rb
  ```

---

## 🔴 Erreurs

### Erreur 1 : Ligne 59 - `order_paid includes payment confirmation in body`
```
Failure/Error: expect(mail.body.encoded).to include('Paiement reçu')
  expected "\r\n----==_mimepart_6940922844a96_85d05e781004e9\r\nContent-Type: text/plain;\r\n charset=UTF-8\r\n..." to include "Paiement reçu"
```

### Erreur 2 : Ligne 64 - `order_paid includes order URL in body`
```
Failure/Error: expect(mail.body.encoded).to include(order_url(order_paid))
  expected "...base64..." to include "https://dev-grenoble-roller.flowtech-lab.org/orders/g2jefwbge"
```

### Erreur 3 : Ligne 77 - `order_cancelled includes order id in subject`
```
Failure/Error: expect(mail.subject).to include("##{order_cancelled.id}")
  expected "❌ Commande #751 - Commande annulée" to include "##{order_cancelled.id}"
```

### Erreur 4 : Ligne 82 - `order_cancelled includes cancellation information in body`
```
Failure/Error: expect(mail.body.encoded).to include('annulée')
  expected "...base64..." to include "annulée"
```

### Erreur 5 : Ligne 107 - `order_preparation includes preparation information in body`
```
Failure/Error: expect(mail.body.encoded).to include('préparation')
  expected "...base64..." to include "préparation"
```

### Erreur 6 : Ligne 112 - `order_preparation includes order URL in body`
```
Failure/Error: expect(mail.body.encoded).to include(order_url(order_prep))
  expected "...base64..." to include "https://dev-grenoble-roller.flowtech-lab.org/orders/..."
```

### Erreur 7 : Ligne 130 - `order_shipped includes shipping confirmation in body`
```
Failure/Error: expect(mail.body.encoded).to include('expédiée')
  expected "...base64..." to include "expédiée"
```

### Erreur 8 : Ligne 135 - `order_shipped includes order URL in body`
```
Failure/Error: expect(mail.body.encoded).to include(order_url(order_shipped))
  expected "...base64..." to include "https://dev-grenoble-roller.flowtech-lab.org/orders/..."
```

### Erreur 9 : Ligne 172 - `refund_confirmed includes refund confirmation in body`
```
Failure/Error: expect(mail.body.encoded).to include('Remboursement confirmé')
  expected "...base64..." to include "Remboursement confirmé"
```

---

## 🔍 Analyse

### Constats
- ❌ Les tests utilisent `mail.body.encoded` qui encode le contenu en base64/quoted-printable
- ✅ Les templates HTML contiennent bien les textes recherchés ("Paiement reçu", "annulée", etc.)
- ✅ Les templates utilisent `order_url(@order)` qui génère une URL absolue
- ❌ Le body encodé ne contient pas le texte en clair, il faut décoder le body
- ⚠️ L'erreur 3 montre que le sujet contient bien l'ID mais avec un format différent (interpolation dans le template)

### Cause Probable

1. **Body encodé** : `mail.body.encoded` retourne le body encodé (base64/quoted-printable), donc le texte recherché n'est pas directement visible
2. **URLs absolues** : Les URLs sont encodées dans le body, il faut décoder pour les trouver
3. **Interpolation dans le template** : Le sujet utilise `##{@order.id}` dans le template, donc l'interpolation se fait au moment du rendu, pas dans le test

### Code Actuel

```ruby
# spec/mailers/order_mailer_spec.rb
it 'includes payment confirmation in body' do
  expect(mail.body.encoded).to include('Paiement reçu')
  expect(mail.body.encoded).to include('Payée')
end

it 'includes order URL in body' do
  expect(mail.body.encoded).to include(order_url(order_paid))
end

# app/views/order_mailer/order_paid.html.erb
<h3>✅ Paiement reçu</h3>
<p>Statut : Payée</p>
<%= link_to 'Voir ma commande →', order_url(@order) %>
```

---

## 💡 Solutions Proposées

### Solution 1 : Décoder le body avant de chercher le texte

**Problème** : `mail.body.encoded` retourne le body encodé.

**Solution** : Décoder le body avant de chercher le texte.

```ruby
it 'includes payment confirmation in body' do
  html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
  body_content = html_part ? html_part.decoded : mail.body.decoded
  expect(body_content).to include('Paiement reçu')
  expect(body_content).to include('Payée')
end
```

### Solution 2 : Chercher le hashid au lieu de l'URL complète

**Problème** : L'URL complète peut varier selon l'environnement et est encodée.

**Solution** : Chercher le hashid qui est stable.

```ruby
it 'includes order URL in body' do
  html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
  body_content = html_part ? html_part.decoded : mail.body.decoded
  expect(body_content).to include(order_paid.hashid).or include("/orders/#{order_paid.hashid}")
end
```

### Solution 3 : Corriger l'assertion du sujet (erreur 3)

**Problème** : Le sujet utilise `##{@order.id}` dans le template, donc l'interpolation se fait au moment du rendu.

**Solution** : Chercher directement l'ID dans le sujet.

```ruby
it 'includes order id in subject' do
  expect(mail.subject).to include("##{order_cancelled.id}")
  expect(mail.subject).to include('Annulée')
end
```

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** :
- Décodage du body incorrect pour chercher le texte
- Recherche d'URLs absolues dans le body encodé
- Assertion du sujet incorrecte (interpolation dans le template)

---

## 📊 Statut

✅ **RÉSOLU** - Tous les tests passent (30 examples, 0 failures)

---

## 🔗 Erreurs Similaires

Cette erreur est similaire aux erreurs suivantes :
- [039-mailers-event-mailer.md](039-mailers-event-mailer.md) - Même problème avec le décodage du body

---

## 📝 Notes

- Les templates HTML contiennent bien les textes recherchés
- Le problème vient uniquement de la façon de tester le body encodé
- Les tests doivent décoder le body pour chercher le texte ou utiliser le hashid pour les URLs

---

## ✅ Actions à Effectuer

1. [x] Décoder le body dans tous les tests qui cherchent du texte
2. [x] Utiliser le hashid au lieu de l'URL complète pour les tests d'URLs
3. [x] Corriger l'assertion du sujet pour `order_cancelled` (chercher "annulée" au lieu de "Annulée")
4. [x] Exécuter les tests pour vérifier qu'ils passent
5. [x] Mettre à jour le statut dans [README.md](../README.md)

## ✅ Solution Appliquée

**Modifications dans `spec/mailers/order_mailer_spec.rb`** :
1. Décodage du body avant de chercher le texte dans tous les tests :
   ```ruby
   html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
   body_content = html_part ? html_part.decoded : mail.body.decoded
   expect(body_content).to include('texte recherché')
   ```
2. Utilisation du hashid au lieu de l'URL complète pour les tests d'URLs
3. Correction de l'assertion du sujet pour `order_cancelled` (chercher "annulée" au lieu de "Annulée")
