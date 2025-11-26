---
title: "Hello Asso - Étape 1 : Récupération des Informations API"
status: "active"
version: "1.0"
created: "2025-01-20"
tags: ["helloasso", "api", "integration", "etape-1"]
---

# Hello Asso - Étape 1 : Récupération des Informations API

**Objectif** : Récupérer toutes les informations nécessaires pour intégrer l'API Hello Asso dans l'application.

---

## 📋 CHECKLIST PRÉLIMINAIRE

### ✅ **À Faire AVANT de commencer le code**

- [ ] **1. Créer/Accéder au compte Hello Asso de l'association**
  - URL : https://www.helloasso.com/
  - Se connecter avec le compte de l'association Grenoble Roller
  - Vérifier que le compte est actif et validé

- [ ] **2. Accéder à la section API**
  - Aller dans "Mon compte" → "Intégrations et API"
  - Ou directement : https://www.helloasso.com/associations/grenoble-roller/parametres/api
  - Vérifier les permissions d'accès API

- [ ] **3. Obtenir les identifiants OAuth2**
  - **Client ID** : Identifiant public de l'application
  - **Client Secret** : Secret à garder confidentiel (jamais dans le code)
  - **Organization Slug** : Identifiant de l'organisation (ex: "grenoble-roller")
  - ⚠️ **IMPORTANT** : Noter ces informations dans un endroit sécurisé

- [ ] **4. Comprendre le flux OAuth2**
  - Hello Asso utilise OAuth2 pour l'authentification
  - Il faut obtenir un **token d'accès** (access token) avant chaque requête API
  - Le token a une durée de vie limitée (à vérifier dans la doc)

- [ ] **5. Consulter la documentation API**
  - Documentation officielle : https://api.helloasso.com/v5/docs
  - Documentation développeur : https://dev.helloasso.com/
  - Endpoints disponibles et leurs paramètres

- [ ] **6. Tester dans l'environnement Sandbox**
  - Créer un compte sandbox si nécessaire
  - Tester l'authentification OAuth2
  - Tester la création d'une commande de test

---

## 🔐 INFORMATIONS À RÉCUPÉRER

### **1. Identifiants OAuth2**

Ces informations doivent être stockées dans les **Rails credentials** (jamais dans le code) :

```yaml
# config/credentials.yml.enc
helloasso:
  client_id: "votre_client_id_sandbox"        # Client ID sandbox
  client_secret: "votre_client_secret_sandbox" # Client Secret sandbox
  organization_slug: "grenoble-roller"        # À confirmer
  environment: "sandbox"                      # ⚠️ TOUJOURS "sandbox" pour commencer
  # Pour production (à ajouter plus tard) :
  # client_id_production: "votre_client_id_production"
  # client_secret_production: "votre_client_secret_production"
```

### **2. URLs API**

#### **Environnement SANDBOX** (Tests - À utiliser en premier) ⚠️
- **Base URL API** : `https://api.helloasso-sandbox.com/v5`
- **URL OAuth2** : `https://api.helloasso-sandbox.com/oauth2`
- **Obtenir vos tokens** : https://api.helloasso-sandbox.com/oauth2
- **Faire vos appels API** : https://api.helloasso-sandbox.com/v5

#### **Environnement PRODUCTION** (À utiliser uniquement après tests complets)
- **Base URL API** : `https://api.helloasso.com/v5`
- **URL OAuth2** : `https://api.helloasso.com/oauth2`

### **3. Endpoints Nécessaires**

D'après nos besoins, nous aurons besoin de :

#### **Authentification**
- `POST https://api.helloasso-sandbox.com/oauth2` - Obtenir un token d'accès (SANDBOX)
- `POST https://api.helloasso.com/oauth2` - Obtenir un token d'accès (PRODUCTION)

#### **Commandes (Orders)**
- `POST https://api.helloasso-sandbox.com/v5/organizations/{organizationSlug}/orders` - Créer une commande
- `GET https://api.helloasso-sandbox.com/v5/organizations/{organizationSlug}/orders/{orderId}` - Récupérer une commande
- `GET https://api.helloasso-sandbox.com/v5/organizations/{organizationSlug}/orders` - Lister les commandes

#### **Paiements (Payments)**
- `GET https://api.helloasso-sandbox.com/v5/organizations/{organizationSlug}/payments/{paymentId}` - Récupérer un paiement
- `GET https://api.helloasso-sandbox.com/v5/organizations/{organizationSlug}/payments` - Lister les paiements

> ⚠️ **Remplacer `helloasso-sandbox.com` par `helloasso.com` pour la production**

#### **Webhooks**
- Configuration des webhooks dans le compte Hello Asso
- URL de callback : `https://votre-domaine.com/webhooks/helloasso`

---

## 📚 DOCUMENTATION À CONSULTER

### **Liens Essentiels**

1. **Documentation API v5**
   - URL : https://api.helloasso.com/v5/docs
   - Endpoints disponibles, paramètres, réponses

2. **Documentation Développeur**
   - URL : https://dev.helloasso.com/
   - Guides d'intégration, exemples de code

3. **Guide OAuth2**
   - URL : https://dev.helloasso.com/docs/introduction-%C3%A0-lapi-de-helloasso
   - Flux d'authentification détaillé

4. **Centre d'aide**
   - URL : https://centredaide.helloasso.com/
   - FAQ et support

### **Informations Clés à Noter**

- **Durée de vie du token** : Combien de temps le token est valide ?
- **Rate limiting** : Limites de requêtes par minute/heure ?
- **Format des montants** : En centimes ? En euros ?
- **Format des dates** : ISO 8601 ? Autre format ?
- **Gestion des erreurs** : Codes d'erreur et leurs significations
- **Webhooks disponibles** : Quels événements peuvent déclencher un webhook ?

---

## 🔄 FLUX OAuth2 (À Comprendre)

### **Étape 1 : Obtenir un Token d'Accès (SANDBOX)**

```http
POST https://api.helloasso-sandbox.com/oauth2
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials
&client_id=VOTRE_CLIENT_ID_SANDBOX
&client_secret=VOTRE_CLIENT_SECRET_SANDBOX
```

**Réponse attendue** :
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

### **Étape 2 : Utiliser le Token pour les Requêtes API (SANDBOX)**

```http
GET https://api.helloasso-sandbox.com/v5/organizations/grenoble-roller/orders
Authorization: Bearer {access_token}
```

> ⚠️ **IMPORTANT** : Utiliser les URLs sandbox (`api.helloasso-sandbox.com`) pour tous les tests !

---

## 🧪 ENVIRONNEMENT SANDBOX ⚠️ **OBLIGATOIRE**

### **⚠️ RÈGLE D'OR : TOUS LES TESTS EN SANDBOX AVANT PRODUCTION**

**URLs Sandbox** :
- **OAuth2** : https://api.helloasso-sandbox.com/oauth2
- **API v5** : https://api.helloasso-sandbox.com/v5

### **Pourquoi Tester en Sandbox ?**

- ✅ Tester sans risquer de vrais paiements
- ✅ Valider le flux complet avant production
- ✅ Déboguer les erreurs sans impact
- ✅ Tester tous les scénarios (succès, échec, annulation)
- ✅ Valider les webhooks sans impact réel

### **Actions à Faire**

- [ ] Créer un compte sandbox Hello Asso (si nécessaire)
- [ ] Obtenir les identifiants sandbox (Client ID, Client Secret)
- [ ] **Utiliser les URLs sandbox** : `api.helloasso-sandbox.com`
- [ ] Tester l'authentification OAuth2 en sandbox
- [ ] Créer une commande de test en sandbox
- [ ] Tester les webhooks en sandbox (utiliser ngrok ou équivalent pour exposer localhost)
- [ ] Valider TOUT le flux en sandbox avant de passer en production

### **⚠️ Passage en Production**

**NE PAS passer en production tant que :**
- [ ] Tous les tests sandbox sont OK
- [ ] Le flux complet fonctionne (création commande → paiement → webhook)
- [ ] Les erreurs sont gérées correctement
- [ ] Les webhooks sont testés et fonctionnels

---

## 📝 NOTES IMPORTANTES

### **Sécurité**

- ⚠️ **JAMAIS** stocker les credentials dans le code source
- ✅ Utiliser Rails credentials (`config/credentials.yml.enc`)
- ✅ Utiliser des variables d'environnement en production
- ✅ Ne jamais commiter `config/master.key`

### **Gestion du Token**

- Le token expire après un certain temps (à vérifier dans la doc, probablement 3600 secondes = 1h)
- Il faut gérer le renouvellement automatique du token
- Option 1 : Obtenir un nouveau token à chaque requête (simple mais moins performant)
- Option 2 : Mettre en cache le token et le renouveler quand il expire (recommandé)
- ⚠️ **Utiliser les URLs sandbox** pour obtenir le token pendant les tests

### **Format des Données**

- **Montants** : À vérifier dans la doc (probablement en centimes d'euros)
- **Dates** : Format ISO 8601 probablement
- **Devise** : EUR pour l'euro

---

## ✅ VALIDATION DE L'ÉTAPE 1

Cette étape est terminée quand :

- [x] Compte Hello Asso accessible
- [x] Identifiants OAuth2 récupérés (Client ID, Client Secret)
- [x] Organization Slug identifié
- [x] Documentation API consultée
- [x] Flux OAuth2 compris
- [x] Endpoints nécessaires identifiés
- [x] **Credentials ajoutés dans Rails** (voir [`helloasso-ajouter-credentials.md`](helloasso-ajouter-credentials.md))
- [x] Test d'authentification OAuth2 réussi (en sandbox)
- [x] Informations documentées dans ce fichier

---

## 🎯 PROCHAINE ÉTAPE

Une fois cette étape validée, passer à **Étape 2 : Implémentation du Service Hello Asso**

**Fichiers à créer** :
- `app/services/helloasso_service.rb` - Service principal
- `app/services/helloasso/oauth_service.rb` - Gestion OAuth2 (optionnel, peut être dans le service principal)

---

**Dernière mise à jour** : 2025-01-20  
**Version** : 1.0

