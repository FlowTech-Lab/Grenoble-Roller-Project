# Refactoring : Partage de code entre Events et Initiations

## Problème identifié

Les vues `events/show.html.erb` et `initiations/show.html.erb` contenaient beaucoup de code dupliqué pour :
- Les boutons d'action (Calendrier, Modifier, Supprimer)
- La section de rappel (toggle reminder)
- Le modal de suppression
- La structure des actions

## Solution implémentée

### 1. Helper polymorphique (`app/helpers/events_helper.rb`)

Création d'un helper avec des méthodes qui détectent automatiquement le type d'événement (Event ou Event::Initiation) et génèrent les bonnes routes :

```ruby
def event_path_for(event)
  event.is_a?(Event::Initiation) ? initiation_path(event) : event_path(event)
end

def ical_event_path_for(event)
  event.is_a?(Event::Initiation) ? ical_initiation_path(event, format: :ics) : ical_event_path(event, format: :ics)
end
# ... etc
```

**Avantages :**
- ✅ Code DRY (Don't Repeat Yourself)
- ✅ Détection automatique du type
- ✅ Facile à maintenir et étendre

### 2. Partials partagés (`app/views/shared/`)

#### `_event_actions.html.erb`
Partial qui contient tous les boutons d'action communs :
- Section rappel (toggle)
- Bouton Calendrier (.ics)
- Bouton retour à la liste
- Boutons Modifier / Supprimer (si autorisé)

**Utilisation :**
```erb
<%= render 'shared/event_actions', 
    event: @event, 
    user_attendance: @user_attendance, 
    child_attendances: @child_attendances %>
```

#### `_event_delete_modal.html.erb`
Modal de confirmation de suppression partagé.

**Utilisation :**
```erb
<%= render 'shared/event_delete_modal', event: @event %>
```

## Meilleures pratiques appliquées

### ✅ 1. DRY (Don't Repeat Yourself)
- Code commun extrait dans des partials réutilisables
- Helpers pour éviter la duplication de logique de routage

### ✅ 2. Polymorphisme via helpers
- Pas de polymorphisme au niveau des modèles (trop complexe pour ce cas)
- Polymorphisme au niveau des vues via des helpers intelligents
- Détection du type avec `is_a?` pour router correctement

### ✅ 3. Séparation des responsabilités
- **Helpers** : Logique de routage et génération d'URLs
- **Partials** : Présentation et structure HTML
- **Vues principales** : Orchestration et logique spécifique

### ✅ 4. Maintenabilité
- Un seul endroit pour modifier les boutons communs
- Ajout facile de nouveaux types d'événements
- Tests plus simples (un seul partial à tester)

## Structure des fichiers

```
app/
├── helpers/
│   └── events_helper.rb          # Helpers polymorphiques
└── views/
    ├── shared/
    │   ├── _event_actions.html.erb      # Boutons d'action communs
    │   └── _event_delete_modal.html.erb # Modal de suppression
    ├── events/
    │   └── show.html.erb                # Utilise les partials
    └── initiations/
        └── show.html.erb                 # Utilise les partials
```

## Avantages de cette approche

1. **Cohérence** : Les deux types d'événements ont exactement les mêmes boutons et comportements
2. **Maintenance** : Un seul endroit à modifier pour changer les boutons
3. **Extensibilité** : Facile d'ajouter un nouveau type d'événement (ex: Event::Workshop)
4. **Testabilité** : Les partials peuvent être testés indépendamment

## Alternatives considérées

### ❌ Polymorphisme au niveau des modèles
- Trop complexe pour ce cas d'usage
- Nécessiterait une refonte importante de la structure
- Pas nécessaire car les deux types partagent déjà Event comme parent

### ❌ Concern objects
- Over-engineering pour ce cas simple
- Les helpers suffisent pour la logique de routage

### ✅ Solution retenue : Helpers + Partials
- Simple et efficace
- Respecte les conventions Rails
- Facile à comprendre et maintenir

## Prochaines étapes possibles

1. **Tester les partials** : Ajouter des tests pour vérifier le rendu
2. **Documenter les variables** : Ajouter des commentaires sur les variables attendues
3. **Étendre aux autres vues** : Appliquer le même principe aux vues index si nécessaire
4. **Ajouter d'autres types** : Si un nouveau type d'événement est créé, il suffit d'ajouter les routes dans le helper

