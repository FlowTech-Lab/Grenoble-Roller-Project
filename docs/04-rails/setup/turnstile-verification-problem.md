# ⚠️ Problème Identifié : Turnstile ne bloque pas l'authentification

**Date** : 2025-12-08  
**Statut** : 🔍 En diagnostic

---

## 🔴 Problème

Même après correction du code pour bloquer l'authentification si Turnstile échoue :
- Erreur 422 retournée ✅
- Mais l'utilisateur est quand même connecté après refresh ❌

---

## 🔍 Diagnostic Effectué

### Tests Réalisés

1. ✅ **Vérification inclusion TurnstileVerifiable** : OK
2. ✅ **Vérification méthode verify_turnstile accessible** : OK
3. ✅ **Vérification code contrôleur** : Structure correcte avec `return false`
4. ✅ **Test méthode verify_turnstile** : Retourne bien `false` sans token

### Code Actuel

```ruby
def create
  # ... logs ...
  
  unless verify_turnstile
    Rails.logger.warn("Turnstile verification FAILED - BLOCKING authentication")
    self.resource = resource_class.new(sign_in_params)
    flash.now[:alert] = "Vérification de sécurité échouée."
    render :new, status: :unprocessable_entity
    return false # ← Devrait bloquer complètement
  end

  super do |resource|
    # ... authentification Devise ...
  end
end
```

---

## 🤔 Hypothèses

### Hypothèse 1 : Turbo fait une seconde requête

Après un 422, Turbo pourrait faire automatiquement une requête GET qui pourrait authentifier l'utilisateur.

**Test** : Vérifier dans DevTools → Network si une seconde requête est faite après le 422.

### Hypothèse 2 : verify_turnstile retourne true par défaut

En développement, si la clé secrète est manquante, `verify_turnstile` retourne `true` par défaut.

**Correction appliquée** : Ajout d'un log d'avertissement quand la vérification est skippée.

### Hypothèse 3 : Le return ne bloque pas complètement

Même avec `return false`, quelque chose dans Devise pourrait continuer.

**À vérifier** : Vérifier les logs pour voir si `super` est appelé même après le `return`.

### Hypothèse 4 : Session créée ailleurs

La session pourrait être créée dans un callback ou middleware avant même que le contrôleur ne soit appelé.

**À vérifier** : Vérifier les middlewares et callbacks Devise.

---

## 🧪 Tests à Effectuer

### Test 1 : Vérifier les logs complets

```bash
docker compose -f ops/dev/docker-compose.yml logs -f web 2>&1 | tee /tmp/turnstile-logs.txt
```

Puis tenter une connexion et vérifier :
- ✅ `Turnstile verification FAILED - BLOCKING` apparaît
- ❌ **PAS** de `Turnstile verification PASSED` après
- ❌ **PAS** de `Processing by SessionsController#create` après le FAILED

### Test 2 : Vérifier dans DevTools (Network)

1. Ouvrir DevTools → Network
2. Tenter une connexion sans token Turnstile
3. Vérifier :
   - Nombre de requêtes faites
   - Status codes de chaque requête
   - Si une requête GET est faite après le 422

### Test 3 : Vérifier la session

Après un échec Turnstile :
```ruby
# Dans Rails console
session_id = # récupérer depuis les logs
# Vérifier si une session existe pour cet ID
```

---

## 📝 Actions Correctives Appliquées

1. ✅ Inclusion explicite de `TurnstileVerifiable` dans `SessionsController`
2. ✅ Inclusion explicite de `TurnstileVerifiable` dans `RegistrationsController`
3. ✅ Ajout de logs détaillés dans `verify_turnstile`
4. ✅ Ajout de log d'avertissement si vérification skippée en dev
5. ✅ Changement de `return false` à simplement `return`

---

## 🔧 Prochaines Étapes

1. **Tester avec les logs complets** pour voir exactement ce qui se passe
2. **Vérifier DevTools Network** pour voir si Turbo fait des requêtes supplémentaires
3. **Vérifier si la session est créée ailleurs** (middleware, callback)
4. **Tester en désactivant complètement Turnstile temporairement** pour isoler le problème

---

**Version** : 1.0  
**Date de création** : 2025-12-08

