# Analyse Complète : Système de Mailing Automatique et Tâches CRON

**Date** : 2025-01-13  
**Objectif** : Analyser pourquoi les emails automatiques (7h et 19h) ne s'envoient pas

---

## Vue d'ensemble

Les tâches cron sont gérées par [Supercronic](https://github.com/aptible/supercronic), un outil conçu pour les conteneurs Docker. Supercronic est préféré à cron traditionnel car :
- Il ne nécessite pas de processus init
- Il gère mieux les logs
- Il est plus simple à configurer dans Docker

---

## 🚨 PROBLÈME PRINCIPAL IDENTIFIÉ

### Supercronic ne tourne pas actuellement

**Statut** : 🚨 **CRITIQUE** - Toutes les tâches cron sont inactives

**Impact** :
- ❌ EventReminderJob (19h) ne s'exécute pas → Pas d'emails de rappel la veille
- ❌ InitiationParticipantsReportJob (7h) ne s'exécute pas → Pas de rapports matinaux
- ❌ HelloAsso sync (toutes les 5 min) ne s'exécute pas → Paiements non synchronisés
- ❌ Tâches memberships (expirées, renouvellements) ne s'exécutent pas

**Cause probable** : Supercronic n'est pas démarré ou les conditions de démarrage ne sont pas remplies

---

## 📋 Configuration et Architecture

### Fichiers de Configuration

1. **`config/schedule.rb`** : Définition source des tâches avec Whenever
   - Format lisible (syntaxe Ruby/Whenever)
   - Source de vérité pour toutes les tâches cron

2. **`config/crontab`** : Fichier crontab généré utilisé par Supercronic
   - Généré automatiquement depuis `schedule.rb` par `ops/lib/deployment/cron.sh`
   - Format crontab standard (minute hour day month weekday command)
   - Lu par Supercronic au démarrage

### Installation

Supercronic est installé automatiquement dans le Dockerfile :
- Téléchargement depuis GitHub releases (v0.2.32)
- Installation dans `/usr/local/bin/supercronic`
- Support des architectures x86_64 et ARM64

**Fichier** : `Dockerfile` (lignes 30-31)

### Démarrage

Supercronic devrait être lancé automatiquement par `bin/docker-entrypoint` en production et staging :

**Fichier** : `bin/docker-entrypoint` (lignes 67-82)

```bash
# Lancer Supercronic en arrière-plan pour les tâches cron en production/staging
if [ "${RAILS_ENV}" == "production" ] || [ "${APP_ENV}" == "staging" ] || 
   [ "${DEPLOY_ENV}" == "staging" ] || [ "${DEPLOY_ENV}" == "production" ]; then
  if [ -f "/rails/config/crontab" ]; then
    echo "Starting Supercronic for cron jobs..."
    mkdir -p /rails/log
    touch /rails/log/cron.log 2>/dev/null || true
    supercronic /rails/config/crontab &
    SUPERICRONIC_PID=$!
    echo "Supercronic started in background (PID: $SUPERICRONIC_PID)"
  else
    echo "Warning: /rails/config/crontab not found, skipping cron jobs"
  fi
fi
```

**Conditions de démarrage** :
1. Variable d'environnement doit être `RAILS_ENV=production` OU `APP_ENV=staging` OU `DEPLOY_ENV=staging|production`
2. Le fichier `/rails/config/crontab` doit exister

**Configuration Staging** :

✅ **Staging est bien configuré** pour que Supercronic démarre :

- **Variables d'environnement** (`ops/staging/docker-compose.yml` lignes 21-23) :
  ```yaml
  RAILS_ENV: production
  APP_ENV: staging          # ← Condition 1 remplie
  DEPLOY_ENV: staging       # ← Condition 2 remplie
  ```

- **Génération du crontab** : Le script `ops/deploy.sh` détecte automatiquement l'environnement (staging/production) et définit `ENV="staging"` ou `ENV="production"`. Le crontab est généré avec `whenever --set 'environment=${env}'` lors du déploiement.

**Conclusion** : Staging devrait avoir Supercronic qui démarre automatiquement, à condition que :
1. ✅ Les variables d'environnement sont définies (OK dans docker-compose.yml)
2. ⚠️ Le crontab a été généré lors du dernier déploiement (à vérifier)

---

**Configuration Production** :

✅ **Production est bien configuré** pour que Supercronic démarre :

- **Variables d'environnement** (`ops/production/docker-compose.yml` lignes 55-57) :
  ```yaml
  RAILS_ENV: production     # ← Condition remplie pour docker-entrypoint
  APP_ENV: production
  DEPLOY_ENV: production    # ← Condition remplie pour docker-entrypoint
  ```

- **Génération du crontab** : Le script `ops/deploy.sh` détecte automatiquement l'environnement et définit `ENV="production"`. Le crontab est généré avec `whenever --set 'environment=production'` lors du déploiement.

**Conditions de démarrage dans docker-entrypoint** :
- `RAILS_ENV == "production"` ✅ (rempli)
- OU `DEPLOY_ENV == "production"` ✅ (rempli)
- Les deux conditions sont remplies pour production, donc Supercronic devrait démarrer.

**Conclusion** : Production devrait avoir Supercronic qui démarre automatiquement, à condition que :
1. ✅ Les variables d'environnement sont définies (OK dans docker-compose.yml)
2. ⚠️ Le crontab a été généré lors du dernier déploiement (à vérifier)

---

**Configuration Development** :

❌ **Development n'est PAS configuré** pour que Supercronic démarre automatiquement :

- **Variables d'environnement** (`ops/dev/docker-compose.yml` ligne 20) :
  ```yaml
  RAILS_ENV: development    # ← Condition NON remplie
  # Pas de APP_ENV
  # Pas de DEPLOY_ENV
  ```

- **Condition dans docker-entrypoint** :
  ```bash
  if [ "${RAILS_ENV}" == "production" ] || [ "${APP_ENV}" == "staging" ] || 
     [ "${DEPLOY_ENV}" == "staging" ] || [ "${DEPLOY_ENV}" == "production" ]; then
  ```
  - `RAILS_ENV == "production"` ❌ (RAILS_ENV=development)
  - `APP_ENV == "staging"` ❌ (non défini)
  - `DEPLOY_ENV == "staging"` ❌ (non défini)
  - `DEPLOY_ENV == "production"` ❌ (non défini)
  
  **Aucune condition n'est remplie**, donc Supercronic **ne démarre PAS** en développement.

**Pourquoi ?** C'est normal : les tâches cron (emails automatiques, synchronisations, etc.) ne doivent pas tourner en développement pour éviter d'envoyer des emails réels ou de modifier des données de production.

**Pour tester les jobs en dev** :
- Exécuter manuellement : `bin/rails runner "EventReminderJob.perform_now"`
- Pour InitiationParticipantsReportJob : `FORCE_INITIATION_REPORT=true bin/rails runner "InitiationParticipantsReportJob.perform_now"`

**Si on veut activer Supercronic en dev** (déconseillé) :
1. Ajouter `APP_ENV: staging` ou `DEPLOY_ENV: staging` dans `ops/dev/docker-compose.yml`
2. Générer le crontab manuellement : `bundle exec whenever --set 'environment=development' > config/crontab`
3. ⚠️ **Attention** : Les jobs s'exécuteront vraiment, risque d'envoyer des emails réels !

---

## 📧 Tâches de Mailing Configurées

### 1. EventReminderJob - Rappels événements à 19h

**Configuration source** : `config/schedule.rb` (lignes 12-15)

```ruby
# Job de rappel la veille à 19h pour les événements du lendemain
every 1.day, at: "7:00 pm" do
  runner "EventReminderJob.perform_now"
end
```

**Crontab généré** : `config/crontab` (ligne 10)

```
0 19 * * * /bin/bash -l -c 'cd /rails && bundle exec bin/rails runner -e "${RAILS_ENV:-production}" '\''EventReminderJob.perform_now'\'' >> log/cron.log 2>&1'
```

**Fichier job** : `app/jobs/event_reminder_job.rb`

**Fonction** :
- S'exécute tous les jours à **19h00**
- Trouve tous les événements publiés qui ont lieu **demain** (entre 00:00 et 23:59:59)
- Pour chaque événement, trouve les attendances actives avec `wants_reminder: true` et `reminder_sent_at: nil`
- Envoie un email de rappel (`EventMailer.event_reminder`) via `deliver_later`
- Met à jour `reminder_sent_at` pour éviter les doublons

**Logique de filtrage** :
- Événements : `.published`, `.upcoming`, `start_at` demain
- Attendances : `.active` (exclut `canceled` mais inclut `no_show`), `wants_reminder: true`, `reminder_sent_at: nil`
- Pour initiations : vérifie aussi `user.wants_initiation_mail?`

**Flag de suivi** : `reminder_sent_at` (datetime) dans table `attendances`
- Migration : `db/migrate/20251220042130_add_reminder_sent_at_to_attendances.rb`
- Utilisé pour éviter les doublons si le job s'exécute plusieurs fois

**Mailer** : `EventMailer.event_reminder(attendance)`
- Templates : `app/views/event_mailer/event_reminder.html.erb` et `.text.erb`
- Sujet : `📅 Rappel : [Titre] demain !` ou `📅 Rappel : Initiation roller demain samedi [Date]`

---

### 2. InitiationParticipantsReportJob - Rapport participants à 7h

**Configuration source** : `config/schedule.rb` (lignes 17-22)

```ruby
# Rapport participants initiation (tous les jours à 7h, uniquement en production)
# Note: La vérification de l'environnement se fait dans le job lui-même
every 1.day, at: "7:00 am" do
  runner 'InitiationParticipantsReportJob.perform_now'
end
```

**Crontab généré** : ⚠️ **MANQUANT dans `config/crontab`**

**Problème identifié** : Le job est défini dans `schedule.rb` mais **n'apparaît pas dans le crontab généré**. Cela signifie que même si Supercronic tourne, ce job ne s'exécutera pas.

**Fichier job** : `app/jobs/initiation_participants_report_job.rb`

**Fonction** :
- S'exécute tous les jours à **07h00**
- **Uniquement en production** (vérifié dans le job avec `Rails.env.production?`)
- Trouve toutes les initiations du jour (aujourd'hui entre 00:00 et 23:59:59) avec `participants_report_sent_at: nil`
- Envoie un email de rapport (`EventMailer.initiation_participants_report`) à `contact@grenoble-roller.org`
- Met à jour `participants_report_sent_at` pour éviter les doublons

**Flag de suivi** : `participants_report_sent_at` (datetime) dans table `events`
- Migration : `db/migrate/20251220062313_add_participants_report_sent_at_to_events.rb`
- Utilisé pour éviter les doublons si le job s'exécute plusieurs fois le même jour

**Mailer** : `EventMailer.initiation_participants_report(initiation)`
- Templates : `app/views/event_mailer/initiation_participants_report.html.erb` et `.text.erb`
- Sujet : `📋 Rapport participants - Initiation [Date]`
- Destinataire : `contact@grenoble-roller.org` (hardcodé)

**Données incluses** :
- Liste des participants actifs (nom, email, type adulte/enfant)
- Participants avec matériel demandé (pointure)
- Résumé du matériel par pointure

---

### 3. Autres Tâches Cron (non-mailing)

1. **HelloAsso Sync** : Toutes les 5 minutes (`config/crontab` ligne 7)
2. **Memberships Expired** : Tous les jours à minuit (`config/crontab` ligne 13)
3. **Renewal Reminders** : Tous les jours à 9h (`config/crontab` ligne 16)
4. **Check Minor Authorizations** : Tous les lundis à 10h (`config/crontab` ligne 19)
5. **Check Medical Certificates** : Tous les lundis à 10h30 (`config/crontab` ligne 22)

---

## 🔍 Diagnostic : Pourquoi les emails ne s'envoient pas

### Problème 1 : Supercronic ne tourne pas

**Symptômes** :
- Aucun processus Supercronic visible dans le conteneur
- Aucune entrée dans `log/cron.log`
- Les jobs ne s'exécutent jamais

**Causes possibles** :

1. **Variables d'environnement non définies** :
   - Le script vérifie `RAILS_ENV`, `APP_ENV`, ou `DEPLOY_ENV`
   - Si aucune de ces variables n'est définie à `production` ou `staging`, Supercronic ne démarre pas

2. **Fichier crontab absent** :
   - Si `/rails/config/crontab` n'existe pas, Supercronic ne démarre pas
   - Le fichier est généré par `ops/lib/deployment/cron.sh` lors du déploiement

3. **Supercronic non dans le PATH** :
   - Peu probable car installé dans `/usr/local/bin/supercronic` (dans PATH par défaut)

**Vérifications à faire** :

```bash
# 1. Vérifier si Supercronic tourne
docker exec -it grenoble-roller-production ps aux | grep supercronic
# Si aucun résultat → Supercronic ne tourne pas

# 2. Vérifier si le crontab existe
docker exec -it grenoble-roller-production ls -la /rails/config/crontab
# Si fichier n'existe pas → Problème de génération

# 3. Vérifier les variables d'environnement
docker exec -it grenoble-roller-production env | grep -E "RAILS_ENV|APP_ENV|DEPLOY_ENV"
# Vérifier que les variables sont définies correctement

# 4. Vérifier les logs du conteneur au démarrage
docker logs grenoble-roller-production | grep -i supercronic
# Chercher "Starting Supercronic" ou "Warning: /rails/config/crontab not found"
```

---

### Problème 2 : InitiationParticipantsReportJob manquant dans crontab

**Symptôme** : Le job est défini dans `config/schedule.rb` (ligne 20-22) mais n'apparaît pas dans `config/crontab` généré.

**Cause possible** : 
- Problème lors de la génération du crontab par `ops/lib/deployment/cron.sh`
- La condition `if Rails.env.production?` dans le schedule.rb pourrait poser problème (mais elle est commentée comme étant gérée dans le job)

**Vérification** :

```bash
# Vérifier le contenu du crontab généré
docker exec -it grenoble-roller-production cat /rails/config/crontab | grep -i initiation
# Si aucun résultat → Le job n'est pas dans le crontab

# Vérifier ce que whenever génère
docker exec -it grenoble-roller-production bundle exec whenever --set 'environment=production' | grep -i initiation
# Si résultat présent → Le problème est dans la génération/écriture du crontab
```

**Solution** :
1. Vérifier pourquoi `whenever` ne génère pas cette ligne
2. Regénérer le crontab manuellement si nécessaire
3. Vérifier que le script `ops/lib/deployment/cron.sh` écrit bien toutes les lignes générées

---

### Problème 3 : Logique de filtrage trop restrictive (hypothèse)

**Pour EventReminderJob** :
- Le job filtre par `reminder_sent_at: nil` : si un rappel a déjà été envoyé, il ne sera plus envoyé
- Si `wants_reminder: false`, aucun rappel ne sera envoyé
- Pour initiations : si `user.wants_initiation_mail?` est false, aucun rappel ne sera envoyé

**Vérifications** :

```bash
# Tester manuellement le job
docker exec -it grenoble-roller-production bin/rails runner "EventReminderJob.perform_now"

# Vérifier les attendances éligibles
docker exec -it grenoble-roller-production bin/rails runner "
  tomorrow = Time.zone.now.beginning_of_day + 1.day
  events = Event.published.upcoming.where(start_at: tomorrow.beginning_of_day..tomorrow.end_of_day)
  puts \"Events demain: #{events.count}\"
  events.each do |event|
    attendances = event.attendances.active.where(wants_reminder: true).where(reminder_sent_at: nil)
    puts \"  #{event.title}: #{attendances.count} attendances avec rappel demandé\"
  end
"
```

---

## 🔧 Solutions et Actions Requises

### Action 1 : Diagnostiquer pourquoi Supercronic ne démarre pas (URGENT)

**Pour Production** :
```bash
docker logs grenoble-roller-production 2>&1 | grep -i -A 5 -B 5 supercronic
docker exec grenoble-roller-production env | grep -E "RAILS_ENV|APP_ENV|DEPLOY_ENV"
docker exec grenoble-roller-production ls -la /rails/config/crontab
docker exec -d grenoble-roller-production supercronic /rails/config/crontab
docker exec grenoble-roller-production ps aux | grep supercronic
```

**Pour Staging** (remplacer `production` par le nom du conteneur staging) :
```bash
# Identifier le conteneur staging
docker ps | grep staging

# Vérifier les logs
docker logs <container-staging> 2>&1 | grep -i -A 5 -B 5 supercronic

# Vérifier les variables d'environnement
docker exec <container-staging> env | grep -E "RAILS_ENV|APP_ENV|DEPLOY_ENV"
# Devrait afficher : APP_ENV=staging, DEPLOY_ENV=staging, RAILS_ENV=production

# Vérifier l'existence du crontab
docker exec <container-staging> ls -la /rails/config/crontab

# Tester le démarrage manuel
docker exec -d <container-staging> supercronic /rails/config/crontab
docker exec <container-staging> ps aux | grep supercronic
```

### Action 2 : Corriger le crontab manquant (InitiationParticipantsReportJob)

1. **Vérifier ce que whenever génère** :
   ```bash
   docker exec -it grenoble-roller-production bash -c "cd /rails && bundle exec whenever --set 'environment=production'"
   ```

2. **Regénérer le crontab manuellement si nécessaire** :
   ```bash
   docker exec -it grenoble-roller-production bash -c "cd /rails && bundle exec whenever --set 'environment=production' > /rails/config/crontab"
   ```

3. **Vérifier que le script de déploiement fonctionne** :
   - Relancer le script `ops/lib/deployment/cron.sh` lors du prochain déploiement
   - Vérifier les logs de déploiement

### Action 3 : Tester manuellement les jobs

Une fois Supercronic démarré, tester manuellement pour valider la logique :

```bash
# Tester EventReminderJob
docker exec -it grenoble-roller-production bin/rails runner "EventReminderJob.perform_now"

# Tester InitiationParticipantsReportJob (forcer en dev pour test)
docker exec -it grenoble-roller-production bash -c "FORCE_INITIATION_REPORT=true bin/rails runner 'InitiationParticipantsReportJob.perform_now'"
```

### Action 4 : Vérifier les logs

```bash
# Logs des tâches cron
docker exec -it grenoble-roller-production tail -f log/cron.log

# Logs de l'application (pour voir les erreurs éventuelles)
docker logs -f grenoble-roller-production
```

---

## 📊 Résumé des Tâches Configurées

| Tâche | Horaire | Fichier Source | Crontab Généré | Statut |
|-------|---------|----------------|----------------|--------|
| HelloAsso Sync | Toutes les 5 min | `schedule.rb` ligne 8 | ✅ Ligne 7 | ❌ Inactif (Supercronic) |
| EventReminderJob | 19h00 quotidien | `schedule.rb` ligne 13 | ✅ Ligne 10 | ❌ Inactif (Supercronic) |
| InitiationParticipantsReportJob | 07h00 quotidien | `schedule.rb` ligne 20 | ⚠️ **MANQUANT** | ❌ Non configuré + Supercronic |
| Memberships Expired | 00h00 quotidien | `schedule.rb` ligne 25 | ✅ Ligne 13 | ❌ Inactif (Supercronic) |
| Renewal Reminders | 09h00 quotidien | `schedule.rb` ligne 30 | ✅ Ligne 16 | ❌ Inactif (Supercronic) |
| Check Minor Auth | Lundi 10h00 | `schedule.rb` ligne 35 | ✅ Ligne 19 | ❌ Inactif (Supercronic) |
| Check Medical Cert | Lundi 10h30 | `schedule.rb` ligne 40 | ✅ Ligne 22 | ❌ Inactif (Supercronic) |

---

## 🔄 Génération du Crontab

Le fichier `config/crontab` est généré automatiquement lors du déploiement par le script `ops/lib/deployment/cron.sh` :

1. Le script exécute `whenever --set 'environment=production'` dans le conteneur
2. Le contenu généré est écrit dans `/rails/config/crontab`
3. Supercronic lit ce fichier au démarrage

**Script** : `ops/lib/deployment/cron.sh` (fonction `install_crontab()`)

**Note** : Le script n'utilise pas `whenever --update-crontab` car cela nécessiterait la commande `crontab` qui n'est pas disponible dans les conteneurs Docker. À la place, le contenu généré est écrit directement dans le fichier `/rails/config/crontab` que Supercronic lit.

---

## 📝 Notes Importantes

- Les tâches utilisent `RAILS_ENV` de l'environnement Docker (ou `${RAILS_ENV:-production}` si non défini)
- Les logs des tâches sont redirigés vers `log/cron.log`
- Supercronic continue de fonctionner même si une tâche échoue
- Les jobs utilisent `deliver_later` pour traitement asynchrone via SolidQueue
- Les flags de suivi (`reminder_sent_at`, `participants_report_sent_at`) évitent les doublons

---

## 📚 Références

- Documentation complète mailing : `docs/development/Mailing/mailing-system-complete.md`
- EventReminderJob : `app/jobs/event_reminder_job.rb`
- InitiationParticipantsReportJob : `app/jobs/initiation_participants_report_job.rb`
- Docker entrypoint : `bin/docker-entrypoint`
- Script déploiement cron : `ops/lib/deployment/cron.sh`
- Schedule source : `config/schedule.rb`
- Crontab généré : `config/crontab`

---

## 🔍 Diagnostic 503 - Service Unavailable / Subdomain not configured

### Commandes de Diagnostic Rapide

**1. Vérifier l'état des conteneurs** :
```bash
docker ps -a | grep grenoble-roller-production
```

**2. Vérifier le statut de santé du conteneur web** :
```bash
docker inspect grenoble-roller-production --format='{{.State.Health.Status}}'
# Doit retourner : "healthy"
```

**3. Tester le endpoint /up directement dans le conteneur** :
```bash
docker exec grenoble-roller-production curl -f http://localhost:3000/up
# Doit retourner : 200 OK
```

**4. Vérifier les logs du conteneur web** :
```bash
docker logs --tail 50 grenoble-roller-production
```

**5. Vérifier les logs de Caddy (reverse proxy)** :
```bash
docker logs --tail 50 grenoble-roller-caddy-production
```

### Problème Courant : "This subdomain is not configured"

**Cause** : Le domaine/sous-domaine utilisé dans l'URL ne correspond pas à la configuration Caddy.

**Configuration Caddy** (`ops/production/Caddyfile` ligne 17) :
- ✅ Configure uniquement : `grenoble-roller.org` et `www.grenoble-roller.org`
- ❌ Tout autre sous-domaine (ex: `staging.grenoble-roller.org`, `api.grenoble-roller.org`) retournera 503

**Solution** :
1. Utiliser `grenoble-roller.org` ou `www.grenoble-roller.org`
2. OU ajouter le sous-domaine dans le Caddyfile si nécessaire

### Vérifications Complètes

**État de santé détaillé** :
```bash
docker inspect grenoble-roller-production --format='{{json .State.Health}}' | jq
```

**Test de connexion réseau Docker** :
```bash
docker exec grenoble-roller-caddy-production curl -I http://web:3000/up
```

**Vérifier les variables d'environnement** :
```bash
docker exec grenoble-roller-production env | grep -E "RAILS_ENV|APP_ENV|MAILER_HOST|VIRTUAL_HOST"
```

**Redémarrer les conteneurs si nécessaire** :
```bash
cd /chemin/vers/projet
docker compose -f ops/production/docker-compose.yml restart
```

---

## 🔧 Configuration HAProxy pour Health Check

### Problème : HAProxy voit le backend comme DOWN

**Symptôme** : Dans l'interface HAProxy, le backend montre :
- Status: **DOWN**
- LastChk: **L4CON in 0ms** (erreur de connexion TCP)

### Causes possibles

1. **Le conteneur n'est pas démarré** :
   ```bash
   # Vérifier l'état du conteneur
   docker ps -a | grep grenoble-roller-dev
   # Si "Exited", démarrer le conteneur :
   docker compose -f ops/dev/docker-compose.yml up -d
   ```

2. **Configuration HTTP check incorrecte dans HAProxy**

### Configuration HAProxy recommandée

**Endpoint de health check** : `/up`

**Configuration HTTP check dans HAProxy/pfSense** :

```
Http check method: GET
Url used by http check requests: /up
Http check version: HTTP/1.0
```

**Alternative (si GET ne fonctionne pas)** :
```
Http check method: OPTIONS
Url used by http check requests: /up
Http check version: HTTP/1.0
```

### Vérification que l'application répond

**1. Démarrer le conteneur** :
```bash
docker compose -f ops/dev/docker-compose.yml up -d
```

**2. Vérifier que le conteneur est UP** :
```bash
docker ps | grep grenoble-roller-dev
# Doit montrer "Up X minutes"
```

**3. Tester le endpoint /up** :
```bash
# Depuis l'hôte (si port 3000 exposé)
curl -I http://localhost:3000/up
# Doit retourner : HTTP/1.1 200 OK

# Depuis le conteneur (test interne)
docker exec grenoble-roller-dev curl -I http://localhost:3000/up
# Doit retourner : HTTP/1.1 200 OK
```

**4. Tester depuis HAProxy/pfSense** :
```bash
# Tester depuis le serveur HAProxy vers l'IP du conteneur
curl -I http://<IP_CONTENEUR>:3000/up
```

### Configuration HAProxy complète (exemple)

**Backend server configuration** :
- Address: IP du serveur où tourne le conteneur
- Port: 3000 (port exposé dans docker-compose.yml)
- Health check: HTTP
- HTTP check method: GET
- HTTP check URL: /up
- HTTP check version: HTTP/1.0

**Notes importantes** :
- Le endpoint `/up` est standard Rails et retourne 200 si l'app démarre sans erreur
- Le endpoint est exclu du mode maintenance (voir `lib/middleware/maintenance_middleware.rb`)
- Si HAProxy retourne L4CON, c'est une erreur de connexion TCP (conteneur arrêté ou port fermé)

### Résumé : Configuration HAProxy recommandée

```
Backend Server:
  - Address: IP du serveur où tourne le conteneur
  - Port: 3000

Health Check:
  - Type: HTTP
  - Method: GET (si ça ne marche pas, essayer OPTIONS)
  - URL: /up
  - Version: HTTP/1.0
```

### Vérification rapide

```bash
# 1. Vérifier que le conteneur est UP
docker ps | grep grenoble-roller-dev

# 2. Vérifier que le port 3000 est exposé
# Doit montrer : 0.0.0.0:3000->3000/tcp

# 3. Tester depuis l'hôte
curl -I http://localhost:3000/up
# Doit retourner : HTTP/1.1 200 OK

# 4. Si HAProxy est sur un autre serveur, tester depuis HAProxy
curl -I http://<IP_SERVEUR>:3000/up
# Doit retourner : HTTP/1.1 200 OK
```

---

## ⚠️ Port 59691 (ou autre port étrange) dans l'URL

### D'où vient ce port ?

Le port **59691** (ou tout autre port > 30000) n'est **PAS configuré** dans le projet. Il provient probablement d'un **port forwarding automatique** créé par :

1. **Cursor Remote / VS Code Remote** : Port forwarding automatique quand vous travaillez en remote
2. **SSH Tunnel** : Un tunnel SSH avec forwarding automatique
3. **Docker Desktop Port Forwarding** : Port forwarding automatique de Docker Desktop

### Configuration Production Réelle

**Dans `ops/production/docker-compose.yml`** :
- ❌ Le conteneur `web` **n'expose AUCUN port** sur l'hôte (ligne 68-70 : seulement `expose: - "3000"` qui est interne au réseau Docker)
- ✅ Caddy expose les ports **80** et **443** sur l'hôte (lignes 16-20)

### Comment accéder à l'application en Production

**Méthode correcte** :
1. ✅ Via Caddy (reverse proxy) : `http://grenoble-roller.org` ou `https://grenoble-roller.org` (port 80/443)
2. ✅ Directement via localhost : `http://localhost:3000` (port exposé, si vous êtes sur le serveur)
3. ✅ Localement via localhost : `http://localhost:80` (via Caddy, si vous êtes sur le serveur)

**❌ NE PAS utiliser** :
- `http://localhost:59691` → Port forwarding automatique, instable

### Si vous avez besoin d'accéder directement au conteneur web

**Option 1 : Créer un port forwarding manuel** :
```bash
# Forward le port 3000 du conteneur vers 3000 sur l'hôte (temporaire)
docker port grenoble-roller-production 3000

# OU créer un forwarding SSH si vous êtes en remote
ssh -L 3000:localhost:3000 user@server
```

**Option 2 : Accéder via docker exec** (pour les commandes) :
```bash
docker exec grenoble-roller-production curl http://localhost:3000/up
```

**Option 3 : Modifier temporairement docker-compose.yml** (⚠️ déconseillé en prod) :
```yaml
ports:
  - "3000:3000"  # ⚠️ Ne PAS faire en production normale
```

### Pour désactiver le port forwarding automatique

Si vous utilisez **Cursor Remote** ou **VS Code Remote** :
1. Ouvrir la palette de commandes (Cmd/Ctrl + Shift + P)
2. Chercher "Forwarded Ports" ou "Ports"
3. Fermer/supprimer le port 59691 (ou celui qui apparaît)

