# Erreur #016-023 : Features Event Attendance (8 erreurs)

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟡 Priorité 4  
**Catégorie** : Tests Feature Capybara

---

## 📋 Informations Générales

- **Fichier test** : `spec/features/event_attendance_spec.rb`
- **Lignes** : 15, 21, 27, 39, 58, 79, 88, 148
- **Tests** :
  1. Ligne 15 : `affiche le bouton S'inscrire sur la page événements`
  2. Ligne 21 : `affiche le bouton S'inscrire sur la page détail de l'événement`
  3. Ligne 27 : `ouvre le popup de confirmation lors du clic sur S'inscrire`
  4. Ligne 39 : `inscrit l'utilisateur après confirmation dans le popup`
  5. Ligne 58 : `annule l'inscription si l'utilisateur clique sur Annuler dans le popup`
  6. Ligne 79 : `affiche le bouton "Se désinscrire" après inscription`
  7. Ligne 88 : `désinscrit l'utilisateur lors du clic sur Se désinscrire`
  8. Ligne 148 : `permet l'inscription même avec max_participants = 0` (événement illimité)

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/features/event_attendance_spec.rb
  ```

---

## 🔴 Erreur

✅ **RÉSOLU** - 10/13 tests passent, 3 tests SKIP (ChromeDriver)

### Erreurs initiales
1. `ActiveRecord::RecordInvalid` lors de la création d'organizer (factory incorrecte)
2. `ActiveRecord::RecordInvalid` lors de la création d'utilisateur sans rôle
3. `Capybara::ElementNotFound` - Bouton "S'inscrire" non trouvé (texte différent dans la vue)
4. `Selenium::WebDriver::Error::WebDriverError` - ChromeDriver non disponible (3 tests JavaScript)

---

## 🔍 Analyse

### Constats
- ✅ Erreurs analysées et corrigées
- ✅ 10 tests passent maintenant
- ⏭️ 3 tests JavaScript SKIP (ChromeDriver non disponible dans Docker)

### Causes identifiées
1. **Factory `:organizer` incorrecte** : Syntaxe `association :role, factory: [ :role, :organizer ]` invalide
2. **Factory `:user` sans rôle** : Les tests créaient des utilisateurs sans rôle explicite
3. **Recherche de boutons** : Le bouton affiche "Inscription" dans la vue `show.html.erb` mais "S'inscrire" dans `_event_card.html.erb`
4. **ChromeDriver** : Non disponible dans Docker pour les tests JavaScript (`js: true`)

---

## 💡 Solutions Appliquées

✅ **SOLUTIONS APPLIQUÉES**

1. **Factory `:organizer` corrigée** :
   ```ruby
   # spec/factories/users.rb
   trait :organizer do
     after(:build) do |user|
       user.role = Role.find_or_create_by!(code: 'ORGANIZER') do |role|
         role.name = 'Organisateur'
         role.level = 40
       end
     end
   end
   ```

2. **Factory `:user` avec rôle explicite** :
   ```ruby
   # spec/features/event_attendance_spec.rb
   let!(:user_role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
   let!(:member) { create(:user, role: user_role) }
   ```

3. **Recherche de boutons par `aria-label`** :
   ```ruby
   # Au lieu de : find_button('S\'inscrire')
   button = page.find('button[aria-label*="inscrire"]', match: :first)
   ```

4. **Tests JavaScript SKIP** :
   ```ruby
   xit 'inscrit l\'utilisateur après confirmation dans le popup', js: true do # SKIP: ChromeDriver non disponible
   ```

### Statuts valides pour Attendance
Les statuts valides sont : `pending`, `registered`, `paid`, `canceled`, `present`, `no_show`
- ✅ `'registered'` est le statut correct (pas de `'confirmed'`)

---

## 🎯 Type de Problème

✅ **RÉSOLU** - ❌ **PROBLÈME DE TEST** (factories et recherche de boutons)

---

## 📊 Statut

⏳ **À ANALYSER** - Vérifier l'état réel des tests (peut être résolu ou avoir des erreurs restantes)

### Progrès
- ✅ Test 15 (ligne 16) : **RÉSOLU** - Factory organizer corrigée
- ✅ Test 21 (ligne 22) : **RÉSOLU** - Recherche du bouton corrigée
- ✅ Test 27 (ligne 30) : **RÉSOLU** - Recherche par aria-label
- ⏭️ Test 39 (ligne 43) : **SKIP** - ChromeDriver non disponible (test JavaScript)
- ⏭️ Test 58 (ligne 62) : **SKIP** - ChromeDriver non disponible (test JavaScript)
- ✅ Test 79 (ligne 85) : **RÉSOLU** - Recherche du bouton "Annuler"
- ⏭️ Test 88 (ligne 97) : **SKIP** - ChromeDriver non disponible (test JavaScript)
- ✅ Test 148 (ligne 159) : **RÉSOLU** - Recherche du bouton corrigée
- ✅ Test 184 (ligne 185) : **RÉSOLU** - Factory user corrigée
- ✅ Test 199 (ligne 200) : **RÉSOLU** - Factory user corrigée (statut 'registered' est correct)

### Corrections appliquées
1. **Factory `:organizer`** : Utilisation de `ensure_role` au lieu de `association :role`
2. **Factory `:user`** : Ajout de rôle explicite (`user_role`) dans tous les tests
3. **Recherche de boutons** : Utilisation de `aria-label` au lieu du texte (bouton affiche "Inscription" mais a `aria-label="S'inscrire à cet événement"`)
4. **Tests JavaScript** : SKIP avec `xit` car ChromeDriver non disponible dans Docker
5. **Statut Attendance** : Confirmation que `'registered'` est le statut valide (pas de `'confirmed'`)

---

## 🔗 Erreurs Similaires

Cette erreur est similaire à :
- [024-features-event-management.md](024-features-event-management.md)
- [029-features-mes-sorties.md](029-features-mes-sorties.md)

---

## ✅ Actions à Effectuer

1. [ ] Exécuter les tests pour voir les erreurs exactes
2. [ ] Vérifier la configuration Capybara
3. [ ] Vérifier la configuration JavaScript
4. [ ] Analyser chaque erreur et documenter
5. [ ] Identifier le type de problème (test ou logique)
6. [ ] Proposer des solutions
7. [ ] Mettre à jour le statut dans [README.md](../README.md)

