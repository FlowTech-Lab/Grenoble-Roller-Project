# Erreur #024 : Features Event Management - Redirection membre simple

**Date d'analyse** : 2025-12-15  
**Priorité** : 🟡 Priorité 4  
**Catégorie** : Tests Feature Capybara

---

## 📋 Informations Générales

- **Fichier test** : `spec/features/event_management_spec.rb`
- **Ligne** : 97
- **Test** : `redirige vers la page d'accueil si accès direct à new_event_path`
- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/features/event_management_spec.rb:97
  ```

---

## 🔴 Erreur

```
Failure/Error: expect(page).to have_current_path(root_path)
  expected "/events/new" to equal "/"
```

---

## 🔍 Analyse

### Constats
- ❌ Le test attend une redirection vers `root_path` (`/`) mais reste sur `/events/new`
- ✅ Le test est dans le contexte d'un membre simple (pas organisateur)
- ✅ `EventPolicy#new?` appelle `create?` qui retourne `organizer?` (niveau >= 40)
- ✅ Un membre simple (niveau 10) ne devrait pas pouvoir créer d'événement
- ⚠️ Le `rescue_from Pundit::NotAuthorizedError` dans `ApplicationController` devrait rediriger vers `root_path`

### Cause Probable

Le contrôleur `EventsController#new` appelle `authorize @event` qui lève `Pundit::NotAuthorizedError` pour un membre simple, mais la redirection ne se fait pas correctement. Il faut vérifier :
1. Si `authorize` est bien appelé dans `new`
2. Si le `rescue_from` dans `ApplicationController` gère correctement cette erreur
3. Si la politique `EventPolicy#new?` retourne bien `false` pour un membre simple

### Code Actuel

```ruby
# spec/features/event_management_spec.rb ligne 97-99
it 'redirige vers la page d\'accueil si accès direct à new_event_path' do
  visit new_event_path
  expect(page).to have_current_path(root_path)
end

# app/controllers/events_controller.rb
def new
  @event = Event.new(creator_user: current_user)
  authorize @event
  # ...
end

# app/policies/event_policy.rb
def new?
  create?
end

def create?
  organizer?
end

def organizer?
  user.present? && user.role&.level.to_i >= 40
end

# app/controllers/application_controller.rb
rescue_from Pundit::NotAuthorizedError do |exception|
  if user_signed_in?
    user_not_authorized(exception)
  else
    if request.path.include?('/initiations/') || request.path.include?('/events/')
      redirect_to root_path, alert: "Cette ressource n'est pas accessible."
    else
      redirect_to new_user_session_path, alert: "Vous devez être connecté pour accéder à cette page."
    end
  end
end
```

---

## 💡 Solutions Proposées

### Solution 1 : Corriger `user_not_authorized` pour rediriger vers `root_path` pour les événements

**Problème** : `user_not_authorized` redirige vers `request.referer || root_path`, donc si `request.referer` est présent, il redirige vers le referer au lieu de `root_path`.

**Solution** : Modifier `user_not_authorized` pour rediriger vers `root_path` pour les routes d'événements.

```ruby
# app/controllers/application_controller.rb
def user_not_authorized(_exception)
  if api_request?
    render json: {
      error: "Non autorisé",
      message: "Vous n'êtes pas autorisé·e à effectuer cette action."
    }, status: :forbidden
  else
    # Pour les routes d'événements, toujours rediriger vers root_path
    if request.path.include?('/events/') || request.path.include?('/initiations/')
      redirect_to root_path, alert: "Vous n'êtes pas autorisé·e à effectuer cette action."
    else
      redirect_to(request.referer || root_path, alert: "Vous n'êtes pas autorisé·e à effectuer cette action.")
    end
  end
end
```

### Solution 2 : Ajouter une vérification explicite dans `EventsController#new`

**Problème** : La redirection peut ne pas se faire correctement via `rescue_from`.

**Solution** : Ajouter une vérification explicite avant `authorize`.

```ruby
# app/controllers/events_controller.rb
def new
  @event = Event.new(creator_user: current_user)
  
  unless policy(@event).new?
    redirect_to root_path, alert: "Vous n'êtes pas autorisé à créer un événement."
    return
  end
  
  authorize @event
  # ...
end
```

### Solution 3 : Vérifier que le test utilise le bon utilisateur

**Problème** : Le test peut ne pas utiliser un membre simple.

**Solution** : Vérifier que le test crée bien un membre simple (niveau 10) et non un organisateur.

```ruby
context 'quand l\'utilisateur est un simple membre' do
  let!(:user_role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let!(:member) { create(:user, role: user_role) }
  
  before do
    login_as member
  end
  
  it 'redirige vers la page d\'accueil si accès direct à new_event_path' do
    visit new_event_path
    expect(page).to have_current_path(root_path)
  end
end
```

---

## 🎯 Type de Problème

⚠️ **PROBLÈME DE LOGIQUE** :
- La redirection dans `ApplicationController` ne fonctionne pas correctement pour les utilisateurs connectés
- La méthode `user_not_authorized` peut ne pas rediriger vers `root_path`

---

## 📊 Statut

✅ **RÉSOLU** - Solution appliquée : vérification explicite dans `EventsController#new` avant `authorize`

---

## 🔗 Erreurs Similaires

Cette erreur est similaire aux erreurs suivantes :
- [016-features-event-attendance.md](016-features-event-attendance.md) - Problèmes similaires avec les redirections Pundit

---

## 📝 Notes

- Le test est dans le contexte d'un membre simple (pas organisateur)
- La politique `EventPolicy#new?` devrait retourner `false` pour un membre simple
- Le `rescue_from` devrait gérer cette erreur et rediriger vers `root_path`

---

## ✅ Actions à Effectuer

1. [x] Vérifier la méthode `user_not_authorized` dans `ApplicationController`
2. [x] Modifier `user_not_authorized` pour rediriger vers `root_path` pour les routes d'événements
3. [x] Ajouter une vérification explicite dans `EventsController#new` avant `authorize`
4. [x] Exécuter le test pour vérifier qu'il passe
5. [x] Mettre à jour le statut dans [README.md](../README.md)

## ✅ Solution Appliquée

**Modification dans `app/controllers/events_controller.rb`** :
```ruby
def new
  @event = current_user.created_events.build(...)
  
  # Vérifier explicitement les permissions avant authorize pour rediriger correctement
  unless policy(@event).new?
    redirect_to root_path, alert: "Vous n'êtes pas autorisé à créer un événement."
    return
  end
  
  authorize @event
end
```

**Modification dans `app/controllers/application_controller.rb`** :
```ruby
def user_not_authorized(_exception)
  if api_request?
    # ... code API ...
  else
    # Pour les routes d'événements, toujours rediriger vers root_path
    if request.path.include?('/events/') || request.path.include?('/initiations/')
      redirect_to root_path, alert: "Vous n'êtes pas autorisé·e à effectuer cette action."
    else
      redirect_to(request.referer || root_path, alert: "Vous n'êtes pas autorisé·e à effectuer cette action.")
    end
  end
end
```
