# 🚀 Scripts de déploiement PRODUCTION

Scripts dédiés à l'environnement de production.

## 📋 Fichiers

- **`deploy.sh`** : Script de déploiement automatique PRODUCTION
- **`watchdog.sh`** : Script de surveillance (appelé par cron)
- **`rebuild.sh`** : Rebuild rapide sans cache (pour prendre en compte les changements de code)
- **`init-db.sh`** : Initialisation de la base de données (migrate + seed) - pour fresh install
- **`maintenance.sh`** : Script pour activer/désactiver le mode maintenance
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

### Mode Maintenance

Le mode maintenance permet de bloquer l'accès aux visiteurs anonymes tout en permettant l'accès aux administrateurs connectés. Utile pour les mises à jour ou interventions.

**Utilisation avec le script :**

```bash
# Activer le mode maintenance
sudo ./ops/production/maintenance.sh enable

# Désactiver le mode maintenance
sudo ./ops/production/maintenance.sh disable

# Vérifier le statut
sudo ./ops/production/maintenance.sh status
```

**Utilisation directe (sans script) :**

```bash
# Activer
sudo docker exec grenoble-roller-production bin/rails runner "MaintenanceMode.enable!"

# Désactiver
sudo docker exec grenoble-roller-production bin/rails runner "MaintenanceMode.disable!"

# Vérifier le statut
sudo docker exec grenoble-roller-production bin/rails runner "puts MaintenanceMode.status"
```

**Notes importantes :**
- ✅ **Pas de redémarrage requis** : Le mode maintenance s'active/désactive instantanément
- ✅ **Admins autorisés** : Les administrateurs connectés peuvent toujours accéder au site
- ✅ **Page personnalisée** : Une page de maintenance avec design Grenoble Roller s'affiche aux visiteurs
- ✅ **Routes autorisées** : `/admin`, `/users/sign_in`, `/maintenance` restent accessibles

## 📊 Logs

- **Emplacement** : `logs/deploy-production.log` (dans le projet)
- **Backups** : `backups/production/` (dans le projet)

## 🌐 Configuration Reverse Proxy avec HTTPS - Sécurité Maximale

Le docker-compose de production utilise **Caddy** pour une configuration sécurisée et isolée avec HTTPS automatique :

- ✅ **Isolation complète** : L'application Rails n'est **PAS accessible directement** (pas de ports exposés)
- ✅ **Caddy seul point d'entrée** : Seuls les ports 80 (HTTP) et 443 (HTTPS) sont exposés
- ✅ **HTTPS automatique** : Let's Encrypt avec obtention et renouvellement automatiques
- ✅ **Redirection HTTP → HTTPS** : Toutes les requêtes HTTP sont redirigées vers HTTPS
- ✅ **Réseau Docker isolé** : Communication interne uniquement entre services
- ✅ **Sécurité renforcée** : Headers de sécurité, SSL/TLS optimisé, HSTS, HTTP/3 (QUIC)

### Architecture de sécurité

```
Internet → Caddy (80/443) → Rails App (3000, interne) → DB/MinIO (internes)
```

- **Caddy** : Seul service accessible depuis l'extérieur, gère HTTPS automatiquement
- **Rails App** : Accessible uniquement via réseau Docker interne
- **DB/MinIO** : Accessibles uniquement via réseau Docker interne

### Services utilisés

1. **caddy** : Reverse proxy avec HTTPS automatique (Let's Encrypt intégré)
   - Configuration dans `ops/production/Caddyfile`
   - Obtention et renouvellement automatiques des certificats
   - Support HTTP/2 et HTTP/3 (QUIC)

### Configuration

La configuration Caddy est dans `ops/production/Caddyfile` avec :
- HTTPS automatique (Let's Encrypt)
- Redirection HTTP → HTTPS
- Headers de sécurité (HSTS, X-Frame-Options, CSP, etc.)
- Compression (gzip, zstd)
- Proxy vers l'application Rails (réseau interne)
- Health checks automatiques

### Variables d'environnement

```bash
# .env dans ops/production/ ou variables d'environnement
VIRTUAL_HOST=grenoble-roller.org
LETSENCRYPT_EMAIL=contact@grenoble-roller.org
```

### Première utilisation

1. **Démarrer tous les services** :
   ```bash
   docker compose -f ops/production/docker-compose.yml up -d
   ```

2. **Vérifier que Caddy démarre et obtient le certificat** :
   ```bash
   # Suivre les logs (peut prendre 1-2 minutes pour le certificat)
   docker logs -f grenoble-roller-caddy-production
   ```

3. **Vérifier HTTPS** :
   ```bash
   curl -I https://grenoble-roller.org/up
   ```

### Notes importantes

- ⚠️ **DNS requis** : Le domaine doit pointer vers le serveur avant le démarrage
- ⚠️ **Premier démarrage** : Le certificat Let's Encrypt peut prendre 1-2 minutes
- ✅ **HTTPS automatique** : Caddy obtient et renouvelle les certificats automatiquement
- ✅ **Isolation totale** : L'application n'est accessible QUE via Caddy
- ✅ **Sécurité maximale** : Aucun port de l'application n'est exposé vers l'extérieur
- ✅ **Pas de maintenance** : Plus besoin de scripts Certbot ou de renouvellement manuel

### Migration depuis Nginx+Certbot

Si vous migrez depuis Nginx+Certbot, consultez `MIGRATION_GUIDE.md` pour les détails complets.

## ⚙️ Prérequis

1. **Accès GitHub** (SSH recommandé en production) - voir `ops/dev/README.md`

2. **Docker** : Les conteneurs doivent être accessibles

3. **Port 80 disponible** : Caddy écoute sur le port 80 (et 443 pour HTTPS)

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

