---
title: "Hello Asso - Ajouter les Credentials"
status: "active"
version: "1.0"
created: "2025-01-20"
tags: ["helloasso", "credentials", "setup"]
---

# Hello Asso - Ajouter les Credentials

**Guide étape par étape pour ajouter vos identifiants Hello Asso dans Rails credentials.**

---

## 📋 PRÉREQUIS

Vous devez avoir :
- ✅ **Client ID** Hello Asso (sandbox)
- ✅ **Client Secret** Hello Asso (sandbox)
- ✅ **Organization Slug** (ex: "grenoble-roller") - À confirmer

---

## 🔐 ÉTAPE 1 : Ouvrir les Credentials

```bash
bin/rails credentials:edit
```

Cette commande va :
1. Décrypter `config/credentials.yml.enc`
2. Ouvrir le fichier dans votre éditeur par défaut
3. Vous permettre d'ajouter vos identifiants

---

## 📝 ÉTAPE 2 : Ajouter la Structure Hello Asso

Dans le fichier qui s'ouvre, ajoutez la section suivante :

```yaml
# ... autres credentials existants ...

helloasso:
  client_id: "VOTRE_CLIENT_ID_ICI"
  client_secret: "VOTRE_CLIENT_SECRET_ICI"
  organization_slug: "grenoble-roller"  # À confirmer avec votre compte
  environment: "sandbox"  # ⚠️ Toujours "sandbox" pour commencer
```

### **Exemple complet** :

```yaml
secret_key_base: <votre_secret_key_base_existant>

helloasso:
  client_id: "abc123xyz789"
  client_secret: "secret_abc123xyz789_secret"
  organization_slug: "grenoble-roller"
  environment: "sandbox"
```

---

## ✅ ÉTAPE 3 : Sauvegarder et Fermer

1. **Sauvegarder** le fichier (Ctrl+S ou Cmd+S)
2. **Fermer** l'éditeur
3. Rails va automatiquement :
   - Re-chiffrer le fichier
   - Sauvegarder dans `config/credentials.yml.enc`

---

## 🧪 ÉTAPE 4 : Vérifier que les Credentials sont Bien Ajoutés

```bash
bin/rails credentials:show
```

Vous devriez voir votre section `helloasso` avec les valeurs (masquées pour la sécurité).

**Ou tester dans la console Rails** :

```bash
bin/rails console
```

Puis dans la console :

```ruby
# Vérifier que les credentials sont accessibles
Rails.application.credentials.dig(:helloasso, :client_id)
# => "votre_client_id"

Rails.application.credentials.dig(:helloasso, :client_secret)
# => "votre_client_secret"

Rails.application.credentials.dig(:helloasso, :organization_slug)
# => "grenoble-roller"

Rails.application.credentials.dig(:helloasso, :environment)
# => "sandbox"
```

---

## ⚠️ SÉCURITÉ - RÈGLES IMPORTANTES

### ✅ **À FAIRE** :
- ✅ Stocker les credentials dans `config/credentials.yml.enc` (chiffré)
- ✅ Utiliser `bin/rails credentials:edit` pour modifier
- ✅ Vérifier que `config/master.key` est dans `.gitignore`
- ✅ Ne jamais commiter `config/master.key`

### ❌ **À NE JAMAIS FAIRE** :
- ❌ Mettre les credentials dans le code source
- ❌ Mettre les credentials dans un fichier `.env` non chiffré
- ❌ Commiter `config/master.key` dans Git
- ❌ Partager les credentials par email ou chat non sécurisé

---

## 🔄 Pour la Production (Plus Tard)

Quand vous passerez en production, vous pourrez ajouter :

```yaml
helloasso:
  client_id: "votre_client_id_sandbox"
  client_secret: "votre_client_secret_sandbox"
  organization_slug: "grenoble-roller"
  environment: "sandbox"
  # Production (à ajouter quand vous passerez en prod)
  client_id_production: "votre_client_id_production"
  client_secret_production: "votre_client_secret_production"
```

Ou utiliser des variables d'environnement en production :

```bash
# En production
export HELLOASSO_CLIENT_ID="votre_client_id_production"
export HELLOASSO_CLIENT_SECRET="votre_client_secret_production"
```

---

## 📝 NOTES

- Le fichier `config/credentials.yml.enc` est **chiffré** et peut être commité dans Git
- Le fichier `config/master.key` est **déchiffré** et **NE DOIT JAMAIS** être commité
- Les credentials sont accessibles via `Rails.application.credentials.dig(:helloasso, :key)`

---

## ✅ VALIDATION

Une fois les credentials ajoutés, vous pouvez passer à l'étape suivante : **Créer le service Hello Asso**.

---

**Dernière mise à jour** : 2025-01-20  
**Version** : 1.0

