# Scripts de déploiement automatique

## 📋 Fichiers

### Scripts principaux (génériques)
- **`deploy.sh`** : Script principal de déploiement (backup, pull, build, migrate, health check, rollback)
- **`watchdog.sh`** : Script de surveillance appelé par cron (vérifie les mises à jour Git)

### Scripts wrapper par environnement (à utiliser sur chaque machine)
- **`deploy-dev.sh`** / **`watchdog-dev.sh`** : Pour la machine DEV
- **`deploy-staging.sh`** / **`watchdog-staging.sh`** : Pour la machine STAGING
- **`deploy-production.sh`** / **`watchdog-production.sh`** : Pour la machine PRODUCTION

**Note** : Chaque machine n'a besoin que de son propre script wrapper. Les scripts principaux sont partagés.

## 🔧 Configuration

### Variables d'environnement serveur (optionnel)

Créer `.env.server` à la racine du projet sur le serveur :

```bash
# Notifications Slack (optionnel)
SLACK_WEBHOOK=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# Rétention des backups (en jours)
BACKUP_RETENTION_DAYS=7

# Niveau de log
LOG_LEVEL=info
```

⚠️ **Important** : Ce fichier ne doit jamais être poussé sur GitHub (déjà ignoré par `.gitignore`).

### Accès Git

Le serveur doit avoir accès au dépôt GitHub. Deux options :

#### Option 1 : SSH (recommandé)

```bash
# Générer une clé SSH dédiée
ssh-keygen -t ed25519 -f ~/.ssh/github_deploy -N ""

# Afficher la clé publique
cat ~/.ssh/github_deploy.pub

# Ajouter dans GitHub > Settings > Deploy keys
# Configurer Git
git config --global core.sshCommand "ssh -i ~/.ssh/github_deploy -F /dev/null"
```

#### Option 2 : HTTPS

```bash
# Créer un token GitHub : https://github.com/settings/tokens
# Configurer Git
git config --global credential.helper store
# Faire un git pull et entrer le token comme mot de passe
```

## 🚀 Utilisation

### Sur la machine DEV

```bash
# Test manuel
./ops/scripts/deploy-dev.sh

# Cron (toutes les 5 minutes)
*/5 * * * * /app/grenoble-roller/ops/scripts/watchdog-dev.sh
```

### Sur la machine STAGING

```bash
# Test manuel
./ops/scripts/deploy-staging.sh

# Cron (toutes les 5 minutes)
*/5 * * * * /app/grenoble-roller/ops/scripts/watchdog-staging.sh
```

### Sur la machine PRODUCTION

```bash
# Test manuel
./ops/scripts/deploy-production.sh

# Cron (toutes les 10 minutes)
*/10 * * * * /app/grenoble-roller/ops/scripts/watchdog-production.sh
```

## 📊 Logs

- **Staging** : `/var/log/grenoble-roller/deploy-staging.log`
- **Production** : `/var/log/grenoble-roller/deploy-production.log`

## 🔒 Sécurité

- Lock file avec timeout 30 minutes (évite les blocages)
- Backups automatiques avant chaque déploiement
- Rollback automatique en cas d'échec
- Health check avant validation

## 📦 Backups

- **Emplacement** : `/backups/{staging,production}/`
- **Rétention** : 20 derniers backups conservés automatiquement
- **Format** : `db_YYYYMMDD_HHMMSS.sql` et `volumes_YYYYMMDD_HHMMSS.tar.gz`

