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

1. Modifier `config/schedule.rb` si vous utilisez Whenever
2. Mettre à jour `config/crontab` manuellement avec le format crontab
3. Rebuilder l'image Docker
4. Redémarrer le conteneur

## Notes

- Les tâches utilisent `RAILS_ENV` de l'environnement Docker
- Les logs sont redirigés vers `log/cron.log`
- Supercronic continue de fonctionner même si une tâche échoue

