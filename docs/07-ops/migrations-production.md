# 🗄️ Migrations en Production : Diagnostic & Safeguards

**Date** : 2025-01-20  
**Status** : ✅ Safeguards implémentés  
**Environnements** : Staging, Production

---

## 📋 Résumé Exécutif

### Problème Identifié

Le script de déploiement (`deploy.sh`) quittait prématurément si le code Git était à jour, sans vérifier si des migrations étaient en attente dans la base de données. Résultat : migrations présentes dans le code mais jamais exécutées.

### Solution Implémentée

✅ **Safeguards production-grade** :
1. Détection automatique des migrations en attente (même si Git à jour)
2. Détection des migrations destructives avec arrêt en production
3. Timeout configurable (5 min staging, 10 min production)
4. Health check avancé (`/health`, `/health/migrations`)

---

## 🔍 Diagnostic : Cause Racine

### Problème Principal

```bash
# Ligne 235-237 (AVANT correction)
if [ "$LOCAL" = "$REMOTE" ]; then
    log "✅ Déjà à jour (commit: ${LOCAL:0:7})"
    exit 0  # ← SORTIE PRÉMATURÉE
fi
```

**Impact** : Le script quittait avant d'atteindre l'exécution des migrations (ligne 339).

### Scénarios de Défaillance

1. **Déploiement partiel** : Migration non exécutée après échec de build
2. **DB restaurée** : Backup restauré, migrations manquantes non détectées
3. **Migration ajoutée manuellement** : Migration dans le code mais jamais exécutée

---

## ✅ Safeguards Implémentés

### 1. Détection Migrations en Attente

**Avant exit** : Vérification systématique des migrations même si Git est à jour.

```bash
if [ "$LOCAL" = "$REMOTE" ]; then
    # Vérification migrations en attente
    PENDING_COUNT=$(docker exec "$CONTAINER_NAME" bin/rails db:migrate:status | grep -c "^\s*down" || echo "0")
    if [ "$PENDING_COUNT" -gt 0 ]; then
        log_warning "⚠️  $PENDING_COUNT migration(s) en attente détectée(s)"
        # Continue vers exécution migrations
    else
        exit 0
    fi
fi
```

### 2. Détection Migrations Destructives

**Patterns détectés** : `Remove`, `Drop`, `Destroy`, `Delete`, `Truncate`, `Clear`

- **Production** : Arrêt automatique + message d'approbation manuelle requise
- **Staging** : Alerte + pause 10s avant continuation

### 3. Timeout Migrations

- **Staging** : 5 minutes (300s)
- **Production** : 10 minutes (600s)

Rollback automatique si timeout déclenché.

### 4. Health Check Avancé

- `GET /health` : Vérification complète (DB + migrations)
- `GET /health/migrations` : Status migrations uniquement

---

## ⚠️ Limites du Backup Logique (pg_dump)

### Temps de Restauration Réels

| Taille DB | Restauration | Downtime Acceptable ? |
|-----------|--------------|----------------------|
| < 1 GB    | 2-5 min      | ✅ Oui               |
| 1-10 GB   | 15-30 min    | ⚠️ Limite            |
| 10-50 GB  | 1-2h         | 🔴 Critique          |
| > 50 GB   | 2-4h         | 😱 Inacceptable      |

**Pour DB > 10GB** : Considérer backup physique + WAL archiving (PITR).

### Scénarios à Risque

1. **Migrations destructives** : `DROP COLUMN` → perte données irréversible
2. **Migrations longues** : Locks prolongés → downtime
3. **Rollback impossible** : Pas de `down()` → seule option = restauration backup
4. **Drift PostgreSQL** : Versions/extensions différentes dev/prod

---

## 🛠️ Runbooks

### Runbook 1 : Migration Manuelle en Urgence

**Cas d'usage** : Migration en attente non exécutée automatiquement

```bash
# 1. Backup (OBLIGATOIRE)
docker exec grenoble-roller-db-staging pg_dump -U postgres grenoble_roller_production > backup_$(date +%Y%m%d_%H%M%S).sql

# 2. Exécuter migration
docker exec grenoble-roller-staging bin/rails db:migrate

# 3. Vérifier
docker exec grenoble-roller-staging bin/rails db:migrate:status | grep "down"

# 4. Health check (simple pour scripts)
curl -f http://localhost:3001/up

# Ou health check complet (monitoring)
curl -s http://localhost:3001/health | jq
```

### Runbook 2 : Migration Destructive en Production

**Cas d'usage** : Migration contenant `Remove`, `Drop`, `Destroy`, etc.

**⚠️ Le script s'arrête automatiquement en production. Procédure manuelle :**

1. **Backup complet** :
   ```bash
   BACKUP_FILE="backups/production/db_$(date +%Y%m%d_%H%M%S)_before_destructive.sql"
   docker exec grenoble-roller-db-prod pg_dump -U postgres grenoble_roller_production > "$BACKUP_FILE"
   ```

2. **Tester en staging d'abord** :
   ```bash
   docker exec grenoble-roller-staging bin/rails db:migrate
   ```

3. **Exécuter en production** :
   ```bash
   docker exec grenoble-roller-prod bin/rails db:migrate
   ```

4. **Valider** :
   ```bash
   docker exec grenoble-roller-prod bin/rails db:migrate:status
   curl -s http://localhost:3002/health | jq
   ```

5. **Si rollback nécessaire** :
   ```bash
   cat "$BACKUP_FILE" | docker exec -i grenoble-roller-db-prod psql -U postgres grenoble_roller_production
   ```

### Runbook 3 : Migration Timeout

**Symptôme** : Migration dépasse le timeout (5/10 min)

**Action immédiate** :
1. Vérifier l'état : `docker exec grenoble-roller-prod bin/rails db:migrate:status`
2. Si partiellement exécutée → Restaurer backup
3. Analyser pourquoi timeout (migration trop longue, locks)
4. Optimiser la migration avant réessai

---

## 📊 Monitoring

### Endpoints Health Check

**Deux endpoints complémentaires** :

1. **`/up`** (Rails standard) : Simple, rapide, pas de DB queries
   - Utilisé par Docker healthcheck et scripts de déploiement
   - Retourne 200/500 (app boot OK ou non)

2. **`/health`** (Custom) : Complet avec DB + migrations
   - Pour monitoring avancé (Grafana/Prometheus)
   - Retourne JSON détaillé

```bash
# Health check simple (utilisé par scripts de déploiement)
curl -f http://localhost:3002/up

# Health check complet (monitoring)
curl -s http://localhost:3002/health | jq

# Réponse OK :
{
  "status": "ok",
  "database": "connected",
  "migrations": {
    "pending_count": 0,
    "status": "up_to_date"
  }
}

# Réponse dégradée (migrations en attente) :
{
  "status": "degraded",
  "migrations": {
    "pending_count": 1,
    "status": "pending",
    "pending_migrations": [
      {
        "version": "20251124020634",
        "name": "AddConfirmableToUsers"
      }
    ]
  }
}
```

### Métriques Recommandées (Grafana/Prometheus)

- `pending_migrations_count` : Nombre de migrations en attente
- Alerte si `pending_migrations_count > 0` pendant > 15 minutes

---

## 🔗 Fichiers Modifiés

- ✅ `ops/staging/deploy.sh` - Safeguards implémentés
- ✅ `ops/production/deploy.sh` - Safeguards implémentés
- ✅ `app/controllers/health_controller.rb` - Health check créé
- ✅ `config/routes.rb` - Routes `/health` ajoutées

---

## 📝 Checklist Déploiement

### Avant Migration
- [ ] Backup créé et validé
- [ ] Migration testée en staging
- [ ] Migration destructives ? → Approbation manuelle requise
- [ ] DB > 10GB ? → Planifier fenêtre maintenance

### Pendant Migration
- [ ] Monitoring logs actif
- [ ] Health check surveillé
- [ ] Pas de timeout (> 5-10 min selon env)

### Après Migration
- [ ] État migrations vérifié (`db:migrate:status`)
- [ ] Health check OK (`/health`)
- [ ] Tests fonctionnels réussis
- [ ] Pas d'erreurs dans logs

---

**Dernière mise à jour** : 2025-01-20  
**Auteur** : FlowTech-AI

