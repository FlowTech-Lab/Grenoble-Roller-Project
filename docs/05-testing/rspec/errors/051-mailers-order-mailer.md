# Erreur #051-080 : Mailers OrderMailer (30 erreurs)

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟡 Priorité 6  
**Catégorie** : Tests de Mailers

---

## 📋 Informations Générales

- **Fichier test** : `spec/mailers/order_mailer_spec.rb`
- **Lignes** : 11, 15, 20, 25, 29, 33, 38, 48, 52, 57, 62, 71, 75, 80, 85, 94, 98, 103, 108, 117, 121, 126, 131, 140, 144, 149, 159, 163, 168, 173
- **Tests** : Tests pour `order_confirmation`, `order_paid`, `order_cancelled`, `order_preparation`, `order_shipped`, `refund_requested`, `refund_confirmed`

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/mailers/order_mailer_spec.rb
  ```

---

## 🔴 Erreur

⏳ **À ANALYSER** - Exécuter les tests pour voir les erreurs exactes

---

## 🔍 Analyse

### Constats
- ⏳ Erreurs non encore analysées
- 🔍 Problème probable avec les templates de mailers
- ⚠️ Probablement problème avec les helpers `_path` vs `_url` dans les templates

---

## 💡 Solutions Proposées

⏳ **À DÉTERMINER** après analyse

---

## 🎯 Type de Problème

⚠️ **À ANALYSER** (probablement ⚠️ **PROBLÈME DE LOGIQUE** - templates ou helpers)

---

## 📊 Statut

⏳ **À ANALYSER**

---

## 🔗 Erreurs Similaires

Cette erreur est similaire à :
- [039-mailers-event-mailer.md](039-mailers-event-mailer.md)
- [043-mailers-membership-mailer.md](043-mailers-membership-mailer.md)
- [081-mailers-user-mailer.md](081-mailers-user-mailer.md)

---

## ✅ Actions à Effectuer

1. [ ] Exécuter les tests pour voir les erreurs exactes
2. [ ] Vérifier les templates de mailers
3. [ ] Analyser chaque erreur et documenter
4. [ ] Identifier le type de problème (test ou logique)
5. [ ] Proposer des solutions
6. [ ] Mettre à jour le statut dans [README.md](../README.md)

---

## 📝 Liste Détaillée des Erreurs

| Ligne | Test | Statut |
|-------|------|--------|
| 11 | OrderMailer#order_confirmation sends to user email | ⏳ À analyser |
| 15 | OrderMailer#order_confirmation includes order id in subject | ⏳ À analyser |
| 20 | OrderMailer#order_confirmation includes order details in body | ⏳ À analyser |
| 25 | OrderMailer#order_confirmation includes user first name in body | ⏳ À analyser |
| 29 | OrderMailer#order_confirmation includes order URL in body | ⏳ À analyser |
| 33 | OrderMailer#order_confirmation has HTML content | ⏳ À analyser |
| 38 | OrderMailer#order_confirmation has text content as fallback | ⏳ À analyser |
| 48 | OrderMailer#order_paid sends to user email | ⏳ À analyser |
| 52 | OrderMailer#order_paid includes order id in subject | ⏳ À analyser |
| 57 | OrderMailer#order_paid includes payment confirmation in body | ⏳ À analyser |
| 62 | OrderMailer#order_paid includes order URL in body | ⏳ À analyser |
| 71 | OrderMailer#order_cancelled sends to user email | ⏳ À analyser |
| 75 | OrderMailer#order_cancelled includes order id in subject | ⏳ À analyser |
| 80 | OrderMailer#order_cancelled includes cancellation information in body | ⏳ À analyser |
| 85 | OrderMailer#order_cancelled includes orders URL in body | ⏳ À analyser |
| 94 | OrderMailer#order_preparation sends to user email | ⏳ À analyser |
| 98 | OrderMailer#order_preparation includes order id in subject | ⏳ À analyser |
| 103 | OrderMailer#order_preparation includes preparation information in body | ⏳ À analyser |
| 108 | OrderMailer#order_preparation includes order URL in body | ⏳ À analyser |
| 117 | OrderMailer#order_shipped sends to user email | ⏳ À analyser |
| 121 | OrderMailer#order_shipped includes order id in subject | ⏳ À analyser |
| 126 | OrderMailer#order_shipped includes shipping confirmation in body | ⏳ À analyser |
| 131 | OrderMailer#order_shipped includes order URL in body | ⏳ À analyser |
| 140 | OrderMailer#refund_requested sends to user email | ⏳ À analyser |
| 144 | OrderMailer#refund_requested includes order id in subject | ⏳ À analyser |
| 149 | OrderMailer#refund_requested includes refund request information in body | ⏳ À analyser |
| 159 | OrderMailer#refund_confirmed sends to user email | ⏳ À analyser |
| 163 | OrderMailer#refund_confirmed includes order id in subject | ⏳ À analyser |
| 168 | OrderMailer#refund_confirmed includes refund confirmation in body | ⏳ À analyser |
| 173 | OrderMailer#refund_confirmed includes orders URL in body | ⏳ À analyser |

