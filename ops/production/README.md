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

## ⚙️ Prérequis

1. **Accès GitHub** (SSH recommandé en production) - voir `ops/dev/README.md`

2. **Docker** : Les conteneurs doivent être accessibles

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

