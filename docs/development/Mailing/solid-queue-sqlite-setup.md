# 🔧 Configuration Solid Queue avec SQLite - Guide Complet

**Date** : 2025-12-30  
**Objectif** : Documenter la configuration complète de Solid Queue avec SQLite séparé

---

## ✅ Configuration Effectuée

### 1. Gem SQLite3 Ajoutée

**Fichier** : `Gemfile`
```ruby
gem "sqlite3", "~> 1.7"
```

### 2. Configuration `database.yml`

**Fichier** : `config/database.yml`

**Production/Staging** :
```yaml
production:
  primary: &primary_production
    # ... configuration PostgreSQL ...
  
  queue:
    adapter: sqlite3
    database: storage/solid_queue.sqlite3
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
    timeout: 5000
    migrations_paths: db/queue_migrate
```

**Development** :
```yaml
development:
  primary: &primary_development
    # ... configuration PostgreSQL ...
  
  queue:
    adapter: sqlite3
    database: storage/solid_queue.sqlite3
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
    timeout: 5000
    migrations_paths: db/queue_migrate
```

**Test** :
```yaml
test:
  primary: &primary_test
    # ... configuration PostgreSQL ...
  
  queue:
    adapter: sqlite3
    database: storage/solid_queue_test.sqlite3
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
    timeout: 5000
    migrations_paths: db/queue_migrate
```

### 3. Configuration `active_job.queue_adapter`

**Fichiers** :
- `config/environments/production.rb`
- `config/environments/staging.rb`
- `config/environments/development.rb`

```ruby
config.active_job.queue_adapter = :solid_queue
```

### 4. Initializer Solid Queue

**Fichier** : `config/initializers/solid_queue.rb`

Rails détecte automatiquement la configuration `queue` dans `database.yml`. Pas besoin de configuration supplémentaire.

---

## 📋 Ordre d'Exécution (Confirmé)

### Procédure Correcte

1. **Configuration `database.yml`** (déjà fait ✅)
   - Section `queue` configurée avec SQLite
   - Fichier dans le code source (dans l'image Docker)

2. **Build Docker** (déjà fait ✅)
   - L'image contient `database.yml` avec la configuration SQLite

3. **Démarrage des conteneurs** (déjà fait ✅)
   - PostgreSQL démarre
   - Application démarre

4. **Migrations PostgreSQL** (`db:migrate`)
   - Applique les migrations principales
   - Ne touche pas SQLite

5. **Migrations SQLite Queue** (`db:migrate:queue`)
   - Crée le fichier `storage/solid_queue.sqlite3` si nécessaire
   - Applique les migrations de la queue
   - Ne touche pas PostgreSQL

### ⚠️ Point Critique Identifié

**Le problème** : Le script essaie de faire `db:migrate:queue` mais :
- ✅ `database.yml` est maintenant configuré pour SQLite (corrigé)
- ✅ `active_job.queue_adapter` est maintenant configuré (corrigé)
- ⚠️ Le répertoire `storage/` doit exister (géré dans les scripts)
- ⚠️ Rails peut créer automatiquement le fichier SQLite au premier usage

**Solution** : Les scripts vérifient maintenant que `database.yml` contient la configuration SQLite avant d'essayer de migrer.

---

## 🔍 Vérifications Post-Configuration

### 1. Vérifier la Configuration

```bash
# Vérifier que database.yml contient SQLite pour queue
docker exec grenoble-roller-staging grep -A 5 "queue:" /rails/config/database.yml

# Doit afficher :
#   queue:
#     adapter: sqlite3
#     database: storage/solid_queue.sqlite3
```

### 2. Vérifier que le Fichier SQLite Existe

```bash
# Vérifier que le fichier SQLite existe
docker exec grenoble-roller-staging ls -la /rails/storage/solid_queue.sqlite3

# Si le fichier n'existe pas, Rails le créera automatiquement au premier usage
```

### 3. Tester les Migrations

```bash
# Tester les migrations de la queue
docker exec grenoble-roller-staging bin/rails db:migrate:queue

# Doit créer le fichier SQLite et appliquer les migrations
```

### 4. Vérifier Solid Queue

```bash
# Vérifier que Solid Queue fonctionne
docker exec grenoble-roller-staging bin/rails runner "puts SolidQueue::Job.count"

# Doit retourner : 0 (pas d'erreur)
```

---

## 🚨 Problèmes Connus et Solutions

### Problème 1 : "database does not exist" ou "queue not configured"

**Cause** : `database.yml` n'est pas configuré pour SQLite ou la configuration est incorrecte.

**Solution** :
1. Vérifier que `database.yml` contient `adapter: sqlite3` pour la section `queue`
2. Vérifier que `active_job.queue_adapter = :solid_queue` est défini dans les fichiers d'environnement
3. Rebuild l'image Docker pour inclure la nouvelle configuration

### Problème 2 : "uninitialized constant SolidQueue"

**Cause** : La gem `solid_queue` n'est pas installée ou `active_job.queue_adapter` n'est pas configuré.

**Solution** :
1. Vérifier que `gem "solid_queue"` est dans `Gemfile`
2. Vérifier que `config.active_job.queue_adapter = :solid_queue` est dans les fichiers d'environnement
3. Rebuild l'image Docker

### Problème 3 : Le fichier SQLite n'est pas créé

**Cause** : Le répertoire `storage/` n'existe pas ou n'a pas les permissions.

**Solution** :
1. Les scripts créent automatiquement `storage/` avec `mkdir -p /rails/storage`
2. Vérifier les permissions : `docker exec grenoble-roller-staging ls -la /rails/storage`

---

## 📚 Références Communauté

D'après la recherche web, la procédure standard est :

1. **Configurer `database.yml`** avec SQLite pour la section `queue`
2. **Configurer `active_job.queue_adapter = :solid_queue`** dans les fichiers d'environnement
3. **Exécuter `db:migrate:queue`** pour créer les tables Solid Queue
4. **Rails créera automatiquement le fichier SQLite** si nécessaire

**Source** : [Solid Queue GitHub](https://github.com/rails/solid_queue)

---

## ✅ Checklist de Vérification

- [x] Gem `sqlite3` ajoutée au `Gemfile`
- [x] `database.yml` configuré avec SQLite pour `queue` (production, staging, development, test)
- [x] `config.active_job.queue_adapter = :solid_queue` dans les 3 environnements
- [x] Scripts de déploiement mis à jour pour gérer `db:migrate:queue`
- [x] Vérification que `database.yml` contient SQLite avant migration
- [ ] Tester le déploiement complet
- [ ] Vérifier que le fichier SQLite est créé
- [ ] Vérifier que Solid Queue fonctionne

---

**Date de mise à jour** : 2025-12-30  
**Statut** : ✅ Configuration complète effectuée
