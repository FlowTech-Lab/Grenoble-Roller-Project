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

