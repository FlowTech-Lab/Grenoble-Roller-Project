# 🔍 Turnstile - Dépannage 422

## Problème : Erreur 422 "Unprocessable Entity"

L'erreur 422 vient du `SessionsController` ou `RegistrationsController` qui retourne ce statut quand `verify_turnstile` échoue.

---

## Causes possibles

### 1. Token Turnstile non généré au moment du submit

**Symptôme** : Le widget Turnstile n'a pas eu le temps de générer le token avant la soumission.

**Solution** : JavaScript ajouté pour :
- Désactiver le bouton submit jusqu'à ce que le token soit généré
- Vérifier que le token est présent avant de soumettre

**Vérification** :
- Ouvrir DevTools (F12)
- Onglet Elements
- Chercher `<input name="cf-turnstile-response">` dans le formulaire
- Vérifier qu'il a une valeur avant de cliquer sur "Se connecter"

---

### 2. Token Turnstile non récupéré côté serveur

**Symptôme** : Le token est dans le formulaire mais pas récupéré par Rails.

**Vérification dans les logs** :
```bash
docker compose -f ops/dev/docker-compose.yml logs web | grep -i "turnstile\|cf-turnstile"
```

**Logs à rechercher** :
- `Turnstile verification failed: No token provided`
- `Available params keys: ...`

**Solution** : Le concern `TurnstileVerifiable` vérifie maintenant les deux formats :
- `params['cf-turnstile-response']`
- `params[:'cf-turnstile-response']`

---

### 3. Vérification Cloudflare échoue

**Symptôme** : Le token est présent mais Cloudflare le rejette.

**Vérification dans les logs** :
```bash
docker compose -f ops/dev/docker-compose.yml logs web | grep -i "verification failed"
```

**Causes communes** :
- Clé secrète incorrecte dans les credentials
- Domaine non configuré dans Cloudflare Dashboard
- Token expiré (trop de temps entre génération et soumission)

**Solutions** :
1. Vérifier que `turnstile.secret_key` est correcte dans Rails credentials
2. Vérifier que le domaine est bien configuré dans Cloudflare Turnstile Dashboard
3. Le JavaScript attend maintenant que le token soit frais avant de permettre la soumission

---

### 4. Mode Managed nécessite interaction

**Symptôme** : Cloudflare demande une interaction (checkbox) mais l'utilisateur ne la voit pas.

**Solution actuelle** : Mode "normal" qui affiche toujours le widget de manière visible.

**Si besoin de mode invisible** :
- Changer `data-size="normal"` en `data-size="invisible"`
- Mais attention : peut causer des 422 si interaction requise

---

## Diagnostic rapide

### Commande pour vérifier les logs Turnstile

```bash
docker compose -f ops/dev/docker-compose.yml logs web --tail=200 | grep -A 5 -B 5 -i "turnstile\|422\|unprocessable"
```

### Vérifier que les clés sont configurées

```bash
docker compose -f ops/dev/docker-compose.yml run --rm web bin/rails runner "
  site_key = Rails.application.credentials.dig(:turnstile, :site_key)
  secret_key = Rails.application.credentials.dig(:turnstile, :secret_key)
  puts 'Site Key: ' + (site_key.present? ? '✅ Présente (' + site_key.first(20) + '...)' : '❌ MANQUANTE')
  puts 'Secret Key: ' + (secret_key.present? ? '✅ Présente' : '❌ MANQUANTE')
"
```

### Vérifier dans le navigateur

1. Ouvrir DevTools (F12)
2. Onglet Network
3. Soumettre le formulaire
4. Chercher la requête POST vers `/users/sign_in`
5. Onglet Payload ou Form Data
6. Vérifier la présence de `cf-turnstile-response` avec une valeur

---

## Solutions implémentées

### 1. Amélioration du logging

Le concern `TurnstileVerifiable` log maintenant :
- Si le token est manquant (avec la liste des params disponibles)
- Si la vérification Cloudflare échoue (avec les codes d'erreur)
- Les succès de vérification (en mode debug)

### 2. Protection JavaScript

Le JavaScript :
- Désactive le bouton submit jusqu'à ce que le token soit généré
- Vérifie que le token est présent avant de soumettre
- Affiche un message si la vérification est en cours

### 3. Vérification serveur robuste

Le concern vérifie :
- Les deux formats de paramètres (`params['cf-turnstile-response']` et `params[:'cf-turnstile-response']`)
- Skip en test (pour les tests automatisés)
- Skip en dev si clé secrète manquante (pour faciliter le développement)

---

## Test manuel

1. Ouvrir la page de connexion
2. Ouvrir DevTools (F12) → Onglet Console
3. Attendre que le widget Turnstile s'affiche
4. Vérifier dans Elements qu'un `<input name="cf-turnstile-response">` est présent dans le formulaire
5. Remplir email + mot de passe
6. Le bouton "Se connecter" devrait être activé automatiquement
7. Cliquer sur "Se connecter"
8. Vérifier dans Network que `cf-turnstile-response` est présent dans la requête POST

---

## Si le problème persiste

### Vérifier la configuration Cloudflare

1. Aller sur https://dash.cloudflare.com/
2. Security → Turnstile
3. Vérifier que le site est configuré avec :
   - **Domaines** : `dev-grenoble-roller.flowtech-lab.org` (pour dev)
   - **Widget Mode** : `Managed` ou `Non-interactive`
   - **Site Key** : Correspond à celle dans Rails credentials

### Tester avec les clés de test Cloudflare

Temporairement, utiliser les clés de test :
- Site Key : `1x00000000000000000000AA`
- Secret Key : `1x0000000000000000000000000000000AA`

Cela permet de vérifier si le problème vient de la configuration Cloudflare ou du code.

---

**Version** : 1.0  
**Date de création** : 2025-12-07

