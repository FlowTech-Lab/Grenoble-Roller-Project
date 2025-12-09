# 🚀 Scripts de déploiement PRODUCTION

Scripts dédiés à l'environnement de production.

## 📋 Fichiers

- **`deploy.sh`** : Script de déploiement automatique PRODUCTION
- **`watchdog.sh`** : Script de surveillance (appelé par cron)
- **`rebuild.sh`** : Rebuild rapide sans cache (pour prendre en compte les changements de code)
- **`init-db.sh`** : Initialisation de la base de données (migrate + seed) - pour fresh install
- **`config.sh`** : Configuration centralisée avec timeouts adaptés à la production

## ✨ Fonctionnalités automatiques

- ✅ **Création automatique des dossiers** : `backups/production` et `logs/`
- ✅ **Vérification de branche** : Vérifie et passe automatiquement sur `main`
- ✅ **Vérification accès GitHub** : Détecte si SSH/HTTPS est configuré
- ✅ **Rollback automatique** : En cas d'échec, retour à la version précédente + restauration DB

## 🚀 Utilisation

### Déploiement automatique

```bash
# Depuis la racine du projet
./ops/production/deploy.sh
```

### Rebuild manuel (après modification de code/seeds)

```bash
# ⚠️  ATTENTION: Rebuild sans cache pour prendre en compte les changements
# Cela peut causer un downtime de 10-15 minutes
./ops/production/rebuild.sh

# Puis initialiser la DB si nécessaire
./ops/production/init-db.sh
```

### Initialisation base de données (fresh install)

```bash
# ⚠️  ATTENTION: Migrate + Seed en PRODUCTION
# Ce script demande une double confirmation pour sécurité
./ops/production/init-db.sh
```

### Automatisation (cron)

```bash
# Toutes les 10 minutes (moins fréquent que staging)
*/10 * * * * cd /chemin/vers/projet && ./ops/production/watchdog.sh
```

## 📊 Logs

- **Emplacement** : `logs/deploy-production.log` (dans le projet)
- **Backups** : `backups/production/` (dans le projet)

## 🌐 Configuration Reverse Proxy avec HTTPS Automatique

Le docker-compose de production utilise **nginx-proxy** + **acme-companion** pour automatiser complètement HTTPS :

- ❌ **HTTP (port 80) : BLOQUÉ** - Toutes les requêtes HTTP sont refusées
- ✅ **HTTPS (port 443) : OBLIGATOIRE** - Seul accès autorisé avec Let's Encrypt (automatique)
- ✅ **Renouvellement automatique** des certificats SSL
- ✅ **Configuration automatique** de nginx (pas besoin de nginx.conf manuel)
- ✅ **Double sécurité** : nginx-proxy bloque HTTP + Rails force SSL

### Services utilisés

1. **nginx-proxy** : Génère automatiquement la configuration nginx
2. **acme-companion** : Gère Let's Encrypt (obtention + renouvellement automatique)

### Configuration

La configuration se fait via des **variables d'environnement et labels Docker** sur le service `web` :

- `VIRTUAL_HOST` : Domaines à exposer (par défaut : `grenoble-roller.org,www.grenoble-roller.org`)
- `LETSENCRYPT_EMAIL` : Email pour Let's Encrypt (par défaut : `contact@grenoble-roller.org`)
- `HTTPS_METHOD: nohttp` : **Bloque complètement HTTP** (pas de redirection, refus direct)

### Variables d'environnement optionnelles

Vous pouvez personnaliser via un fichier `.env` ou des variables d'environnement :

```bash
# .env dans ops/production/
VIRTUAL_HOST=grenoble-roller.org,www.grenoble-roller.org
LETSENCRYPT_EMAIL=contact@grenoble-roller.org
```

### Première utilisation

1. **Démarrer les services** :
   ```bash
   docker compose -f ops/production/docker-compose.yml up -d
   ```

2. **Vérifier les certificats** :
   ```bash
   docker logs grenoble-roller-acme-companion
   ```

3. **Tester HTTPS** :
   ```bash
   curl https://grenoble-roller.org/up
   ```

### Notes importantes

- ⚠️ **Premier démarrage** : La génération du certificat Let's Encrypt peut prendre 1-2 minutes
- ⚠️ **DNS requis** : Le domaine `grenoble-roller.org` doit pointer vers le serveur avant le démarrage
- ✅ **Renouvellement automatique** : Les certificats sont renouvelés automatiquement avant expiration
- ✅ **Redirection HTTP → HTTPS** : Automatique via nginx-proxy

## ⚙️ Prérequis

1. **Accès GitHub** (SSH recommandé en production) - voir `ops/dev/README.md`

2. **Docker** : Les conteneurs doivent être accessibles

3. **Port 80 disponible** : Nginx écoute sur le port 80 (et 443 pour HTTPS)

## 🔍 Vérification rapide

```bash
# Vérifier l'accès GitHub
git fetch origin

# Vérifier la branche
git branch

# Tester le script
./ops/production/deploy.sh
```

---

**C'est tout !** Le script gère le reste automatiquement.

