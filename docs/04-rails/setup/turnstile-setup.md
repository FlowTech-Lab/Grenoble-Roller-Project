# 🔒 Cloudflare Turnstile - Configuration

**Dernière mise à jour** : 2025-12-07  
**Statut** : ✅ **Configuré**

---

## 📋 Vue d'ensemble

Cloudflare Turnstile est un système de vérification anti-bot invisible qui protège les formulaires d'inscription et de connexion sans impacter l'expérience utilisateur.

### Avantages

- ✅ **Vérification quasi-invisible** : Fonctionne en arrière-plan sans interaction utilisateur
- ✅ **Privé** : Collecte minimale de données (conforme RGPD)
- ✅ **Ultra-léger** : Moins de 1KB, impact minimal sur les performances
- ✅ **Gratuit** : 1M requêtes/mois gratuites
- ✅ **Flexible** : Personnalisable, design épuré

---

## ⚙️ Configuration

### 1. Obtenir les clés Cloudflare Turnstile

1. Se connecter au dashboard Cloudflare : https://dash.cloudflare.com/
2. Aller dans **Security** → **Turnstile**
3. Cliquer sur **Add Site**
4. Configurer :
   - **Site Name** : `Grenoble Roller`
   - **Domain** : `grenoble-roller.org` (et `dev-grenoble-roller.flowtech-lab.org` pour dev)
   - **Widget Mode** : `Invisible` (recommandé pour UX)
5. Récupérer :
   - **Site Key** (clé publique)
   - **Secret Key** (clé privée)

### 2. Configuration des variables d'environnement

**Fichier** : `.env` ou Rails credentials (recommandé pour production)

```bash
# Cloudflare Turnstile
TURNSTILE_SITE_KEY=your_site_key_here
TURNSTILE_SECRET_KEY=your_secret_key_here
```

**OU via Rails credentials (recommandé)** :

```bash
docker compose -f ops/dev/docker-compose.yml run --rm -it -e EDITOR=nano web bin/rails credentials:edit
```

**Structure YAML à ajouter** :
```yaml
turnstile:
  site_key: your_site_key_here
  secret_key: your_secret_key_here
```

### 3. Implémentation

Turnstile est intégré **manuellement** (pas de gem disponible sur RubyGems) :

- **Concern** : `app/controllers/concerns/turnstile_verifiable.rb` - Vérification côté serveur
- **JavaScript** : Script Cloudflare directement intégré dans les vues
- **Vérification serveur** : Requête HTTP à l'API Cloudflare

**Aucune installation de gem nécessaire** - Tout est déjà en place dans le code.

---

## 🚀 Intégration

### Concern TurnstileVerifiable

Le concern `TurnstileVerifiable` est inclus dans `ApplicationController`, donc disponible dans tous les contrôleurs :

```ruby
# app/controllers/application_controller.rb
include TurnstileVerifiable
```

**Méthode disponible** : `verify_turnstile` - Retourne `true` si vérification réussie, `false` sinon.

### Contrôleurs

#### RegistrationsController
- ✅ Vérification Turnstile avant création du compte via `verify_turnstile`
- ✅ Message d'erreur si vérification échoue

#### SessionsController
- ✅ Vérification Turnstile avant authentification via `verify_turnstile`
- ✅ Message d'erreur si vérification échoue

### Vues

#### Formulaire d'inscription (`app/views/devise/registrations/new.html.erb`)
- ✅ Widget Turnstile invisible intégré
- ✅ Script JavaScript pour gestion automatique

#### Formulaire de connexion (`app/views/devise/sessions/new.html.erb`)
- ✅ Widget Turnstile invisible intégré
- ✅ Script JavaScript pour gestion automatique

---

## 🧪 Tests

### Mode Test

En environnement `test`, Turnstile est automatiquement désactivé (skip verification) pour permettre les tests automatisés.

```ruby
# app/controllers/concerns/turnstile_verifiable.rb
def verify_turnstile
  return true if Rails.env.test? # Skip en test
  # ... vérification
end
```

### Tests Manuels

1. **Désactiver temporairement Turnstile** (si besoin de tester sans) :
   - Commenter la vérification dans les contrôleurs
   - OU utiliser des clés de test Cloudflare

2. **Tester avec clés réelles** :
   - Configurer les variables d'environnement
   - Tester l'inscription et la connexion
   - Vérifier que la vérification fonctionne (dans les DevTools, onglet Network)

---

## 🔒 Sécurité

### Protection Multi-Couches

1. **Turnstile** : Vérification invisible anti-bot
2. **Rate Limiting (Rack::Attack)** : 
   - 5 tentatives de connexion / 15 min par IP
   - 3 inscriptions / heure par IP
3. **Confirmation Email** : Validation de l'adresse email
4. **Validation Serveur** : Vérification côté serveur de tous les paramètres

### Conformité RGPD

- ✅ Cloudflare Turnstile est conforme RGPD
- ✅ Collecte minimale de données
- ✅ Pas de tracking utilisateur
- ✅ Données hébergées en Europe (option disponible)

---

## 📊 Monitoring

### Logs

Les échecs de vérification Turnstile sont loggés automatiquement. Vérifier les logs :

```bash
docker compose -f ops/dev/docker-compose.yml logs web | grep -i turnstile
```

### Dashboard Cloudflare

Le dashboard Cloudflare Turnstile permet de voir :
- Nombre de vérifications
- Taux de succès/échec
- Statistiques par domaine

---

## 🛠️ Dépannage

### Le widget ne s'affiche pas

1. Vérifier que `TURNSTILE_SITE_KEY` est configuré
2. Vérifier la console JavaScript pour erreurs
3. Vérifier que le script Cloudflare est chargé (Network tab)

### Vérification échoue toujours

1. Vérifier que `TURNSTILE_SECRET_KEY` est configuré correctement
2. Vérifier les logs Rails pour erreurs détaillées
3. Vérifier que le domaine est bien configuré dans Cloudflare

### En développement local

Pour tester en développement local (localhost), il faut :
1. Ajouter `localhost` ou `127.0.0.1` dans les domaines autorisés Cloudflare
2. OU utiliser les clés de test Cloudflare :
   - Site Key : `1x00000000000000000000AA`
   - Secret Key : `1x0000000000000000000000000000000AA`

---

## 📚 Documentation

- **Cloudflare Turnstile** : https://developers.cloudflare.com/turnstile/
- **Gem turnstile-rails** : https://github.com/patleb/turnstile-rails
- **Best Practices** : https://developers.cloudflare.com/turnstile/get-started/server-side-validation/

---

## ✅ Checklist de Déploiement

### Pré-Production

- [ ] Créer un site Turnstile dans Cloudflare dashboard
- [ ] Configurer les clés dans Rails credentials (ou variables d'environnement)
- [ ] Tester l'inscription avec Turnstile
- [ ] Tester la connexion avec Turnstile
- [ ] Vérifier les logs pour erreurs

### Production

- [ ] Configurer le domaine de production dans Cloudflare Turnstile
- [ ] Utiliser Rails credentials pour stocker les clés secrètes
- [ ] Vérifier que le rate limiting fonctionne correctement
- [ ] Monitorer les logs pour échecs de vérification

---

**Version** : 1.0  
**Date de création** : 2025-12-07  
**Statut** : ✅ Opérationnel

