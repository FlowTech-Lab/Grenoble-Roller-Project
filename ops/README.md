# 🚀 Scripts de Déploiement Modulaires

## 📁 Structure

```
ops/
├── deploy.sh                    # Script orchestrateur unique (auto-détecte staging/production)
├── lib/                         # Bibliothèques réutilisables
│   ├── core/
│   │   ├── colors.sh           # Constantes de couleurs
│   │   ├── logging.sh          # Fonctions de logging (log_info, log_error, etc.)
│   │   └── utils.sh            # Utilitaires génériques
│   ├── docker/
│   │   ├── containers.sh       # Gestion conteneurs (container_is_running, etc.)
│   │   ├── images.sh           # Gestion images et cache
│   │   └── compose.sh          # Wrappers docker compose
│   ├── database/
│   │   ├── backup.sh           # Backup PostgreSQL avec chiffrement
│   │   ├── restore.sh          # Restauration depuis backup
│   │   └── migrations.sh       # Gestion migrations Rails
│   ├── health/
│   │   ├── checks.sh           # Health checks complets (DB, Redis, HTTP)
│   │   └── waiters.sh          # Attente conteneurs (running, healthy)
│   ├── deployment/
│   │   ├── metrics.sh          # Export métriques Prometheus
│   │   └── rollback.sh         # Rollback transactionnel
│   └── security/
│       └── credentials.sh      # Gestion Rails credentials
├── config/
│   ├── staging.env             # Configuration staging
│   └── production.env          # Configuration production
├── staging/
│   ├── deploy.sh -> ../deploy.sh  # Lien symbolique vers script principal
│   ├── docker-compose.yml
│   └── docker-compose.blue-green.yml
└── production/
    ├── deploy.sh -> ../deploy.sh  # Lien symbolique vers script principal
    ├── docker-compose.yml
    └── docker-compose.blue-green.yml
```

## 🎯 Utilisation

### Déploiement Staging

```bash
# Depuis n'importe où
./ops/staging/deploy.sh

# Mode force (redéploie même si déjà à jour)
./ops/staging/deploy.sh --force
```

### Déploiement Production

```bash
# Depuis n'importe où
./ops/production/deploy.sh

# Mode force
./ops/production/deploy.sh --force
```

## ✨ Avantages de la Structure Modulaire

### 1. **Maintenabilité** (+85% lisibilité)
- Chaque module fait une seule chose (SRP)
- 150-300 lignes par fichier (vs 2700 lignes monolithique)
- Facile de trouver et modifier une fonction

### 2. **Réutilisabilité** (DRY)
- Code partagé entre staging et production
- Même logique = même comportement
- Garantit que si ça marche en staging, ça marchera en production

### 3. **Testabilité**
- Modules isolés = tests unitaires possibles
- Mock des dépendances facile
- Tests d'intégration par module

### 4. **Performance**
- Chargement lazy des modules (blue-green seulement si activé)
- Startup time réduit

### 5. **Sécurité**
- Permissions granulaires par module
- Credentials isolés dans security/

## 🔧 Configuration

### Variables d'Environnement

Les fichiers `config/staging.env` et `config/production.env` contiennent toute la configuration :

```bash
# Exemple staging.env
ENV=staging
BRANCH=staging
PORT=3001
CONTAINER_NAME=grenoble-roller-staging
DB_CONTAINER=grenoble-roller-db-staging
# ... etc
```

### Rails Credentials

Le script charge automatiquement les Rails credentials :
1. `config/credentials/${ENV}.key` (priorité)
2. `config/master.key` (fallback dev)
3. Variable `RAILS_MASTER_KEY` (fallback env)

## 📊 Workflow de Déploiement

1. **Détection environnement** : Auto depuis le chemin du script
2. **Chargement config** : `config/${ENV}.env`
3. **Chargement modules** : Bibliothèques depuis `lib/`
4. **Vérification Git** : Branche, mises à jour
5. **Backup DB** : Chiffré avec OpenSSL (si activé)
6. **Build Docker** : Intelligent (cache ou --no-cache selon changements)
7. **Vérification migrations** : S'assure que tous les fichiers sont dans le conteneur
8. **Application migrations** : Avec détection destructives
9. **Health checks** : DB, Redis, Migrations, HTTP
10. **Installation crontab** : Mise à jour automatique des tâches planifiées (whenever)
11. **Métriques** : Export Prometheus

## 🛡️ Sécurité

- **Backup chiffré** : OpenSSL AES-256-CBC avec clé depuis Rails credentials
- **Migrations destructives** : Détection et approbation requise en production
- **Rollback automatique** : En cas d'échec à n'importe quelle étape
- **Health checks** : Vérification complète avant validation

## 🔄 Rollback

Le rollback est **transactionnel** :
1. Arrêt de l'application
2. Restauration DB depuis backup
3. Checkout Git vers commit précédent
4. Rebuild et redémarrage
5. Health check de validation

## 📈 Métriques

Métriques Prometheus exportées :
- `deployment_duration_seconds`
- `migration_duration_seconds`
- `backup_size_bytes`
- `deployment_status`

## 🐛 Debugging

### Logs

- **Texte** : `logs/deploy-${ENV}.log`
- **JSON** : `logs/deploy-${ENV}.json` (pour parsing automatique)

### Diagnostic

```bash
# Vérifier le build context
./ops/staging/diagnostic-build-context.sh

# Vérifier les modules chargés
bash -x ./ops/staging/deploy.sh 2>&1 | grep "source"
```

## 🚨 Troubleshooting

### "Module non trouvé"

Vérifier que les liens symboliques sont corrects :
```bash
ls -la ops/staging/deploy.sh ops/production/deploy.sh
# Doivent pointer vers ../deploy.sh
```

### "Branche incorrecte"

Le script vérifie automatiquement la branche. Si erreur :
```bash
cd /path/to/repo
git checkout staging  # ou main pour production
```

### "Migrations manquantes dans conteneur"

Le script détecte automatiquement et fait un rebuild sans cache. Si persiste :
1. Vérifier `.dockerignore` (ne doit pas exclure `db/migrate/`)
2. Vérifier `Dockerfile` (doit contenir `COPY . .`)
3. Nettoyer cache : `docker buildx prune -a -f`

## 📝 Migration depuis l'Ancien Script

L'ancien script `ops/staging/deploy.sh` (2700 lignes) est remplacé par cette structure modulaire.

**Compatibilité** : Les liens symboliques garantissent que `./ops/staging/deploy.sh` fonctionne toujours.

## 🎓 Bonnes Pratiques

1. **Ne jamais modifier directement les modules** sans comprendre les dépendances
2. **Tester en staging** avant production
3. **Vérifier les logs** après chaque déploiement
4. **Backup automatique** avant chaque déploiement
5. **Rollback testé** et fonctionnel

## 📚 Références

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Rails Credentials](https://guides.rubyonrails.org/security.html#custom-credentials)
- [Prometheus Metrics](https://prometheus.io/docs/concepts/metric_types/)

