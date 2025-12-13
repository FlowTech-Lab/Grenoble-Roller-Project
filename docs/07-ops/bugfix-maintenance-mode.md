# Bugfix : Mode maintenance et Health Check HTTP

**Date** : 2025-01-20  
**Status** : ✅ Corrigé  
**Problèmes identifiés et corrigés** : 3 erreurs critiques

---

## 🐛 Problèmes identifiés

### 1. **Erreur : Health check HTTP échoue (code: 000000)**
```
ERROR:   ❌ HTTP endpoint échoué (code: 000000)
```

**Cause** : Le health check tentait de tester `http://localhost:3000/up` depuis l'hôte, mais le port 3000 n'est pas exposé sur l'hôte (seulement dans le réseau Docker interne).

**Solution** : Le health check teste maintenant depuis le conteneur lui-même où curl est disponible.

### 2. **Problème : Application arrêtée pendant le déploiement**
L'application était arrêtée avec `docker compose down`, causant un downtime complet.

**Solution** : Utilisation du mode maintenance au lieu d'arrêter l'application.

### 3. **Erreur : Crontab non installé**
```
WARNING: ⚠️  Échec de l'installation du crontab
```

**Cause** : Le script tentait d'exécuter `bundle exec whenever` depuis l'hôte, mais bundle/whenever ne sont disponibles que dans le conteneur.

**Solution** : Le crontab est maintenant installé depuis le conteneur.

---

## ✅ Corrections appliquées

### 1. Mode maintenance intégré dans le déploiement

**Nouveau module** : `ops/lib/deployment/maintenance.sh`
- `enable_maintenance_mode()` : Active le mode maintenance
- `disable_maintenance_mode()` : Désactive le mode maintenance
- `check_maintenance_status()` : Vérifie le statut
- `is_maintenance_enabled()` : Retourne true/false

**Intégration dans `deploy.sh`** :
- Activation du mode maintenance AVANT le build (évite downtime)
- Désactivation AVANT le health check final

**Intégration dans `rollback.sh`** :
- Activation du mode maintenance AVANT l'arrêt de l'application
- Désactivation après rollback réussi

**Intégration dans `compose.sh`** :
- Activation du mode maintenance AVANT `docker compose down` lors d'un rebuild sans cache

### 2. Health check HTTP corrigé

**Avant** :
```bash
# Testait depuis l'hôte (ne fonctionnait pas)
curl -s -w "%{http_code}" "http://localhost:3000/up"
```

**Après** :
```bash
# Teste depuis le conteneur (où curl est disponible)
$DOCKER_CMD exec "$container" curl -s -w "%{http_code}" "http://localhost:3000/up"

# Fallback : wget si curl non disponible
# Fallback : reverse proxy (port 80) depuis l'hôte
```

### 3. Installation crontab depuis le conteneur

**Avant** :
```bash
# Tentait depuis l'hôte (bundle non disponible)
bundle exec whenever --update-crontab
```

**Après** :
```bash
# Exécute depuis le conteneur (bundle/whenever disponibles)
$DOCKER_CMD exec "$container" bundle exec whenever --update-crontab --set "environment=${env}"
```

### 4. Script maintenance.sh amélioré

**Avant** :
- Utilisait `sudo docker` directement
- Pas de gestion d'erreurs

**Après** :
- Utilise `$DOCKER_CMD` (détection automatique de sudo)
- Utilise les fonctions du module `maintenance.sh`
- Meilleure gestion d'erreurs

---

## 📋 Workflow de déploiement avec mode maintenance

1. **Nettoyage préventif** : Arrêt des conteneurs orphelins
2. **Activation mode maintenance** : Site accessible mais affiche la page de maintenance
3. **Backup DB** : Sauvegarde de la base de données
4. **Git pull** : Mise à jour du code
5. **Build** : Construction de l'image Docker
6. **Migrations** : Application des migrations
7. **Crontab** : Installation depuis le conteneur
8. **Désactivation mode maintenance** : Site redevient accessible
9. **Health check** : Vérification complète (DB, Redis, Migrations, HTTP depuis conteneur)

**Avantage** : Aucun downtime, les utilisateurs voient la page de maintenance pendant le déploiement.

---

## 🔍 Détails techniques

### Health check HTTP amélioré

```bash
# Priorité 1 : Depuis le conteneur (curl disponible)
$DOCKER_CMD exec "$container" curl -s -w "%{http_code}" "http://localhost:3000/up"

# Priorité 2 : Depuis le conteneur (wget si curl non disponible)
$DOCKER_CMD exec "$container" wget -q -O - "http://localhost:3000/up"

# Priorité 3 : Via reverse proxy depuis l'hôte (port 80)
curl -s -w "%{http_code}" "http://localhost:80/up"
```

### Mode maintenance

Le mode maintenance utilise `Rails.cache` pour stocker l'état :
- Activation : `Rails.cache.write("maintenance_mode:enabled", "true")`
- Désactivation : `Rails.cache.delete("maintenance_mode:enabled")`
- Vérification : `Rails.cache.read("maintenance_mode:enabled") == "true"`

---

## 🧪 Tests recommandés

### 1. Test du mode maintenance

```bash
# Activer
./ops/production/maintenance.sh enable

# Vérifier le statut
./ops/production/maintenance.sh status

# Désactiver
./ops/production/maintenance.sh disable
```

### 2. Test du health check HTTP

```bash
# Depuis le conteneur
$DOCKER_CMD exec grenoble-roller-production curl -s -w "%{http_code}" -o /dev/null "http://localhost:3000/up"
# Devrait retourner : 200

# Via le reverse proxy depuis l'hôte
curl -s -w "%{http_code}" -o /dev/null "http://localhost:80/up"
# Devrait retourner : 200
```

### 3. Test de l'installation du crontab

```bash
# Depuis le conteneur
$DOCKER_CMD exec grenoble-roller-production bundle exec whenever --update-crontab --set "environment=production"

# Vérifier les entrées
$DOCKER_CMD exec grenoble-roller-production bundle exec whenever --set "environment=production"
```

---

## 📋 Checklist de vérification

- [x] Mode maintenance activé avant build
- [x] Mode maintenance désactivé après health check réussi
- [x] Health check HTTP teste depuis le conteneur
- [x] Crontab installé depuis le conteneur
- [x] Script maintenance.sh utilise $DOCKER_CMD
- [x] Rollback utilise le mode maintenance
- [x] Rebuild sans cache utilise le mode maintenance

---

## 🔗 Fichiers modifiés

- `ops/lib/deployment/maintenance.sh` (nouveau)
- `ops/production/deploy.sh` (intégration mode maintenance)
- `ops/lib/deployment/rollback.sh` (intégration mode maintenance)
- `ops/lib/docker/compose.sh` (intégration mode maintenance)
- `ops/lib/health/checks.sh` (health check HTTP depuis conteneur)
- `ops/lib/deployment/cron.sh` (installation depuis conteneur)
- `ops/production/maintenance.sh` (amélioration avec $DOCKER_CMD)

---

## 🎯 Avantages

1. **Zéro downtime** : Les utilisateurs voient la page de maintenance au lieu d'une erreur
2. **Health check fiable** : Teste depuis le conteneur où les outils sont disponibles
3. **Crontab fonctionnel** : Installation depuis le conteneur où bundle/whenever sont disponibles
4. **Meilleure expérience utilisateur** : Message de maintenance au lieu d'erreur 502

---

**Dernière mise à jour** : 2025-01-20  
**Auteur** : FlowTech-AI

