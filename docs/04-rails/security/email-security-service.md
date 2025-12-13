---
title: "Service de Sécurité Email (EmailSecurityService) - Grenoble Roller"
status: "active"
version: "1.0"
created: "2025-01-30"
updated: "2025-01-30"
tags: ["security", "email", "monitoring", "sentry"]
---

# Service de Sécurité Email (EmailSecurityService)

**Dernière mise à jour** : 2025-01-30

Ce document décrit le service de détection des anomalies de sécurité liées aux confirmations email (email scanners, attaques brute force).

---

## 📋 Vue d'Ensemble

Le `EmailSecurityService` est un service de sécurité qui détecte et alerte sur les anomalies liées aux confirmations email :

1. **Email scanners** : Détection des clics automatiques (< 10 secondes après envoi)
2. **Attaques brute force** : Détection des tentatives multiples de confirmation avec tokens invalides

### Fonctionnalités

- ✅ Détection email scanner (auto-click)
- ✅ Détection brute force (tentatives multiples)
- ✅ Logging sécurisé des alertes
- ✅ Intégration Sentry (alertes automatiques)
- ✅ Activation uniquement en production/staging

---

## 🏗️ Service : `EmailSecurityService`

**Fichier** : `app/services/email_security_service.rb`

### Méthodes Publiques

#### 1. Détection Email Scanner

```ruby
def detect_email_scanner(user, ip, time_since_sent)
  # Détecte si un email a été cliqué < 10 secondes après l'envoi
end
```

**Paramètres** :
- `user` : Utilisateur concerné (objet User)
- `ip` : Adresse IP de la requête
- `time_since_sent` : Temps écoulé depuis l'envoi de l'email (ActiveSupport::Duration)

**Logique** :
- Vérifie que le service est activé (`enabled?`)
- Construit un hash d'alerte avec les métadonnées
- Log l'alerte dans les logs Rails
- Envoie une alerte Sentry (si configuré)

**Severité** : `medium`

#### 2. Détection Brute Force

```ruby
def detect_brute_force(ip, failure_count)
  # Détecte les tentatives multiples de confirmation avec tokens invalides
end
```

**Paramètres** :
- `ip` : Adresse IP de la requête
- `failure_count` : Nombre d'échecs consécutifs

**Logique** :
- Vérifie que le service est activé (`enabled?`)
- Construit un hash d'alerte avec les métadonnées
- Log l'alerte dans les logs Rails
- Envoie une alerte Sentry (si configuré)

**Severité** : `high`

---

## 🔍 Détails Techniques

### Structure des Alertes

#### Email Scanner

```ruby
{
  type: "email_scanner_detected",
  user_id: 123,
  user_email: "user@example.com",
  ip: "192.168.1.1",
  time_since_sent: 5,  # secondes
  timestamp: 2025-01-30T10:30:00Z,
  severity: "medium"
}
```

#### Brute Force

```ruby
{
  type: "confirmation_brute_force",
  ip: "192.168.1.1",
  failure_count: 10,
  timestamp: 2025-01-30T10:30:00Z,
  severity: "high"
}
```

### Méthodes Privées

#### `enabled?`

```ruby
def enabled?
  Rails.env.production? || Rails.env.staging?
end
```

**Comportement** :
- Activé uniquement en production et staging
- Désactivé en développement (pas de fausses alertes lors des tests)

#### `sentry_enabled?`

```ruby
def sentry_enabled?
  defined?(Sentry) && Sentry.configuration.dsn.present?
end
```

**Comportement** :
- Vérifie si Sentry est configuré
- Vérifie que le DSN est présent

#### `log_security_alert(alert_data)`

```ruby
def log_security_alert(alert_data)
  Rails.logger.error(
    "🔒 SECURITY ALERT: #{alert_data[:type]} - " \
    "IP: #{alert_data[:ip]}, " \
    "Severity: #{alert_data[:severity]}, " \
    "Details: #{alert_data.except(:ip, :severity).to_json}"
  )
end
```

**Logging** :
- Niveau : `error` (visible dans les logs)
- Format : Préfixe `🔒 SECURITY ALERT:` pour faciliter la recherche
- Contenu : Type, IP, sévérité, détails (JSON)

#### `send_sentry_alert(alert_data)`

```ruby
def send_sentry_alert(alert_data)
  Sentry.capture_message(
    "Security Alert: #{alert_data[:type]}",
    level: alert_data[:severity] == "high" ? :error : :warning,
    extra: alert_data,
    tags: {
      security_alert: true,
      alert_type: alert_data[:type],
      severity: alert_data[:severity]
    }
  )
end
```

**Sentry** :
- Level : `error` pour high severity, `warning` pour medium
- Extra : Toutes les métadonnées de l'alerte
- Tags : Tags personnalisés pour faciliter le filtrage

---

## 🔗 Intégration avec ConfirmationsController

### Utilisation

**Fichier** : `app/controllers/confirmations_controller.rb`

#### Détection Email Scanner

```ruby
# Dans ConfirmationsController#show (après confirmation réussie)
time_since_sent = Time.current - user.confirmation_sent_at

if time_since_sent < 10.seconds
  EmailSecurityService.detect_email_scanner(user, request.remote_ip, time_since_sent)
end
```

**Condition** : Si le temps entre l'envoi et le clic < 10 secondes

**Raison** : Un email scanner (antivirus, filtre spam) clique automatiquement sur tous les liens, généralement très rapidement après réception.

#### Détection Brute Force

```ruby
# Dans ConfirmationsController#show (après échec de confirmation)
failure_count = Rails.cache.fetch("confirmation_failures:#{ip}", expires_in: 1.hour) { 0 }
failure_count += 1
Rails.cache.write("confirmation_failures:#{ip}", failure_count, expires_in: 1.hour)

if failure_count >= 5
  EmailSecurityService.detect_brute_force(ip, failure_count)
end
```

**Condition** : Si >= 5 échecs consécutifs depuis la même IP en 1 heure

**Stockage** : Utilise Rails.cache avec clé `confirmation_failures:#{ip}` et expiration 1h

**Raison** : Détecte les tentatives d'attaque brute force sur les tokens de confirmation.

---

## 🎯 Cas d'Usage

### Cas 1 : Email Scanner Détecté

**Scénario** :
1. Email de confirmation envoyé à 10:00:00
2. Lien cliqué à 10:00:05 (< 10 secondes)
3. `EmailSecurityService.detect_email_scanner` appelé

**Résultat** :
- Alerte loggée (niveau error)
- Alerte Sentry envoyée (severity: medium)
- Pas de blocage (comportement normal pour certains utilisateurs)

### Cas 2 : Brute Force Détecté

**Scénario** :
1. Tentative confirmation token invalide #1 depuis IP 192.168.1.1
2. Tentative confirmation token invalide #2 depuis même IP
3. ... (5+ tentatives)
4. `EmailSecurityService.detect_brute_force` appelé

**Résultat** :
- Alerte loggée (niveau error)
- Alerte Sentry envoyée (severity: high)
- Recommandation : Blocage temporaire de l'IP (non implémenté actuellement)

---

## 🔐 Sécurité

### Activation Conditionnelle

**Environnements** :
- ✅ Production : Activé
- ✅ Staging : Activé
- ❌ Development : Désactivé (évite fausses alertes)
- ❌ Test : Désactivé

### Données Sensibles

**Logging** :
- Email utilisateur : Loggé (nécessaire pour investigation)
- IP : Loggée (nécessaire pour identification)
- User ID : Loggé (nécessaire pour traçabilité)

**Recommandation** : Vérifier la conformité RGPD si logs conservés longtemps.

### Intégration Sentry

**Avantages** :
- Alertes en temps réel
- Filtrage et recherche facilités
- Tags personnalisés pour analyse
- Métriques et dashboards

**Configuration** :
- Nécessite Sentry configuré avec DSN valide
- Vérification automatique avant envoi

---

## 📊 Monitoring

### Logs Rails

**Format** :
```
🔒 SECURITY ALERT: email_scanner_detected - IP: 192.168.1.1, Severity: medium, Details: {"type":"email_scanner_detected","user_id":123,"user_email":"user@example.com","time_since_sent":5,"timestamp":"2025-01-30T10:30:00Z"}
```

**Recherche** :
```bash
# Dans les logs
grep "SECURITY ALERT" log/production.log

# Par type
grep "email_scanner_detected" log/production.log
grep "confirmation_brute_force" log/production.log
```

### Sentry

**Dashboards** :
- Filtrer par tag `security_alert: true`
- Filtrer par `alert_type`
- Filtrer par `severity`

**Alertes** :
- Configuration possible d'alertes Sentry basées sur la sévérité
- Notifications email/Slack si configuré

---

## 🔄 Améliorations Futures Possibles

### 1. Blocage Automatique

**Idée** : Bloquer temporairement les IPs suspectes

```ruby
# Exemple (non implémenté)
if failure_count >= 10
  Rails.cache.write("blocked_ip:#{ip}", true, expires_in: 1.hour)
end
```

**Middleware** : Vérifier avant chaque requête si IP bloquée

### 2. Rate Limiting

**Idée** : Intégration avec `rack-attack` pour rate limiting

```ruby
# Exemple (non implémenté)
Rack::Attack.throttle("confirmations/#{ip}", limit: 5, period: 1.hour) do |req|
  req.ip if req.path.start_with?("/users/confirmation")
end
```

### 3. Analyse Temporelle

**Idée** : Analyser les patterns temporels

- Heures de la journée
- Jours de la semaine
- Patterns géographiques (si géolocalisation IP disponible)

### 4. Dashboard Admin

**Idée** : Interface admin pour visualiser les alertes

- Liste des alertes récentes
- Statistiques par type
- Graphiques temporels
- Actions manuelles (blocage IP, etc.)

---

## 🔗 Références

- **Service** : `app/services/email_security_service.rb`
- **Contrôleur** : `app/controllers/confirmations_controller.rb`
- **Documentation email confirmation** : [`docs/04-rails/setup/email-confirmation.md`](setup/email-confirmation.md)
- **Sentry** : [Documentation Sentry Ruby](https://docs.sentry.io/platforms/ruby/)

---

## 📝 Notes

### Faux Positifs

**Email Scanner** :
- Certains utilisateurs peuvent cliquer très rapidement (< 10s)
- Certains clients email ouvrent les liens en arrière-plan
- **Recommandation** : Analyser les patterns plutôt que bloquer systématiquement

**Brute Force** :
- Utilisateurs avec mauvaise connexion peuvent générer plusieurs requêtes
- Partage de lien peut générer plusieurs clics
- **Recommandation** : Seuil à ajuster selon le trafic réel

### Conformité RGPD

**Logs** :
- Conserver uniquement le nécessaire
- Anonymiser après période de rétention
- Documenter dans la politique de confidentialité

---

**Version** : 1.0  
**Dernière mise à jour** : 2025-01-30


