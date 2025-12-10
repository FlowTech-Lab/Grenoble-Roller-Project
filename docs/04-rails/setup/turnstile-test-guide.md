# 🧪 Guide de Test Turnstile - Validation Correcte

**Date de création** : 2025-12-08  
**Objectif** : Vérifier que Turnstile bloque correctement les requêtes si la vérification échoue

---

## ⚠️ Problème Identifié

**Symptôme** : 
- Erreur 422 "Unprocessable Entity"
- Mais après refresh, l'utilisateur est connecté quand même
- **Cause** : L'authentification Devise se faisait même si Turnstile échouait

**Solution** : Blocage complet avant d'appeler `super` dans Devise

---

## ✅ Test de Validation Correcte

### Test 1 : Vérifier que Turnstile bloque l'authentification

**Scénario** : Tenter une connexion SANS token Turnstile valide

**Étapes** :
1. **Ouvrir un onglet privé** (pas de session)
2. **Aller sur** `/users/sign_in`
3. **DevTools → Console**, exécuter :
   ```javascript
   // Supprimer le token Turnstile (simuler échec)
   const form = document.querySelector('form[action*="session"]');
   const tokenInput = form.querySelector('input[name="cf-turnstile-response"]');
   if (tokenInput) tokenInput.remove();
   ```
4. **Remplir email + mot de passe**
5. **Cliquer sur "Se connecter"**

**Résultat attendu** :
- ✅ Erreur 422
- ✅ Message "Vérification de sécurité échouée"
- ✅ **L'utilisateur N'EST PAS connecté** (vérifier après refresh)
- ✅ Dans les logs : `Turnstile verification FAILED - BLOCKING authentication`

### Test 2 : Vérifier que Turnstile permet l'authentification

**Scénario** : Tenter une connexion AVEC token Turnstile valide

**Étapes** :
1. **Ouvrir un onglet privé**
2. **Aller sur** `/users/sign_in`
3. **Attendre 3-5 secondes** que Turnstile charge
4. **DevTools → Console**, vérifier :
   ```javascript
   const form = document.querySelector('form[action*="session"]');
   const tokenInput = form.querySelector('input[name="cf-turnstile-response"]');
   console.log('Token present:', tokenInput !== null);
   console.log('Token value:', tokenInput ? tokenInput.value.substring(0, 20) + '...' : 'NONE');
   ```
5. **Remplir email + mot de passe VALIDES**
6. **Cliquer sur "Se connecter"**

**Résultat attendu** :
- ✅ Pas d'erreur 422
- ✅ Connexion réussie
- ✅ Redirection vers la page d'accueil
- ✅ Dans les logs : `Turnstile verification PASSED, proceeding with authentication`

---

## 🔍 Vérification dans les Logs

### Commandes pour vérifier

```bash
# Suivre les logs en temps réel
docker compose -f ops/dev/docker-compose.yml logs -f web 2>&1 | grep --line-buffered -i "turnstile\|sessions.*create\|verification\|failed\|passed"
```

### Logs attendus

**Si Turnstile échoue** :
```
SessionsController#create - IP: xxx.xxx.xxx.xxx
Params keys: [...]
Token present: false
Turnstile verification failed: No token provided...
SessionsController#create - Turnstile verification FAILED - BLOCKING authentication
```

**Si Turnstile réussit** :
```
SessionsController#create - IP: xxx.xxx.xxx.xxx
Params keys: ["cf-turnstile-response"]
Token present: true
Turnstile verification successful for IP...
SessionsController#create - Turnstile verification PASSED, proceeding with authentication
```

---

## 🐛 Diagnostic si Test 1 Échoue

Si l'utilisateur est quand même connecté après un échec Turnstile :

### Vérifier le code

```bash
# Vérifier que le return est bien présent
grep -A 10 "unless verify_turnstile" app/controllers/sessions_controller.rb
```

**Doit contenir** :
```ruby
unless verify_turnstile
  # ... logs ...
  respond_with(resource, location: new_user_session_path)
  return  # ← CRITIQUE : doit être là
end
```

### Vérifier que super n'est pas appelé

Les logs doivent montrer :
- ✅ `Turnstile verification FAILED - BLOCKING`
- ❌ **PAS** de `Processing by SessionsController#create` après le FAILED

---

## 📋 Checklist de Validation

- [ ] Test 1 : Connexion SANS token → Échec 422 + Utilisateur NON connecté
- [ ] Test 2 : Connexion AVEC token valide → Succès + Utilisateur connecté
- [ ] Logs montrent "BLOCKING authentication" en cas d'échec
- [ ] Logs montrent "PASSED, proceeding" en cas de succès
- [ ] Après échec Turnstile, refresh de la page → Utilisateur toujours déconnecté
- [ ] Après succès Turnstile, refresh de la page → Utilisateur toujours connecté

---

## 🔧 Test avec Clés de Test Cloudflare

Pour tester sans dépendre des vraies clés :

**Dans Rails credentials**, utiliser temporairement :
```yaml
turnstile:
  site_key: 1x00000000000000000000AA
  secret_key: 1x0000000000000000000000000000000AA
```

**Ces clés de test** :
- ✅ Fonctionnent toujours (pas de limite)
- ✅ Retournent toujours `success: true`
- ✅ Permettent de tester le flux complet sans vraie vérification

---

**Version** : 1.0  
**Date de création** : 2025-12-08

