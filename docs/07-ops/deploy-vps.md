# 🚀 Guide de Déploiement sur VPS

## ✅ Prérequis sur le VPS

### 1. Système d'exploitation
- Ubuntu 20.04+ ou Debian 11+ recommandé
- Accès root ou utilisateur avec sudo

### 2. Outils nécessaires
```bash
# Docker et Docker Compose
sudo apt update
sudo apt install -y docker.io docker-compose git curl
sudo systemctl enable docker
sudo systemctl start docker

# Ajouter votre utilisateur au groupe docker (recommandé)
sudo usermod -aG docker $USER
# ⚠️ Se déconnecter/reconnecter pour que ça prenne effet
```

### 3. Espace disque
- **Minimum** : 20 GB libres
- **Recommandé** : 50 GB+ pour les backups et logs

### 4. Mémoire RAM
- **Minimum** : 2 GB
- **Recommandé** : 4 GB+ (pour Docker + PostgreSQL + Rails)

### 5. Ports disponibles
- **Staging** : Port 3001 (à exposer dans le firewall si nécessaire)
- **Production** : Port 3002 (à exposer dans le firewall si nécessaire)
- **PostgreSQL** : 5432 (interne Docker uniquement)
- **Minio** : 9000/9001 (interne Docker uniquement)

---

## 📦 Installation Initiale

### 1. Cloner le repository

```bash
# Se placer dans le répertoire où installer l'application
cd /opt  # ou /home/votre-utilisateur selon votre préférence

# Cloner le repo
git clone https://github.com/FlowTech-Lab/Grenoble-Roller-Project.git
# OU si vous utilisez SSH:
# git clone git@github.com:FlowTech-Lab/Grenoble-Roller-Project.git

cd Grenoble-Roller-Project
```

### 2. Configuration Git (si nécessaire)

Si vous utilisez SSH pour GitHub :

```bash
# Générer une clé SSH dédiée au déploiement
ssh-keygen -t ed25519 -f ~/.ssh/github_deploy -N ""

# Afficher la clé publique à ajouter dans GitHub
cat ~/.ssh/github_deploy.pub

# Configurer Git pour utiliser cette clé
git config --global core.sshCommand "ssh -i ~/.ssh/github_deploy -F /dev/null"

# Tester l'accès
git fetch origin
```

### 3. Configuration Rails Credentials

**⚠️ CRITIQUE EN PRODUCTION** : Vous devez avoir les Rails master keys.

```bash
# Option 1 : Copier les fichiers de credentials depuis votre machine locale
# (recommandé pour production)
scp config/master.key user@vps:/opt/Grenoble-Roller-Project/config/
scp config/credentials/production.key user@vps:/opt/Grenoble-Roller-Project/config/credentials/

# Option 2 : Définir la variable d'environnement
export RAILS_MASTER_KEY="votre_master_key_ici"

# Option 3 : Créer les credentials sur le serveur
bin/rails credentials:edit --environment production
```

### 4. Vérification des prérequis

```bash
# Vérifier Docker
docker --version
docker compose version

# Vérifier Git
git --version

# Vérifier l'accès au repo
git fetch origin

# Vérifier l'espace disque
df -h
```

---

## 🎯 Déploiement Staging

### 1. Se placer sur la branche staging

```bash
cd /opt/Grenoble-Roller-Project
git checkout staging
```

### 2. Premier déploiement

```bash
# Démarrer les conteneurs pour la première fois
docker compose -f ops/staging/docker-compose.yml up -d

# Attendre que les conteneurs soient healthy (30-60 secondes)
docker ps

# Initialiser la base de données (si première installation)
./ops/staging/init-db.sh
```

### 3. Vérification

```bash
# Vérifier que l'application répond
curl http://localhost:3001/up

# Vérifier les logs
docker logs grenoble-roller-staging
```

### 4. Configuration du watchdog (déploiement automatique)

```bash
# Ajouter dans le crontab
crontab -e

# Ajouter cette ligne (vérifie toutes les 5 minutes)
*/5 * * * * cd /opt/Grenoble-Roller-Project && ./ops/staging/watchdog.sh >> /tmp/watchdog-staging.log 2>&1
```

---

## 🎯 Déploiement Production

### 1. Se placer sur la branche main

```bash
cd /opt/Grenoble-Roller-Project
git checkout main
```

### 2. Premier déploiement

```bash
# ⚠️ ATTENTION : Vérifier que vous êtes bien en production !
# Vérifier la branche
git branch

# Démarrer les conteneurs
docker compose -f ops/production/docker-compose.yml up -d

# Attendre que les conteneurs soient healthy
docker ps

# Initialiser la base de données (si première installation)
# ⚠️ Ce script demande une double confirmation
./ops/production/init-db.sh
```

### 3. Vérification

```bash
# Vérifier que l'application répond
curl http://localhost:3002/up

# Vérifier les logs
docker logs grenoble-roller-production
```

### 4. Configuration du watchdog (déploiement automatique)

```bash
# Ajouter dans le crontab
crontab -e

# Ajouter cette ligne (vérifie toutes les 10 minutes - moins fréquent que staging)
*/10 * * * * cd /opt/Grenoble-Roller-Project && ./ops/production/watchdog.sh >> /tmp/watchdog-production.log 2>&1
```

---

## 🔧 Configuration Réseau (Firewall)

Si vous avez un firewall (ufw, iptables, etc.), ouvrir les ports :

```bash
# Ubuntu/Debian avec ufw
sudo ufw allow 3001/tcp  # Staging
sudo ufw allow 3002/tcp  # Production
sudo ufw reload

# Vérifier
sudo ufw status
```

---

## 🔍 Vérifications Post-Déploiement

### 1. Vérifier que tout fonctionne

```bash
# Staging
curl http://localhost:3001/up
docker ps | grep staging

# Production
curl http://localhost:3002/up
docker ps | grep production
```

### 2. Vérifier les logs

```bash
# Logs de déploiement
tail -f logs/deploy-staging.log
tail -f logs/deploy-production.log

# Logs Docker
docker logs grenoble-roller-staging -f
docker logs grenoble-roller-production -f
```

### 3. Vérifier les backups

```bash
# Lister les backups
ls -lh backups/staging/
ls -lh backups/production/
```

---

## 🔄 Déploiements Manuels

### Déploiement manuel staging

```bash
cd /opt/Grenoble-Roller-Project
./ops/staging/deploy.sh
```

### Déploiement manuel production

```bash
cd /opt/Grenoble-Roller-Project
./ops/production/deploy.sh
```

### Forcer un redéploiement (même si pas de nouvelles versions)

```bash
./ops/staging/deploy.sh --force
./ops/production/deploy.sh --force
```

---

## 🛠️ Scripts Utiles

### Rebuild rapide (après modification de code)

```bash
# Staging
./ops/staging/rebuild.sh

# Production (⚠️ demande confirmation)
./ops/production/rebuild.sh
```

### Initialiser/réinitialiser la base de données

```bash
# Staging
./ops/staging/init-db.sh

# Production (⚠️ demande double confirmation)
./ops/production/init-db.sh
```

---

## 📊 Monitoring

### Vérifier l'état des conteneurs

```bash
docker ps -a
docker stats
```

### Vérifier l'espace disque

```bash
df -h
docker system df
```

### Nettoyer l'espace (si nécessaire)

```bash
# Nettoyer les images inutilisées
docker image prune -a -f

# Nettoyer les volumes inutilisés (⚠️ attention aux données)
docker volume prune -f

# Nettoyer tout (⚠️ très agressif)
docker system prune -a --volumes -f
```

---

## 🚨 Troubleshooting

### Le déploiement ne fonctionne pas

1. **Vérifier les permissions** :
   ```bash
   ls -la ops/staging/deploy.sh
   chmod +x ops/staging/deploy.sh ops/production/deploy.sh
   ```

2. **Vérifier l'accès Git** :
   ```bash
   git fetch origin
   git branch -a
   ```

3. **Vérifier Docker** :
   ```bash
   docker ps
   docker compose version
   ```

### Les conteneurs ne démarrent pas

1. **Vérifier les logs** :
   ```bash
   docker logs grenoble-roller-staging
   docker logs grenoble-roller-db-staging
   ```

2. **Vérifier les ports disponibles** :
   ```bash
   netstat -tuln | grep 3001
   netstat -tuln | grep 3002
   ```

3. **Vérifier l'espace disque** :
   ```bash
   df -h
   ```

### Les migrations échouent

1. **Vérifier que les fichiers sont dans le conteneur** :
   ```bash
   docker exec grenoble-roller-staging ls -la /rails/db/migrate
   ```

2. **Vérifier la connexion à la base** :
   ```bash
   docker exec grenoble-roller-staging bin/rails db:migrate:status
   ```

3. **Rebuild sans cache si nécessaire** :
   ```bash
   ./ops/staging/rebuild.sh
   ```

---

## ✅ Checklist de Déploiement

Avant de déployer en production :

- [ ] Docker et Docker Compose installés et fonctionnels
- [ ] Git configuré avec accès au repository
- [ ] Rails master key configurée (production.key)
- [ ] Credentials Minio correspondant aux valeurs docker-compose
- [ ] Espace disque suffisant (minimum 20 GB)
- [ ] Ports disponibles (3001 staging, 3002 production)
- [ ] Firewall configuré si nécessaire
- [ ] Test en staging réussi
- [ ] Backup de la base de données production (si existante)
- [ ] Watchdog configuré dans crontab

---

## 🔐 Sécurité

### Recommandations

1. **Ne jamais exposer PostgreSQL ou Minio directement** (ils sont dans le réseau Docker interne)

2. **Utiliser un reverse proxy** (nginx, traefik) devant l'application :
   ```nginx
   # Exemple nginx
   server {
       listen 80;
       server_name staging.votre-domaine.com;
       
       location / {
           proxy_pass http://localhost:3001;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```

3. **Activer HTTPS** avec Let's Encrypt (Certbot)

4. **Restreindre l'accès SSH** (clés uniquement, pas de mots de passe)

5. **Surveiller les logs** régulièrement

---

## 📞 Support

En cas de problème :

1. Consulter les logs : `logs/deploy-*.log`
2. Vérifier les logs Docker : `docker logs <container-name>`
3. Consulter la documentation : [`docs/07-ops/deployment.md`](deployment.md)

---

**Version** : 1.0  
**Date** : 2025-01-20

