# Configuration des tâches cron avec Supercronic

## Vue d'ensemble

Les tâches cron sont gérées par [Supercronic](https://github.com/aptible/supercronic), un outil conçu pour les conteneurs Docker. Supercronic est préféré à cron traditionnel car :
- Il ne nécessite pas de processus init
- Il gère mieux les logs
- Il est plus simple à configurer dans Docker

## Configuration

### Fichiers

- **`config/schedule.rb`** : Définition des tâches avec Whenever (pour référence)
- **`config/crontab`** : Fichier crontab utilisé par Supercronic (généré depuis schedule.rb)

### Installation

Supercronic est installé automatiquement dans le Dockerfile :
- Téléchargement depuis GitHub releases
- Installation dans `/usr/local/bin/supercronic`
- Support des architectures x86_64 et ARM64

### Démarrage

Supercronic est lancé automatiquement par `bin/docker-entrypoint` en production et staging :
- Vérifie la présence de `/rails/config/crontab`
- Lance Supercronic en arrière-plan
- Les logs des tâches sont écrits dans `log/cron.log`

## Tâches configurées

1. **Sync HelloAsso payments** : Toutes les 5 minutes
2. **Rappels événements** : Tous les jours à 19h
3. **Mise à jour adhésions expirées** : Tous les jours à minuit
4. **Rappels renouvellement** : Tous les jours à 9h
5. **Vérification autorisations parentales** : Tous les lundis à 10h
6. **Vérification certificats médicaux** : Tous les lundis à 10h30

## Vérification

### Vérifier que Supercronic est actif

```bash
# Dans le conteneur
docker exec -it grenoble-roller-production ps aux | grep supercronic
```

### Voir les logs des tâches cron

```bash
# Dans le conteneur
docker exec -it grenoble-roller-production tail -f log/cron.log
```

### Vérifier les logs de Supercronic

Les logs de Supercronic lui-même sont dans les logs du conteneur (stdout/stderr).

## Modification des tâches

Le fichier `config/crontab` est généré automatiquement lors du déploiement par le script `ops/lib/deployment/cron.sh` :

1. Modifier `config/schedule.rb` pour ajouter/modifier les tâches
2. Le script de déploiement génère automatiquement `config/crontab` depuis `schedule.rb` avec `whenever --set`
3. Le fichier est écrit dans `/rails/config/crontab` dans le conteneur
4. Supercronic lit automatiquement ce fichier au démarrage

**Note** : Le script n'utilise pas `whenever --update-crontab` car cela nécessiterait la commande `crontab` qui n'est pas disponible dans les conteneurs Docker. À la place, le contenu généré est écrit directement dans le fichier `/rails/config/crontab` que Supercronic lit.

## Notes

- Les tâches utilisent `RAILS_ENV` de l'environnement Docker
- Les logs sont redirigés vers `log/cron.log`
- Supercronic continue de fonctionner même si une tâche échoue

