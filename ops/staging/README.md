# 🚀 Scripts de déploiement STAGING

Scripts dédiés à l'environnement de staging.

## 📋 Fichiers

- **`deploy.sh`** : Script de déploiement automatique STAGING
- **`watchdog.sh`** : Script de surveillance (appelé par cron)

## ✨ Fonctionnalités automatiques

- ✅ **Création automatique des dossiers** : `backups/staging` et `logs/`
- ✅ **Vérification de branche** : Vérifie et passe automatiquement sur `staging`
- ✅ **Vérification accès GitHub** : Détecte si SSH/HTTPS est configuré
- ✅ **Rollback automatique** : En cas d'échec, retour à la version précédente

## 🚀 Utilisation

### Test manuel

```bash
# Depuis la racine du projet
./ops/staging/deploy.sh
```

### Automatisation (cron)

```bash
# Toutes les 5 minutes
*/5 * * * * cd /chemin/vers/projet && ./ops/staging/watchdog.sh
```

## 📊 Logs

- **Emplacement** : `logs/deploy-staging.log` (dans le projet)
- **Backups** : `backups/staging/` (dans le projet)

## ⚙️ Prérequis

1. **Accès GitHub** (SSH ou HTTPS) - voir `ops/dev/README.md`

2. **Docker** : Les conteneurs doivent être accessibles

## 🔍 Vérification rapide

```bash
# Vérifier l'accès GitHub
git fetch origin

# Vérifier la branche
git branch

# Tester le script
./ops/staging/deploy.sh
```

---

**C'est tout !** Le script gère le reste automatiquement.

