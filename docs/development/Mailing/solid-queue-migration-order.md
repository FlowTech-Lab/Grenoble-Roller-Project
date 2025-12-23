# 📋 Ordre d'Exécution - Migrations PostgreSQL & SQLite Queue

**Date** : 2025-12-30  
**Objectif** : Documenter et confirmer l'ordre d'exécution des migrations pour PostgreSQL et SQLite Queue

---

## ✅ Ordre Confirmé et Cohérent

### Principe Général

**Toujours dans cet ordre** :
1. **PostgreSQL d'abord** (base principale)
2. **SQLite ensuite** (queue Solid Queue)
3. **Seed PostgreSQL** (si nécessaire)

**Raison** : PostgreSQL contient les données applicatives critiques, SQLite contient uniquement les jobs en queue (moins critique).

---

## 📝 Scripts et Ordre d'Exécution

### 1. `ops/staging/init-db.sh`

**Ordre d'exécution** :
```bash
1. db:migrate (PostgreSQL)          # Migrations principales
2. db:migrate:queue (SQLite)        # Migrations queue
3. db:seed (PostgreSQL)             # Seed données
```

**Lignes** :
- Ligne 77 : `db:migrate` (PostgreSQL)
- Ligne 95 : `db:migrate:queue` (SQLite)
- Ligne 116 : `db:seed` (PostgreSQL)

**✅ Confirmé** : Ordre correct et cohérent

---

### 2. `ops/production/init-db.sh`

**Ordre d'exécution** :
```bash
1. db:migrate (PostgreSQL)          # Migrations principales
2. db:migrate:queue (SQLite)        # Migrations queue
3. db:seed (PostgreSQL)             # Seed données (seeds_production.rb ou seeds.rb)
```

**Lignes** :
- Ligne 117 : `db:migrate` (PostgreSQL)
- Ligne 135 : `db:migrate:queue` (SQLite)
- Ligne 144/153 : `db:seed` (PostgreSQL)

**✅ Confirmé** : Ordre correct et cohérent

---

### 3. `ops/lib/database/migrations.sh` (fonction `apply_migrations`)

**Utilisé par** : `ops/deploy.sh` (staging/production)

**Ordre d'exécution** :
```bash
1. db:migrate (PostgreSQL)          # Migrations principales
   └─ Vérification post-migration (ligne 257)
2. db:migrate:queue (SQLite)        # Migrations queue
   └─ Gestion erreurs non bloquantes
```

**Lignes** :
- Ligne 225/229 : `db:migrate` (PostgreSQL)
- Ligne 257 : Vérification `db:migrate:status` (PostgreSQL)
- Ligne 285/288 : `db:migrate:queue` (SQLite)

**✅ Confirmé** : Ordre correct et cohérent

---

### 4. `ops/dev/deploy.sh`

**Ordre d'exécution** :
```bash
1. db:reset (PostgreSQL)            # Drop + Create + Schema Load + Seed
   └─ Fallback : db:migrate si échec
2. db:migrate:queue (SQLite)        # Migrations queue
```

**Lignes** :
- Ligne 318 : `db:reset` (PostgreSQL) - inclut `db:seed`
- Ligne 351 : `db:migrate:queue` (SQLite)

**✅ Confirmé** : Ordre correct et cohérent

**Note** : `db:reset` inclut déjà `db:seed`, donc pas besoin de seed séparé.

---

## 🔒 Garanties de Séparation

### PostgreSQL (Base Principale)

**Commandes qui touchent PostgreSQL** :
- `db:migrate` : Applique migrations en attente (sécurisé)
- `db:reset` : Drop + Create + Schema + Seed (destructif, dev uniquement)
- `db:seed` : Peuple la base avec les données initiales

**Ne touche JAMAIS** :
- ❌ La queue SQLite (`storage/solid_queue.sqlite3`)
- ❌ Les jobs en cours dans Solid Queue

### SQLite (Queue Solid Queue)

**Commandes qui touchent SQLite** :
- `db:migrate:queue` : Applique migrations de la queue (sécurisé)

**Ne touche JAMAIS** :
- ❌ La base PostgreSQL
- ❌ Les données applicatives (users, events, attendances, etc.)

---

## 📊 Tableau Récapitulatif

| Script | Étape 1 | Étape 2 | Étape 3 | Environnement |
|--------|---------|---------|---------|---------------|
| `staging/init-db.sh` | `db:migrate` (PostgreSQL) | `db:migrate:queue` (SQLite) | `db:seed` (PostgreSQL) | Staging |
| `production/init-db.sh` | `db:migrate` (PostgreSQL) | `db:migrate:queue` (SQLite) | `db:seed` (PostgreSQL) | Production |
| `lib/database/migrations.sh` | `db:migrate` (PostgreSQL) | `db:migrate:queue` (SQLite) | - | Staging/Production |
| `dev/deploy.sh` | `db:reset` (PostgreSQL) | `db:migrate:queue` (SQLite) | - | Development |

**✅ Tous les scripts respectent le même ordre** : PostgreSQL → SQLite

---

## ⚠️ Points d'Attention

### 1. `db:reset` en Development

**Comportement** :
- `db:reset` fait : `db:drop` + `db:create` + `db:schema:load` + `db:seed`
- **Ne touche QUE PostgreSQL**
- La queue SQLite reste **intacte**

**Utilisation** : Uniquement en development (`ops/dev/deploy.sh`)

### 2. Gestion des Erreurs

**PostgreSQL** :
- ❌ **Bloquant** : Si `db:migrate` échoue, le script s'arrête
- ✅ **Critique** : Les données applicatives doivent être cohérentes

**SQLite Queue** :
- ⚠️ **Non bloquant** : Si `db:migrate:queue` échoue, le script continue
- ✅ **Raison** : La queue peut être créée automatiquement au premier usage
- ✅ **Raison** : Les jobs peuvent être recréés si nécessaire

### 3. Vérifications Post-Migration

**PostgreSQL** :
- Vérification `db:migrate:status` après migration
- Si migrations en attente → Erreur

**SQLite Queue** :
- Pas de vérification stricte (non bloquant)
- Logs d'avertissement si échec

---

## 🎯 Ordre Optimal Confirmé

### Pourquoi cet ordre ?

1. **PostgreSQL d'abord** :
   - Base principale avec données critiques
   - Doit être à jour avant que les jobs puissent s'exécuter
   - Les jobs peuvent dépendre de nouvelles colonnes/tables

2. **SQLite ensuite** :
   - Queue secondaire, moins critique
   - Peut être créée/migrée indépendamment
   - Les jobs peuvent attendre si nécessaire

3. **Seed en dernier** :
   - Nécessite que les migrations soient appliquées
   - Peuple la base avec données initiales
   - Uniquement dans `init-db.sh` (pas dans `deploy.sh`)

---

## ✅ Validation Finale

**Ordre confirmé dans tous les scripts** :
- ✅ `ops/staging/init-db.sh`
- ✅ `ops/production/init-db.sh`
- ✅ `ops/lib/database/migrations.sh`
- ✅ `ops/dev/deploy.sh`

**Séparation garantie** :
- ✅ PostgreSQL et SQLite sont complètement indépendants
- ✅ Aucune commande ne peut affecter les deux bases simultanément
- ✅ Les jobs en queue restent intacts lors des opérations PostgreSQL

**Gestion des erreurs** :
- ✅ PostgreSQL : Bloquant (critique)
- ✅ SQLite : Non bloquant (peut être recréé)

---

**Date de validation** : 2025-12-30  
**Statut** : ✅ **ORDRE CONFIRMÉ ET COHÉRENT**
