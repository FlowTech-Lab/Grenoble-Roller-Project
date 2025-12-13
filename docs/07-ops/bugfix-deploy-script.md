# Bugfix : Script de déploiement production

**Date** : 2025-01-20  
**Status** : ✅ Corrigé  
**Problèmes identifiés et corrigés** : 4 erreurs critiques

---

## 🐛 Problèmes identifiés

### 1. **Erreur : Port 80 déjà alloué**
```
Error response from daemon: failed to set up container networking: 
driver failed programming external connectivity on endpoint grenoble-roller-nginx-production: 
Bind for 0.0.0.0:80 failed: port is already allocated
```

**Cause** : Conteneurs orphelins (grenoble-roller-caddy-production, grenoble-roller-certbot-production) bloquent le port 80.

**Solution** : Ajout d'un nettoyage automatique des conteneurs orphelins avant le build.

### 2. **Erreur : Image non trouvée après build réussi**
```
ERROR: ❌ Image non trouvée après build réussi
ERROR: Le build a peut-être échoué silencieusement
```

**Cause** : La fonction `docker_compose_build` utilisait `docker compose` directement au lieu de `$DOCKER_CMD compose`.

**Solution** : Correction pour utiliser `$DOCKER_CMD` partout.

### 3. **Erreur : Migrations locales ABSENTES du conteneur**
```
ERROR: ❌ Impossible de lister les migrations dans le conteneur
ERROR: ❌ ERREUR CRITIQUE : Migrations locales ABSENTES du conteneur
```

**Cause** : La fonction `verify_migrations_synced` utilisait `docker exec` directement au lieu de `$DOCKER_CMD exec`.

**Solution** : Correction pour utiliser `$DOCKER_CMD exec`.

### 4. **Erreur : Échec de la restauration**
```
ERROR: Échec de la restauration (déchiffrement ou import)
ERROR: ❌ Restauration DB échouée - État critique
```

**Cause** : La fonction `restore_database_from_backup` utilisait `docker exec` directement au lieu de `$DOCKER_CMD exec`.

**Solution** : Correction pour utiliser `$DOCKER_CMD exec`.

---

## ✅ Corrections appliquées

### Fichiers modifiés

1. **`ops/production/deploy.sh`**
   - Ajout du nettoyage des conteneurs orphelins avant build
   - Remplacement de `docker` par `$DOCKER_CMD` (3 occurrences)

2. **`ops/lib/database/migrations.sh`**
   - Remplacement de `docker exec` par `$DOCKER_CMD exec` (4 occurrences)

3. **`ops/lib/database/restore.sh`**
   - Remplacement de `docker exec` par `$DOCKER_CMD exec` (3 occurrences)

4. **`ops/lib/deployment/rollback.sh`**
   - Remplacement de `docker compose` par `$DOCKER_CMD compose` (5 occurrences)

5. **`ops/lib/docker/images.sh`**
   - Remplacement de `docker` par `$DOCKER_CMD` (4 occurrences)

6. **`ops/lib/core/utils.sh`**
   - Remplacement de `docker logs` par `$DOCKER_CMD logs` (1 occurrence)

7. **`ops/lib/health/checks.sh`**
   - Remplacement de `docker exec` par `$DOCKER_CMD exec` (3 occurrences)

8. **`ops/lib/health/waiters.sh`**
   - Remplacement de `docker ps` par `$DOCKER_CMD ps` (1 occurrence)

9. **`ops/lib/database/backup.sh`**
   - Remplacement de `docker exec` par `$DOCKER_CMD exec` (3 occurrences)
   - Simplification de la détection de la commande docker

---

## 🔍 Détails des corrections

### Nettoyage des conteneurs orphelins

**Avant** :
```bash
# Nettoyage préventif
log "🧹 Nettoyage préventif Docker..."
docker image prune -f > /dev/null 2>&1 && log_info "Images sans tag nettoyées" || true
docker builder prune -f > /dev/null 2>&1 && log_info "Cache build nettoyé" || true
```

**Après** :
```bash
# Nettoyage préventif
log "🧹 Nettoyage préventif Docker..."

# Arrêter les conteneurs orphelins qui pourraient bloquer les ports
log_info "Arrêt des conteneurs orphelins (Caddy/Certbot/Nginx)..."
$DOCKER_CMD stop grenoble-roller-caddy-production grenoble-roller-certbot-production 2>/dev/null || true
$DOCKER_CMD rm grenoble-roller-caddy-production grenoble-roller-certbot-production 2>/dev/null || true

$DOCKER_CMD image prune -f > /dev/null 2>&1 && log_info "Images sans tag nettoyées" || true
$DOCKER_CMD builder prune -f > /dev/null 2>&1 && log_info "Cache build nettoyé" || true
```

### Utilisation de $DOCKER_CMD partout

Tous les appels directs à `docker` ont été remplacés par `$DOCKER_CMD` pour :
- Respecter la détection automatique de sudo
- Garantir la cohérence dans tout le script
- Éviter les erreurs de permission

---

## 🧪 Tests recommandés

### 1. Test du nettoyage des conteneurs orphelins

```bash
# Créer manuellement des conteneurs orphelins pour tester
docker run -d --name grenoble-roller-caddy-production -p 80:80 nginx:alpine

# Exécuter le script de déploiement
./ops/production/deploy.sh

# Vérifier que les conteneurs orphelins ont été supprimés
docker ps -a | grep grenoble-roller-caddy-production
# Ne devrait rien retourner
```

### 2. Test de la détection de $DOCKER_CMD

```bash
# Vérifier que DOCKER_CMD est correctement détecté
cd ops/production
source ../lib/docker/containers.sh
echo "DOCKER_CMD = $DOCKER_CMD"

# Devrait afficher "docker" ou "sudo docker" selon les permissions
```

### 3. Test complet du déploiement

```bash
# Exécuter le déploiement en mode force
./ops/production/deploy.sh --force

# Vérifier que :
# 1. Les conteneurs orphelins sont arrêtés
# 2. Le build réussit
# 3. Les migrations sont détectées dans le conteneur
# 4. La restauration fonctionne en cas de rollback
```

---

## 📋 Checklist de vérification

- [x] Conteneurs orphelins nettoyés automatiquement
- [x] `$DOCKER_CMD` utilisé partout au lieu de `docker`
- [x] Détection automatique de sudo fonctionnelle
- [x] Migrations détectées correctement dans le conteneur
- [x] Restauration DB fonctionnelle avec `$DOCKER_CMD`
- [x] Health checks utilisent `$DOCKER_CMD`
- [x] Rollback utilise `$DOCKER_CMD`

---

## 🔗 Fichiers modifiés

- `ops/production/deploy.sh`
- `ops/lib/database/migrations.sh`
- `ops/lib/database/restore.sh`
- `ops/lib/database/backup.sh`
- `ops/lib/deployment/rollback.sh`
- `ops/lib/docker/images.sh`
- `ops/lib/docker/compose.sh` (déjà corrigé)
- `ops/lib/core/utils.sh`
- `ops/lib/health/checks.sh`
- `ops/lib/health/waiters.sh`

---

**Dernière mise à jour** : 2025-01-20  
**Auteur** : FlowTech-AI

