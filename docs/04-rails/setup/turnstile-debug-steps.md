# 🔍 Étapes de Debug Turnstile - 422 Error

## Problème 1 : "Vous êtes déjà connecté"

Si vous voyez "Vous êtes déjà connecté" en rafraîchissant la page de connexion, c'est normal : Devise redirige les utilisateurs déjà connectés.

**Solution pour tester** :
1. **Se déconnecter d'abord** : Aller sur `/users/sign_out`
2. **OU utiliser un onglet privé/navigation privée** (Ctrl+Shift+N / Cmd+Shift+N)
3. **OU modifier la session dans la console Rails** :
   ```bash
   docker compose -f ops/dev/docker-compose.yml run --rm web bin/rails console
   > session.clear # (si possible)
   ```

---

## Problème 2 : Erreur 422 "Unprocessable Entity"

### Étape 1 : Suivre les logs en temps réel

**Dans un terminal**, lancer :
```bash
docker compose -f ops/dev/docker-compose.yml logs -f web 2>&1 | grep --line-buffered -i "turnstile\|422\|sign_in\|sessions\|verification\|failed"
```

**Dans un autre terminal ou le navigateur**, tenter une connexion.

### Étape 2 : Vérifier dans le navigateur (DevTools)

1. **Ouvrir DevTools** (F12)
2. **Onglet Network** (Réseau)
3. **Remplir le formulaire** de connexion
4. **Cliquer sur "Se connecter"**
5. **Chercher la requête POST** vers `/users/sign_in`
6. **Cliquer sur cette requête**
7. **Onglet Payload/Form Data** :
   - Vérifier que `cf-turnstile-response` est présent avec une valeur
   - Vérifier que `authenticity_token` est présent
8. **Onglet Response** :
   - Voir le message d'erreur exact renvoyé par le serveur

### Étape 3 : Vérifier la console JavaScript

**Dans DevTools → Onglet Console** :
- Y a-t-il des erreurs JavaScript ?
- Y a-t-il des messages liés à Turnstile ?

### Étape 4 : Vérifier le formulaire HTML

**Dans DevTools → Onglet Elements** :
- Chercher `<form action="/users/sign_in">`
- Vérifier qu'il contient :
  - `<input type="hidden" name="authenticity_token" value="...">`
  - `<input name="cf-turnstile-response" value="...">` (ajouté par Turnstile)

---

## Diagnostic automatique

```bash
# Script de diagnostic complet
docker compose -f ops/dev/docker-compose.yml run --rm web bin/rails runner "
puts '=== DIAGNOSTIC TURNSTILE ==='
puts ''
puts '1. Configuration:'
site_key = Rails.application.credentials.dig(:turnstile, :site_key)
secret_key = Rails.application.credentials.dig(:turnstile, :secret_key)
puts '   Site Key: ' + (site_key.present? ? '✅ Présente' : '❌ MANQUANTE')
puts '   Secret Key: ' + (secret_key.present? ? '✅ Présente' : '❌ MANQUANTE')
puts '   Environment: ' + Rails.env
puts '   Skip en test: ' + Rails.env.test?.to_s
puts ''
puts '2. Concern disponible:'
puts '   TurnstileVerifiable: ' + (defined?(TurnstileVerifiable) ? '✅' : '❌')
puts ''
puts '3. Vérification méthode:'
# Test si la méthode existe
begin
  test_controller = ActionController::Base.new
  test_controller.extend(TurnstileVerifiable)
  puts '   verify_turnstile: ✅ Disponible'
rescue => e
  puts '   verify_turnstile: ❌ Erreur - ' + e.message
end
"
```

---

## Test manuel simple

1. **Ouvrir un onglet privé** (pas de session active)
2. **Aller sur** `https://dev-grenoble-roller.flowtech-lab.org/users/sign_in`
3. **DevTools → Console**, taper :
   ```javascript
   // Vérifier si Turnstile est chargé
   console.log('Turnstile loaded:', typeof turnstile !== 'undefined');
   
   // Vérifier le widget
   const widget = document.querySelector('.cf-turnstile');
   console.log('Widget present:', widget !== null);
   
   // Vérifier le token après quelques secondes
   setTimeout(() => {
     const token = document.querySelector('input[name="cf-turnstile-response"]');
     console.log('Token generated:', token ? token.value.substring(0, 20) + '...' : 'NOT FOUND');
   }, 3000);
   ```
4. **Attendre 3-5 secondes** pour que Turnstile charge
5. **Remplir email + mot de passe**
6. **Vérifier dans Console** que le token est généré
7. **Cliquer sur "Se connecter"**
8. **Vérifier dans Network** la requête POST

---

## Causes probables du 422

### 1. Token Turnstile non généré (très probable)

**Symptômes** :
- Le bouton reste désactivé
- Dans DevTools → Elements, pas de `<input name="cf-turnstile-response">`

**Causes** :
- Script Cloudflare non chargé
- Widget non rendu
- Timeout de génération du token

**Solution** : Le JavaScript devrait attendre que le token soit généré

### 2. Token Turnstile présent mais vérification échoue

**Symptômes** :
- Token présent dans le formulaire
- Erreur 422 quand même

**Vérification** : Regarder les logs pour `Turnstile verification failed`

**Causes** :
- Clé secrète incorrecte
- Domaine non configuré dans Cloudflare
- Token expiré

### 3. Problème CSRF

**Symptômes** :
- `authenticity_token` manquant ou invalide

**Vérification** : Dans Network → Payload, vérifier `authenticity_token`

---

## Solution rapide pour tester

Si le problème persiste, **temporairement désactiver Turnstile** :

Dans `app/controllers/sessions_controller.rb`, commenter :
```ruby
# unless verify_turnstile
#   ...
# end
```

Et dans la vue, commenter la div Turnstile.

Cela permet de vérifier si le problème vient vraiment de Turnstile ou d'autre chose.

