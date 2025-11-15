# 🐕 Watchdog - Déploiement Automatique Local

## 📋 Vue d'ensemble

Solution **100% locale** pour déploiement automatique : pas de SSH, pas de registry, tout se fait sur le serveur local.

---

## 🎯 Principe

**Sur le serveur local** (où tourne Docker) :
1. Script qui vérifie régulièrement les mises à jour Git
2. Si nouvelle version → Backup → Pull → Build → Restart → Health check
3. Si échec → Rollback automatique

**Pas besoin de** :
- ❌ SSH depuis GitHub Actions
- ❌ Registry Docker (GHCR/Docker Hub)
- ❌ Watchtower
- ❌ Port à exposer

---

## 🔄 Flux complet

```
┌─────────────────────────────────────────────────────────────┐
│  DEVELOPPEUR                                                 │
│  git push staging                                            │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│  GITHUB (dépôt distant)                                     │
│  Code disponible sur branche staging                        │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   │ (Script local vérifie toutes les 5 minutes)
                   ▼
┌─────────────────────────────────────────────────────────────┐
│  SERVEUR LOCAL                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Script watchdog (cron ou systemd timer)            │   │
│  │  1. git fetch → Vérifie nouvelles versions           │   │
│  │  2. Si nouvelle version détectée :                  │   │
│  │     - Backup DB + volumes                            │   │
│  │     - git pull                                       │   │
│  │     - docker compose build                           │   │
│  │     - docker compose up -d                           │   │
│  │     - rails db:migrate                                │   │
│  │     - Health check                                   │   │
│  │     - Si OK → Garde                                  │   │
│  │     - Si échec → Rollback (git checkout + rebuild)   │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Implémentation

### 1. Script de déploiement : `ops/scripts/deploy.sh`

```bash
#!/bin/bash
# Script de déploiement automatique local
# Usage: ./ops/scripts/deploy.sh staging|production

set -e

ENV=${1:-staging}
COMPOSE_FILE="ops/${ENV}/docker-compose.yml"
BACKUP_DIR="/backups/${ENV}"
LOG_FILE="/var/log/grenoble-roller/deploy-${ENV}.log"
REPO_DIR="/app/grenoble-roller"  # Chemin du repo sur le serveur

# Couleurs pour logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}" | tee -a "$LOG_FILE"
}

# Vérifier qu'on est dans le bon répertoire
if [ ! -f "$COMPOSE_FILE" ]; then
    log_error "Fichier $COMPOSE_FILE introuvable. Êtes-vous dans le bon répertoire ?"
    exit 1
fi

cd "$REPO_DIR" || exit 1

log "🚀 Début du déploiement ${ENV}..."

# 1. Vérifier s'il y a des mises à jour
log "📥 Vérification des mises à jour..."
git fetch origin

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/${ENV})

if [ "$LOCAL" = "$REMOTE" ]; then
    log "✅ Déjà à jour (commit: ${LOCAL:0:7})"
    exit 0
fi

log "🆕 Nouvelle version détectée (${LOCAL:0:7} → ${REMOTE:0:7})"

# 2. Backup base de données
log "📦 Backup base de données..."
mkdir -p "$BACKUP_DIR"
DB_BACKUP="${BACKUP_DIR}/db_$(date +%Y%m%d_%H%M%S).sql"
if docker exec grenoble-roller-db-${ENV} pg_dump -U postgres grenoble_roller_production > "$DB_BACKUP" 2>/dev/null; then
    log_success "Backup DB créé: $DB_BACKUP"
    # Garder seulement les 10 derniers backups
    ls -t "${BACKUP_DIR}"/db_*.sql | tail -n +11 | xargs rm -f 2>/dev/null || true
else
    log_error "Échec du backup DB"
    exit 1
fi

# 3. Backup volumes (optionnel)
log "📦 Backup volumes..."
VOLUME_BACKUP="${BACKUP_DIR}/volumes_$(date +%Y%m%d_%H%M%S).tar.gz"
if docker run --rm \
    -v grenoble-roller-${ENV}-data:/data:ro \
    -v "$BACKUP_DIR":/backup \
    alpine tar czf /backup/volumes_$(date +%Y%m%d_%H%M%S).tar.gz -C /data . 2>/dev/null; then
    log_success "Backup volumes créé"
    ls -t "${BACKUP_DIR}"/volumes_*.tar.gz | tail -n +11 | xargs rm -f 2>/dev/null || true
else
    log "⚠️ Backup volumes échoué (non critique)"
fi

# 4. Sauvegarder le commit actuel (pour rollback)
CURRENT_COMMIT=$(git rev-parse HEAD)
log "💾 Commit actuel sauvegardé: ${CURRENT_COMMIT:0:7}"

# 5. Git pull
log "📥 Mise à jour du code..."
if ! git pull origin ${ENV}; then
    log_error "Échec du git pull"
    exit 1
fi

# 6. Build et restart
log "🔨 Build et redémarrage..."
if ! docker compose -f "$COMPOSE_FILE" up -d --build; then
    log_error "Échec du build/restart"
    log "🔄 Rollback..."
    git checkout "$CURRENT_COMMIT"
    docker compose -f "$COMPOSE_FILE" up -d --build
    exit 1
fi

# 7. Attendre que le conteneur démarre
log "⏳ Attente du démarrage du conteneur..."
sleep 15

# 8. Migrations
log "🗄️ Exécution des migrations..."
if ! docker exec grenoble-roller-${ENV} bin/rails db:migrate; then
    log_error "Échec des migrations"
    log "🔄 Rollback..."
    git checkout "$CURRENT_COMMIT"
    docker compose -f "$COMPOSE_FILE" up -d --build
    exit 1
fi

# 9. Health check
log "🏥 Health check..."
PORT=$([ "$ENV" = "staging" ] && echo "3001" || echo "3002")
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f "http://localhost:${PORT}/up" > /dev/null 2>&1; then
        log_success "Health check réussi !"
        log_success "✅ Déploiement ${ENV} terminé avec succès (commit: ${REMOTE:0:7})"
        exit 0
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    log "⏳ Tentative $RETRY_COUNT/$MAX_RETRIES..."
    sleep 2
done

# 10. Rollback si health check échoue
log_error "Health check échoué après $MAX_RETRIES tentatives"
log "🔄 Rollback vers commit ${CURRENT_COMMIT:0:7}..."

git checkout "$CURRENT_COMMIT"
docker compose -f "$COMPOSE_FILE" up -d --build

# Restaurer la DB si nécessaire
log "📦 Restauration de la base de données..."
LATEST_BACKUP=$(ls -t "${BACKUP_DIR}"/db_*.sql | head -1)
if [ -f "$LATEST_BACKUP" ]; then
    cat "$LATEST_BACKUP" | docker exec -i grenoble-roller-db-${ENV} psql -U postgres grenoble_roller_production
    log_success "Base de données restaurée"
fi

log_error "Rollback effectué - Déploiement échoué"
exit 1
```

---

### 2. Script de surveillance : `ops/scripts/watchdog.sh`

```bash
#!/bin/bash
# Script watchdog - Vérifie les mises à jour et déclenche le déploiement
# Usage: À exécuter via cron toutes les 5 minutes

ENV=${1:-staging}  # staging ou production
REPO_DIR="/app/grenoble-roller"
DEPLOY_SCRIPT="${REPO_DIR}/ops/scripts/deploy.sh"

cd "$REPO_DIR" || exit 1

# Vérifier si un déploiement est déjà en cours
LOCK_FILE="/tmp/grenoble-roller-deploy-${ENV}.lock"
if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Déploiement déjà en cours (PID: $PID)"
        exit 0
    else
        # Lock file orphelin, le supprimer
        rm -f "$LOCK_FILE"
    fi
fi

# Créer le lock file
echo $$ > "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

# Exécuter le déploiement
"$DEPLOY_SCRIPT" "$ENV"

# Supprimer le lock file
rm -f "$LOCK_FILE"
```

---

### 3. Configuration Cron

Créer `/etc/cron.d/grenoble-roller` :

```bash
# Déploiement automatique Grenoble Roller
# Vérifie les mises à jour toutes les 5 minutes

# Staging
*/5 * * * * root /app/grenoble-roller/ops/scripts/watchdog.sh staging >> /var/log/grenoble-roller/watchdog-staging.log 2>&1

# Production (toutes les 10 minutes)
*/10 * * * * root /app/grenoble-roller/ops/scripts/watchdog.sh production >> /var/log/grenoble-roller/watchdog-prod.log 2>&1
```

**Ou avec systemd timer** (plus moderne) :

Créer `/etc/systemd/system/grenoble-roller-staging.timer` :

```ini
[Unit]
Description=Watchdog déploiement staging Grenoble Roller

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

Créer `/etc/systemd/system/grenoble-roller-staging.service` :

```ini
[Unit]
Description=Déploiement automatique staging

[Service]
Type=oneshot
ExecStart=/app/grenoble-roller/ops/scripts/watchdog.sh staging
User=root
```

Activer :
```bash
sudo systemctl enable grenoble-roller-staging.timer
sudo systemctl start grenoble-roller-staging.timer
```

---

## 📁 Structure des fichiers

```
ops/
├── scripts/
│   ├── deploy.sh          # Script de déploiement principal
│   └── watchdog.sh        # Script de surveillance (cron)
├── staging/
│   └── docker-compose.yml
└── production/
    └── docker-compose.yml

/backups/
├── staging/
│   ├── db_20250120_103000.sql
│   └── volumes_20250120_103000.tar.gz
└── production/
    ├── db_20250120_103000.sql
    └── volumes_20250120_103000.tar.gz

/var/log/grenoble-roller/
├── deploy-staging.log
├── deploy-production.log
├── watchdog-staging.log
└── watchdog-prod.log
```

---

## 🔐 Sécurité

### Permissions

```bash
# Scripts exécutables
chmod +x ops/scripts/*.sh

# Logs accessibles
sudo mkdir -p /var/log/grenoble-roller
sudo chown $USER:$USER /var/log/grenoble-roller

# Backups accessibles
sudo mkdir -p /backups/{staging,production}
sudo chown $USER:$USER /backups/{staging,production}
```

### Accès Git

Le serveur doit avoir accès au dépôt. **Deux options** :

#### Option 1 : SSH (recommandé pour production)

```bash
# Sur le serveur, générer une clé SSH dédiée
ssh-keygen -t ed25519 -f ~/.ssh/github_deploy -N ""

# Afficher la clé publique
cat ~/.ssh/github_deploy.pub

# Ajouter la clé publique au dépôt GitHub
# GitHub > Settings > Deploy keys > Add deploy key
# Coller le contenu de ~/.ssh/github_deploy.pub

# Configurer Git pour utiliser cette clé
git config --global core.sshCommand "ssh -i ~/.ssh/github_deploy -F /dev/null"
```

#### Option 2 : HTTPS (plus simple)

```bash
# Créer un token GitHub avec permissions: repo
# https://github.com/settings/tokens

# Configurer Git credential helper
git config --global credential.helper store

# Faire un git pull et entrer le token comme mot de passe
git pull origin staging
# Username: votre-username
# Password: ghp_votre_token_github
```

### Variables d'environnement serveur

Créer `/app/grenoble-roller/.env.server` (jamais pushé) :

```bash
# Notifications Slack (optionnel)
SLACK_WEBHOOK=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# Rétention des backups (en jours)
BACKUP_RETENTION_DAYS=7

# Niveau de log
LOG_LEVEL=info
```

---

## 🧪 Test

### Test manuel

```bash
# Test du script de déploiement
./ops/scripts/deploy.sh staging

# Vérifier les logs
tail -f /var/log/grenoble-roller/deploy-staging.log
```

### Test du watchdog

```bash
# Exécuter manuellement
./ops/scripts/watchdog.sh staging

# Vérifier les logs
tail -f /var/log/grenoble-roller/watchdog-staging.log
```

---

## ✅ Avantages de cette approche

- ✅ **100% local** : Pas de SSH, pas de registry
- ✅ **Simple** : Juste des scripts bash
- ✅ **Backup intégré** : DB + volumes avant chaque déploiement
- ✅ **Rollback automatique** : Git checkout + rebuild si échec
- ✅ **Health check** : Vérification avant validation
- ✅ **Logs** : Tout est loggé
- ✅ **Pas de port à exposer** : Tout est local

---

## ⚙️ Configuration par environnement

### Staging
- Vérification : Toutes les 5 minutes
- Port : 3001
- Logs : `/var/log/grenoble-roller/deploy-staging.log`

### Production
- Vérification : Toutes les 10 minutes (moins fréquent)
- Port : 3002
- Logs : `/var/log/grenoble-roller/deploy-production.log`

---

## 🚨 Gestion des erreurs

### Scénario 1 : Git pull échoue
→ Script s'arrête, pas de déploiement

### Scénario 2 : Build échoue
→ Rollback automatique vers commit précédent

### Scénario 3 : Migrations échouent
→ Rollback automatique + restauration DB

### Scénario 4 : Health check échoue
→ Rollback automatique + restauration DB

---

## 📊 Monitoring

### Vérifier l'état

```bash
# Dernier déploiement
tail -20 /var/log/grenoble-roller/deploy-staging.log

# Vérifier que le cron tourne
systemctl status grenoble-roller-staging.timer

# Vérifier les backups
ls -lh /backups/staging/
```

---

## 🔄 Workflow complet

1. **Développeur** : `git push origin staging`
2. **Serveur** : Cron exécute `watchdog.sh` toutes les 5 minutes
3. **Watchdog** : Détecte nouvelle version → Appelle `deploy.sh`
4. **Deploy** : Backup → Pull → Build → Restart → Health check
5. **Si OK** : Déploiement réussi
6. **Si échec** : Rollback automatique

---

## 📝 Checklist de mise en place

### Étape 1 : Préparation serveur
- [ ] Créer les scripts `deploy.sh` et `watchdog.sh`
- [ ] Rendre les scripts exécutables (`chmod +x`)
- [ ] Créer les dossiers de backup (`/backups/{staging,production}`)
- [ ] Créer les dossiers de logs (`/var/log/grenoble-roller`)
- [ ] Configurer l'accès Git sur le serveur (SSH ou HTTPS token)
- [ ] Créer `.env.server` avec variables optionnelles (Slack, etc.)

### Étape 2 : Tests manuels
- [ ] Tester manuellement le script `deploy.sh staging`
- [ ] Vérifier les backups créés
- [ ] Vérifier les logs
- [ ] Tester le rollback (simuler un échec)

### Étape 3 : Automatisation
- [ ] Tester `watchdog.sh staging` manuellement
- [ ] Configurer le cron ou systemd timer
- [ ] Vérifier les logs après premier déploiement automatique
- [ ] Surveiller pendant 24-48h

### Étape 4 : Production
- [ ] Dupliquer la config pour production
- [ ] Configurer cron avec fréquence réduite (10 min)
- [ ] Ajouter notifications Slack (optionnel)
- [ ] Documenter le process pour l'équipe

---

**Version** : 1.0 (Approche 100% locale)  
**Date** : 2025-01-20

