# 🔍 Comment Vérifier que Turnstile Fonctionne

**Mode invisible = Rien de visible pour l'utilisateur !**

Turnstile en mode invisible fonctionne complètement en arrière-plan. Voici comment vérifier qu'il fonctionne correctement.

---

## ✅ Méthode 1 : DevTools du Navigateur (Recommandé)

### Étapes

1. **Ouvrir la page de connexion/inscription** dans votre navigateur
2. **Ouvrir les DevTools** : `F12` (Windows/Linux) ou `Cmd+Option+I` (Mac)
3. **Aller dans l'onglet Network** (Réseau)
4. **Soumettre le formulaire** (cliquer sur "Se connecter" ou "Créer mon compte")

### Ce que vous devriez voir

✅ **Requêtes réussies** :
- `challenges.cloudflare.com/turnstile/v0/api.js` - Chargement du script (au chargement de la page)
- `challenges.cloudflare.com/turnstile/v0/siteverify` - Vérification du token (à la soumission)

✅ **Status 200** pour ces requêtes

❌ **Si vous ne voyez pas ces requêtes** :
- Turnstile n'est peut-être pas configuré
- Vérifiez que la `site_key` est présente dans les credentials

### Console JavaScript

Dans l'onglet **Console**, vous ne devriez **pas** voir d'erreurs comme :
- `turnstile is not defined`
- `Cannot read property 'render' of undefined`

---

## ✅ Méthode 2 : Logs Rails

### Vérifier les logs en temps réel

```bash
docker compose -f ops/dev/docker-compose.yml logs -f web | grep -i turnstile
```

### Ce que vous devriez voir

✅ **Pas de logs Turnstile** = Normal (si tout fonctionne, pas de log)

❌ **Logs d'erreur** :
- `Turnstile verification failed: ...` = Vérification échouée
- `Turnstile verification error: ...` = Erreur technique

### Vérifier après une tentative de connexion

```bash
docker compose -f ops/dev/docker-compose.yml logs web | grep -i "turnstile\|verification"
```

---

## ✅ Méthode 3 : Test Simple - Clés Manquantes vs Présentes

### Test 1 : Sans clé Turnstile (développement)

**Configuration** : Pas de `turnstile.site_key` dans les credentials

**Résultat attendu** :
- Le formulaire se soumet normalement
- Pas de vérification Turnstile
- C'est normal en développement (skip si clé manquante)

### Test 2 : Avec clé Turnstile

**Configuration** : `turnstile.site_key` et `turnstile.secret_key` présents

**Résultat attendu** :
- Le formulaire attend la vérification Turnstile (invisible)
- Si vérification réussit → Connexion/Inscription OK
- Si vérification échoue → Message "Vérification de sécurité échouée"

---

## ✅ Méthode 4 : Vérifier les Clés dans Rails

### Vérifier que la Site Key est présente

```bash
docker compose -f ops/dev/docker-compose.yml run --rm web bin/rails runner "puts Rails.application.credentials.dig(:turnstile, :site_key) || '❌ Site Key MANQUANTE'"
```

**Résultat attendu** : Une clé qui commence par `0x...` ou `1x...`

### Vérifier que la Secret Key est présente

```bash
docker compose -f ops/dev/docker-compose.yml run --rm web bin/rails runner "puts Rails.application.credentials.dig(:turnstile, :secret_key).present? ? '✅ Secret Key OK' : '❌ Secret Key MANQUANTE'"
```

**Résultat attendu** : `✅ Secret Key OK`

---

## ✅ Méthode 5 : Mode Visible Temporaire (Pour voir Turnstile)

Pour **voir** Turnstile en action, changez temporairement le mode :

### Modifier la vue

Dans `app/views/devise/sessions/new.html.erb` ou `app/views/devise/registrations/new.html.erb`, changez :

```erb
data-size="invisible"  <!-- Mode invisible -->
```

En :

```erb
data-size="normal"  <!-- Mode visible -->
```

### Utiliser les clés de test Cloudflare

Ajoutez temporairement ces clés dans les credentials :

```yaml
turnstile:
  site_key: 1x00000000000000000000AA
  secret_key: 1x0000000000000000000000000000000AA
```

**Résultat** : Vous verrez maintenant le widget Turnstile visible (petit captcha)

⚠️ **Important** : Remettez `invisible` et les vraies clés après le test !

---

## ✅ Méthode 6 : Vérifier dans le Code Source HTML

1. Ouvrir la page de connexion/inscription
2. Clic droit → **Afficher le code source de la page**
3. Rechercher : `cf-turnstile`

**Ce que vous devriez voir** :

```html
<div class="cf-turnstile" 
     data-sitekey="0x4AAAAA..." 
     data-theme="light"
     data-size="invisible">
</div>
```

Si cette div est présente avec une `site_key` valide, Turnstile est bien chargé.

---

## ❌ Signes que Turnstile ne fonctionne PAS

### 1. Pas de requête Cloudflare dans Network tab
- **Cause** : Script non chargé ou clé manquante
- **Solution** : Vérifier les credentials et la console JavaScript

### 2. Message "Vérification de sécurité échouée"
- **Cause** : Vérification côté serveur échoue
- **Solution** : Vérifier la `secret_key` et les logs Rails

### 3. Erreur JavaScript dans la console
- **Cause** : Script Cloudflare non chargé
- **Solution** : Vérifier la connexion internet et les DevTools Network tab

### 4. Le formulaire se soumet sans vérification
- **Cause** : Turnstile non déclenché (JavaScript ou clé manquante)
- **Solution** : Vérifier les credentials et le script JavaScript

---

## 📝 Checklist de Vérification Rapide

- [ ] Clés Turnstile configurées dans Rails credentials
- [ ] Script Cloudflare chargé (Network tab → `api.js`)
- [ ] Widget présent dans le HTML (`cf-turnstile` div)
- [ ] Pas d'erreurs JavaScript dans la console
- [ ] Requête `siteverify` lors de la soumission (Network tab)
- [ ] Logs Rails sans erreurs Turnstile
- [ ] Message "Vérification de sécurité échouée" si clés incorrectes (test négatif)

---

**Version** : 1.0  
**Date de création** : 2025-12-07

