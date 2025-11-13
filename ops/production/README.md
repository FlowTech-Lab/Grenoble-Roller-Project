# 🚀 Scripts de déploiement PRODUCTION

Scripts dédiés à l'environnement de production.

## 📋 Fichiers

- **`deploy.sh`** : Script de déploiement automatique PRODUCTION
- **`watchdog.sh`** : Script de surveillance (appelé par cron)

## ✨ Fonctionnalités automatiques

- ✅ **Création automatique des dossiers** : `backups/production` et `logs/`
- ✅ **Vérification de branche** : Vérifie et passe automatiquement sur `main`
- ✅ **Vérification accès GitHub** : Détecte si SSH/HTTPS est configuré
- ✅ **Rollback automatique** : En cas d'échec, retour à la version précédente + restauration DB

## 🚀 Utilisation

### Test manuel

```bash
# Depuis la racine du projet
./ops/production/deploy.sh
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

