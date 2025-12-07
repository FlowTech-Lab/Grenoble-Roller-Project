# Prompt Perplexity : Confirmation Email - Lien Token vs Code 6 Chiffres

## Prompt à copier-coller dans Perplexity

```
Comparaison sécurité et UX entre deux méthodes de confirmation d'email pour une application web Rails/Devise :

1. **Lien avec token** (méthode actuelle Devise)
   - Email contient un lien cliquable avec token unique dans l'URL
   - Exemple : https://example.com/confirm?token=abc123...
   - Un clic confirme automatiquement

2. **Code à 6 chiffres** (OTP)
   - Email contient un code numérique à 6 chiffres
   - L'utilisateur doit copier-coller ou saisir le code dans un formulaire
   - Exemple : Code : 456789

Pour une association de roller (Grenoble Roller), quel système est le meilleur en termes de :
- Sécurité (protection contre attaques, token hijacking, etc.)
- Expérience utilisateur (facilité d'utilisation, taux de confirmation)
- Implémentation (complexité, maintenance avec Devise)
- Accessibilité (mobiles, clients email limités)

Quels sont les avantages/inconvénients de chaque méthode ?
Quelle méthode recommandez-vous et pourquoi ?
```

## Contexte actuel

**Système implémenté :** Lien avec token (méthode standard Devise)

**Ce qui est en place :**
- Email avec lien cliquable `confirmation_url(@resource, confirmation_token: @token)`
- Token unique stocké en base de données
- Lien valable 3 jours
- Protection rate limiting
- Template HTML stylé + version texte

**Fichiers concernés :**
- `app/views/devise/mailer/confirmation_instructions.html.erb`
- `app/views/devise/mailer/confirmation_instructions.text.erb`
- `app/controllers/confirmations_controller.rb`

---

## Résumé

**Méthode actuelle : Lien avec token**
- ✅ Standard Devise (pas de code custom)
- ✅ Simple : un clic = confirmation
- ✅ Pas de saisie manuelle
- ⚠️ URL longue avec token visible
- ⚠️ Risque si email compromis

**Alternative : Code à 6 chiffres (OTP)**
- ✅ Code court, facile à retenir
- ✅ Pas de lien cliquable = plus sûr si email compromis
- ✅ Meilleur pour mobile (copier-coller facile)
- ⚠️ Nécessite code custom (pas standard Devise)
- ⚠️ Saisie manuelle = friction UX
- ⚠️ Plus complexe à implémenter

---

**Voulez-vous que je modifie l'implémentation pour utiliser un code à 6 chiffres, ou garder le lien avec token ?**
