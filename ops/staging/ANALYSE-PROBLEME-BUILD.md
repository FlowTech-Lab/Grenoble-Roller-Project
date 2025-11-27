# 🔍 Analyse : Pourquoi les fichiers manquent dans le conteneur Docker

## Problème Identifié

Les fichiers de migration sont présents localement et dans Git, mais absents du conteneur après un build `--no-cache`.

## Diagnostic Complet

### ✅ Ce qui fonctionne
1. **Fichiers locaux** : Les 4 migrations existent dans `db/migrate/`
2. **Git** : Les fichiers sont versionnés et trackés par Git
3. **Build context** : Les fichiers sont dans le build context (`/home/flowtech/Grenoble-Roller-Project`)
4. **.dockerignore** : N'exclut PAS `db/migrate/`
5. **Dockerfile** : Contient `COPY . .` dans le stage `build`

### ❌ Le problème

**L'image a été créée à 15:45:59, mais les fichiers modifiés à 15:18:53 ne sont PAS dans l'image.**

## Causes Racines Possibles

### 1. **Build Context résolu au mauvais moment** ⚠️ CRITIQUE

Docker résout le build context **au moment où `docker compose build` est exécuté**, pas au moment où le Dockerfile fait `COPY . .`.

**Séquence problématique possible :**
```bash
# 1. Script fait git pull (15:18:53)
git pull origin staging  # ✅ Fichiers mis à jour

# 2. Script fait docker compose build (15:45:59)
docker compose build --no-cache
# ❌ Docker résout le build context ICI
# Si le répertoire courant a changé ou si Docker utilise un cache de build context...
```

**Solution :** S'assurer que le build context est résolu depuis le bon répertoire au moment du build.

### 2. **Multi-stage Build : COPY --from=build peut perdre des fichiers**

Le Dockerfile utilise un multi-stage build :
```dockerfile
# Stage build
COPY . .  # ✅ Copie tout dans /rails

# Stage final
COPY --from=build /rails /rails  # ⚠️ Copie depuis le stage build
```

**Problème potentiel :** Si le stage `build` n'a pas tous les fichiers (à cause d'un cache ou d'un problème de timing), le stage final n'aura pas ces fichiers non plus.

### 3. **Cache BuildKit persistant malgré --no-cache**

BuildKit peut avoir un cache de build context qui persiste même avec `--no-cache`.

**Solution :** Utiliser `docker buildx prune -a -f` AVANT le build.

### 4. **Timing : Build context snapshot au début du build**

Docker fait un snapshot du build context **au début du build**, pas au moment du `COPY`.

**Séquence problématique :**
```bash
# 1. git pull (15:18:53) - fichiers mis à jour
# 2. Quelque chose modifie le répertoire entre git pull et build
# 3. docker compose build (15:45:59) - snapshot du build context
#    Si le snapshot est pris AVANT git pull ou si Docker utilise un cache...
```

## Solutions Recommandées

### Solution 1 : Vérifier le build context AVANT le build (CRITIQUE)

Ajouter une vérification explicite que les fichiers sont dans le build context juste avant le build :

```bash
# Dans force_rebuild_without_cache()
# Vérifier que les fichiers sont vraiment dans le build context
log_info "Vérification explicite du build context..."
for file in "${MIGRATION_FILES[@]}"; do
    if [ ! -f "${REPO_DIR}/${file}" ]; then
        log_error "❌ ${file} ABSENT du build context avant build !"
        log_error "Le build utiliserait un état obsolète"
        return 1
    fi
done
```

### Solution 2 : Forcer un nouveau build context avec BUILD_ID

Le script utilise déjà `BUILD_ID`, mais on peut l'améliorer :

```dockerfile
# Dockerfile
ARG BUILD_ID=latest
# Utiliser BUILD_ID dans un RUN pour forcer un nouveau layer
RUN echo "Build ID: ${BUILD_ID}" > /rails/.build_id
```

### Solution 3 : Vérifier après COPY dans le Dockerfile

Ajouter une vérification dans le Dockerfile après `COPY . .` :

```dockerfile
# Copy application code
COPY . .

# Vérification que les migrations sont copiées
RUN test -f /rails/db/migrate/20250126180000_add_donation_cents_to_orders.rb || \
    (echo "ERREUR: Migration manquante après COPY" && exit 1)
```

### Solution 4 : Utiliser --progress=plain pour voir ce qui est copié

Le script utilise déjà `--progress=plain`, mais on peut améliorer le logging :

```bash
docker compose --progress=plain -f "$compose_file" build \
    --pull --no-cache --build-arg BUILD_ID="$BUILD_ID" \
    2>&1 | tee -a "$LOG_FILE" | grep -E "COPY|migrate"
```

### Solution 5 : Vérifier l'image IMMÉDIATEMENT après build

Ajouter une vérification post-build avant de démarrer le conteneur :

```bash
# Après docker compose build
log_info "Vérification que les migrations sont dans l'IMAGE (pas le conteneur)..."
docker create --name test-migrations staging-web > /dev/null 2>&1
if docker cp test-migrations:/rails/db/migrate/. /tmp/test-migrations/ 2>/dev/null; then
    MIGRATION_COUNT=$(ls -1 /tmp/test-migrations/*.rb 2>/dev/null | wc -l)
    if [ "$MIGRATION_COUNT" -ne "$MIGRATION_FILES_COUNT" ]; then
        log_error "❌ Image ne contient que ${MIGRATION_COUNT} migrations au lieu de ${MIGRATION_FILES_COUNT}"
        docker rm test-migrations > /dev/null 2>&1
        return 1
    fi
    log_success "✅ Image contient ${MIGRATION_COUNT} migrations"
fi
docker rm test-migrations > /dev/null 2>&1
```

## Recommandation Immédiate

**Implémenter Solution 1 + Solution 5** : Vérifier le build context avant le build ET vérifier l'image après le build.

