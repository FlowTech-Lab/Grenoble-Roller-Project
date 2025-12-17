# Comparatif des Formulaires d'Adhésion : Enfant vs Adulte

**Date :** 2025-01-XX  
**Fichiers comparés :**
- `app/views/memberships/child_form.html.erb`
- `app/views/memberships/adult_form.html.erb`

---

## 📊 Résumé Exécutif

### Différences attendues (normales)
- ✅ Champs spécifiques enfants vs adultes
- ✅ Validation d'âge différente (< 6 ans bloqué vs < 16 ans bloqué)
- ✅ Section autorisation parentale pour enfants < 16 ans
- ✅ Section coordonnées pour adultes uniquement
- ✅ Textes adaptés ("votre enfant" vs "vous")

### ⚠️ Différences problématiques (incohérences)
- ❌ **Validation téléphone** : logique différente entre les deux formulaires
- ❌ **Gestion des questions de santé** : `checkHealthQuestions()` appelée différemment
- ❌ **Validation formulaire** : logique de validation de date de naissance différente
- ❌ **Boutons submit** : styles et textes incohérents
- ❌ **Gestion des erreurs** : affichage des messages d'erreur non uniformisé
- ❌ **Champs cachés** : ordre et structure différents

---

## 🔍 Analyse Détaillée

### 1. STRUCTURE GÉNÉRALE

#### Hero Section
| Aspect | Child Form | Adult Form | Cohérence |
|--------|-----------|------------|-----------|
| Titre dynamique | ✅ Oui (réadhésion supportée) | ❌ Non (titre fixe) | ⚠️ **INCOHÉRENT** |
| Badges saison | ✅ Identique | ✅ Identique | ✅ OK |
| Progress bar | ✅ Identique | ✅ Identique | ✅ OK |

**Problème identifié :**
- Le formulaire enfant gère la réadhésion (`@old_membership`) mais pas le formulaire adulte
- **Impact :** Les adultes ne peuvent pas renouveler leur adhésion avec pré-remplissage

---

### 2. FORMULAIRE (form_with)

#### ID du formulaire
| Child Form | Adult Form | Cohérence |
|-----------|------------|-----------|
| `id: "child_membership_form"` | `id: "adult_membership_form"` | ✅ OK (différence attendue) |

#### Champs cachés
| Child Form | Adult Form | Cohérence |
|-----------|------------|-----------|
| `is_child_membership: true` | `type: "adult"` | ⚠️ **INCOHÉRENT** |
| `with_tshirt: false` | `with_tshirt: false` | ✅ OK |
| `payment_method: "helloasso"` | `payment_method: "helloasso"` | ✅ OK |

**Problème identifié :**
- Le formulaire enfant utilise `is_child_membership: true`
- Le formulaire adulte utilise `type: "adult"`
- **Impact :** Logique backend potentiellement différente, risque de bugs

---

### 3. ÉTAPE 1 : CATÉGORIE

#### Structure HTML
| Aspect | Child Form | Adult Form | Cohérence |
|--------|-----------|------------|-----------|
| Titre section | "Choisissez l'adhésion" | "Choisissez votre adhésion" | ✅ OK (différence attendue) |
| Intro | "Sélectionnez la formule qui correspond à votre enfant" | "Sélectionnez la formule qui vous correspond" | ✅ OK |
| Sélection par défaut | `key == :standard && @membership.nil?` | `key == :standard` | ⚠️ **INCOHÉRENT** |

**Problème identifié :**
- Child form : vérifie `@membership.nil?` en plus
- Adult form : sélectionne toujours `:standard` par défaut
- **Impact :** Comportement différent lors du chargement initial

---

### 4. ÉTAPE 2 : INFORMATIONS

#### Champs présents
| Child Form | Adult Form | Cohérence |
|-----------|------------|-----------|
| `child_first_name` | `first_name` | ✅ OK (différence attendue) |
| `child_last_name` | `last_name` | ✅ OK (différence attendue) |
| ❌ Pas d'email | ✅ `email` (readonly) | ✅ OK (différence attendue) |
| ❌ Pas de téléphone | ✅ `phone` (avec masque) | ✅ OK (différence attendue) |
| `child_date_of_birth` | `date_of_birth` | ✅ OK (différence attendue) |

#### Date de naissance - Années disponibles
| Child Form | Adult Form | Cohérence |
|-----------|------------|-----------|
| `Date.today.year.downto(Date.today.year - 18)` | `Date.today.year.downto(Date.today.year - 120)` | ✅ OK (différence attendue) |

#### Date de naissance - Validation JavaScript
| Child Form | Adult Form | Cohérence |
|-----------|------------|-----------|
| Fonction : `updateChildDateOfBirth()` | Fonction : `updateAdultDateOfBirth()` | ✅ OK (différence attendue) |
| Fonction : `checkChildAge()` | Fonction : `updateAdultAge()` | ⚠️ **INCOHÉRENT** (nommage) |
| Validation : < 6 ans bloqué | Validation : < 16 ans bloqué | ✅ OK (différence attendue) |

**Problème identifié :**
- Noms de fonctions différents (`checkChildAge` vs `updateAdultAge`)
- **Impact :** Code moins maintenable, risque de confusion

#### Date de naissance - Messages d'erreur
| Child Form | Adult Form | Cohérence |
|-----------|------------|-----------|
| Message < 6 ans : "L'adhésion n'est pas possible pour les enfants de moins de 6 ans." | Message < 16 ans : "L'adhésion adulte n'est pas possible pour les personnes de moins de 16 ans. Veuillez contacter un membre du bureau de l'association." | ✅ OK (différence attendue) |
| Affichage âge : `child_age_display` | Affichage âge : `adult_age_display` | ✅ OK (différence attendue) |
| Inférence catégorie : Oui (ENFANT/ADOLESCENT) | Inférence catégorie : Non | ⚠️ **INCOHÉRENT** |

**Problème identifié :**
- Le formulaire enfant affiche une inférence de catégorie automatique
- Le formulaire adulte ne le fait pas
- **Impact :** Expérience utilisateur incohérente

---

### 5. ÉTAPE 3 : SECTION SPÉCIFIQUE

#### Child Form : Autorisation parentale
- Section affichée si âge < 16 ans
- Signature digitale avec nom parent + nom enfant
- Prix affiché dynamiquement

#### Adult Form : Coordonnées
- Adresse, ville, code postal, pays
- Champ adresse avec autocomplétion

**Cohérence :** ✅ OK (différence attendue, sections différentes)

---

### 6. QUESTIONNAIRE DE SANTÉ

#### Textes
| Child Form | Adult Form | Cohérence |
|-----------|------------|-----------|
| "concernant la santé de votre enfant" | "concernant votre santé" | ✅ OK (différence attendue) |

#### Messages Standard avec réponse OUI
| Child Form | Adult Form | Cohérence |
|-----------|------------|-----------|
| "Conseil avant la pratique" | "Consultez votre médecin avant de pratiquer" | ⚠️ **INCOHÉRENT** |
| "Nous vous recommandons fortement de consulter votre médecin avant la pratique le roller." | "Vous avez indiqué avoir des problèmes de santé. Nous vous recommandons fortement de consulter votre médecin avant de pratiquer le roller." | ⚠️ **INCOHÉRENT** |

**Problème identifié :**
- Formulations différentes pour le même cas d'usage
- **Impact :** Expérience utilisateur incohérente

#### Logique JavaScript
| Child Form | Adult Form | Cohérence |
|-----------|------------|-----------|
| `checkHealthQuestions()` appelée dans `updateCategorySelection()` | `checkHealthQuestions()` appelée dans `updateCategorySelection()` | ✅ OK |
| `checkHealthQuestions()` appelée dans `checkChildAge()` | ❌ Pas d'appel dans `updateAdultAge()` | ⚠️ **INCOHÉRENT** |

**Problème identifié :**
- Le formulaire enfant vérifie les questions de santé quand l'âge change
- Le formulaire adulte ne le fait pas
- **Impact :** Comportement différent lors du changement de date de naissance

---

### 7. CONSENTEMENTS

#### RGPD
| Child Form | Adult Form | Cohérence |
|-----------|------------|-----------|
| "J'autorise Grenoble Roller à collecter les données **de l'enfant** pour l'adhésion" | "J'autorise Grenoble Roller à collecter **mes données** pour l'adhésion" | ✅ OK (différence attendue) |

#### Communication
- Identique dans les deux formulaires ✅

#### FFRS
- Identique dans les deux formulaires ✅

---

### 8. VALIDATION JAVASCRIPT

#### Fonction `validateField()`

**Validation téléphone :**
| Child Form | Adult Form | Cohérence |
|-----------|------------|-----------|
| ❌ Pas de validation téléphone (pas de champ) | ✅ Validation téléphone présente | ✅ OK (différence attendue) |
| Message d'erreur : "Le numéro de téléphone doit contenir exactement 10 chiffres (ex: 0612345678)" | Message d'erreur : "Le numéro de téléphone doit contenir exactement 10 chiffres (ex: 06 12 34 56 78)" | ⚠️ **INCOHÉRENT** (format affiché différent) |

**Problème identifié :**
- Format d'exemple différent (avec/sans espaces)
- **Impact :** Confusion utilisateur potentielle

**Validation code postal :**
| Child Form | Adult Form | Cohérence |
|-----------|------------|-----------|
| ❌ Pas de validation code postal | ✅ Validation code postal présente | ✅ OK (différence attendue) |

#### Fonction `validateForm()`

**Validation date de naissance :**
| Child Form | Adult Form | Cohérence |
|-----------|------------|-----------|
| Vérifie jour/mois/année individuellement | Vérifie jour/mois/année individuellement | ✅ OK |
| Vérifie âge minimum (< 6 ans) | Vérifie âge minimum (< 16 ans) | ✅ OK (différence attendue) |
| Vérifie autorisation parentale si nécessaire | ❌ Pas de vérification équivalente | ✅ OK (différence attendue) |

**Validation questionnaire santé :**
- Identique dans les deux formulaires ✅

**Validation certificat médical :**
- Identique dans les deux formulaires ✅

---

### 9. BOUTONS DE SOUMISSION

#### Bouton principal
| Child Form | Adult Form | Cohérence |
|-----------|------------|-----------|
| Texte : "Ajouter l'enfant" | Texte : "Valider et payer" | ⚠️ **INCOHÉRENT** |
| Classe : `btn-liquid-warning` | Classe : `btn-liquid-primary` | ⚠️ **INCOHÉRENT** |
| ID : `submit_btn` | ID : `submit_btn` | ✅ OK |

**Problème identifié :**
- Textes et styles différents pour la même action
- **Impact :** Expérience utilisateur incohérente

#### Bouton secondaire
- Identique dans les deux formulaires ✅ ("Déjà adhérent / Espèces / Chèques")

#### Gestion des erreurs dans onclick
- Identique dans les deux formulaires ✅

---

### 10. SCRIPTS JAVASCRIPT

#### Initialisation DOMContentLoaded

**Appels de fonctions :**
| Child Form | Adult Form | Cohérence |
|-----------|------------|-----------|
| `updateCategorySelection()` | `updateCategorySelection()` | ✅ OK |
| `checkChildAge()` | `updateAdultAge()` | ✅ OK (différence attendue) |
| `checkHealthQuestions()` | `checkHealthQuestions()` | ✅ OK |
| `checkAllConsents()` | `checkAllConsents()` | ✅ OK |
| `validateForm()` | `validateForm()` | ✅ OK |

**Gestion drag & drop certificat :**
- Identique dans les deux formulaires ✅

**Écouteurs d'événements :**
- Identique dans les deux formulaires ✅

#### Gestion T-shirt
- Identique dans les deux formulaires ✅ (conditionnelle `@with_tshirt`)

#### Validation avant soumission

**Child Form :**
```javascript
// Retirer le required des champs cachés pour éviter l'erreur "not focusable"
const authSection = document.getElementById('parent_authorization_section');
const authCheckbox = document.getElementById('parent_authorization');
if (authSection && authSection.style.display === 'none' && authCheckbox) {
  authCheckbox.removeAttribute('required');
}

const certificateUpload = document.getElementById('health_certificate_upload');
const certificateInput = document.getElementById('medical_certificate_input');
if (certificateUpload && certificateUpload.style.display === 'none' && certificateInput) {
  certificateInput.removeAttribute('required');
}
```

**Adult Form :**
```javascript
// Vérifier l'âge avant soumission
const day = document.getElementById('date_of_birth_day')?.value;
const month = document.getElementById('date_of_birth_month')?.value;
const year = document.getElementById('date_of_birth_year')?.value;

if (day && month && year) {
  // Calcul âge et blocage < 16 ans
  // ...
}
```

**Problème identifié :**
- Logique de validation avant soumission différente
- Child form : retire les `required` des champs cachés
- Adult form : vérifie l'âge avant soumission
- **Impact :** Comportement différent, risque de bugs

---

## 🚨 PROBLÈMES CRITIQUES IDENTIFIÉS

### 1. Champs cachés incohérents
- **Child :** `is_child_membership: true`
- **Adult :** `type: "adult"`
- **Action :** Unifier la logique backend

### 2. Validation téléphone - Format d'exemple différent
- **Child :** "0612345678" (sans espaces)
- **Adult :** "06 12 34 56 78" (avec espaces)
- **Action :** Uniformiser le format d'exemple

### 3. Messages questionnaire santé incohérents
- **Child :** "Conseil avant la pratique"
- **Adult :** "Consultez votre médecin avant de pratiquer"
- **Action :** Harmoniser les messages

### 4. Boutons submit incohérents
- **Child :** "Ajouter l'enfant" (warning)
- **Adult :** "Valider et payer" (primary)
- **Action :** Harmoniser les textes et styles

### 5. Validation avant soumission différente
- **Child :** Retire les `required` des champs cachés
- **Adult :** Vérifie l'âge avant soumission
- **Action :** Unifier la logique de validation

### 6. Inférence catégorie manquante (adulte)
- **Child :** Affiche inférence catégorie automatique
- **Adult :** Ne l'affiche pas
- **Action :** Ajouter inférence catégorie pour adultes ou la retirer des enfants

### 7. Réadhésion non supportée (adulte)
- **Child :** Gère `@old_membership` et réadhésion
- **Adult :** Ne gère pas la réadhésion
- **Action :** Ajouter support réadhésion pour adultes

### 8. Sélection catégorie par défaut différente
- **Child :** `key == :standard && @membership.nil?`
- **Adult :** `key == :standard`
- **Action :** Unifier la logique de sélection par défaut

### 9. Appel `checkHealthQuestions()` manquant (adulte)
- **Child :** Appelée dans `checkChildAge()`
- **Adult :** Pas d'appel dans `updateAdultAge()`
- **Action :** Ajouter l'appel dans `updateAdultAge()` ou le retirer de `checkChildAge()`

---

## ✅ RECOMMANDATIONS

### Priorité HAUTE
1. **Unifier les champs cachés** : Utiliser la même logique (`is_child_membership` vs `type`)
2. **Harmoniser les messages** : Questionnaire santé, validation téléphone
3. **Unifier la validation avant soumission** : Même logique dans les deux formulaires

### Priorité MOYENNE
4. **Harmoniser les boutons submit** : Même style et texte cohérent
5. **Ajouter support réadhésion adulte** : Gérer `@old_membership` comme pour enfants
6. **Unifier sélection catégorie par défaut** : Même logique dans les deux formulaires

### Priorité BASSE
7. **Harmoniser inférence catégorie** : Ajouter pour adultes ou retirer pour enfants
8. **Unifier appels JavaScript** : Même logique d'appel des fonctions de validation

---

## 📝 CHECKLIST DE CORRECTION

### Backend
- [ ] Vérifier logique `is_child_membership` vs `type` dans le contrôleur
- [ ] Unifier la gestion des champs cachés
- [ ] Ajouter support réadhésion pour adultes

### Frontend - Child Form
- [ ] Harmoniser messages questionnaire santé
- [ ] Harmoniser format exemple téléphone (si ajouté)
- [ ] Harmoniser bouton submit

### Frontend - Adult Form
- [ ] Ajouter support réadhésion (`@old_membership`)
- [ ] Ajouter inférence catégorie (ou retirer de child)
- [ ] Ajouter appel `checkHealthQuestions()` dans `updateAdultAge()`
- [ ] Harmoniser messages questionnaire santé
- [ ] Harmoniser bouton submit
- [ ] Unifier sélection catégorie par défaut

### JavaScript
- [ ] Unifier logique validation avant soumission
- [ ] Harmoniser format exemple téléphone
- [ ] Unifier appels fonctions de validation

---

## 🔄 RENOUVELLEMENT D'ADHÉSION : IMPLÉMENTATION POUR ADULTES

### 📋 État Actuel

#### Pour les ENFANTS (✅ Implémenté)

**1. Dans la vue `index.html.erb` (section Historique) :**
```erb
<!-- Ligne 334-337 -->
<% if membership.is_child_membership? %>
  <%= link_to new_membership_path(type: 'child', renew_from: membership.id), class: "btn btn-sm btn-success" do %>
    <i class="bi bi-arrow-repeat me-1"></i>Réadhérer
  <% end %>
<% end %>
```

**2. Dans la vue `_membership_card.html.erb` :**
```erb
<!-- Ligne 99-102 -->
<% if membership.is_child_membership? %>
  <%= link_to new_membership_path(type: 'child', renew_from: membership.id), class: "btn btn-sm btn-success" do %>
    <i class="bi bi-arrow-repeat me-1"></i>Réadhérer
  <% end %>
<% end %>
```

**3. Dans le contrôleur `memberships_controller.rb` :**
```ruby
# Lignes 40-57
if type == "child" && params[:renew_from].present?
  old_membership = current_user.memberships.find_by(id: params[:renew_from])
  if old_membership && old_membership.is_child_membership? && old_membership.expired?
    @old_membership = old_membership
    @membership = Membership.new(
      is_child_membership: true,
      child_first_name: old_membership.child_first_name,
      child_last_name: old_membership.child_last_name,
      child_date_of_birth: old_membership.child_date_of_birth,
      category: old_membership.category,
      with_tshirt: false,
      tshirt_size: nil,
      tshirt_qty: 0
    )
  end
end
```

**4. Dans le formulaire `child_form.html.erb` :**
```erb
<!-- Lignes 15-19 : Titre dynamique -->
<% if @old_membership %>
  RÉADHÉSION DE <%= @old_membership.child_full_name.upcase %>
<% else %>
  INSCRIPTION DE VOTRE ENFANT
<% end %>

<!-- Lignes 111-116 : Message d'information -->
<% if @old_membership %>
  <div class="alert alert-info mb-4">
    <i class="bi bi-info-circle me-2"></i>
    <strong>Renouvellement d'adhésion</strong> : Les informations de <%= @old_membership.child_full_name %> ont été pré-remplies.
    Vous pouvez les modifier si nécessaire.
  </div>
<% end %>

<!-- Lignes 1251-1275 : Initialisation JavaScript -->
<% if @old_membership %>
  // Pré-remplir le nom de l'enfant dans l'autorisation parentale
  // Initialiser la date de naissance si elle est pré-remplie
  // Sélectionner la catégorie si elle était pré-remplie
<% end %>
```

#### Pour les ADULTES (❌ Non implémenté)

**1. Dans la vue `index.html.erb` (section Historique) :**
```erb
<!-- Ligne 338-341 : Actuellement -->
<% else %>
  <%= link_to new_membership_path(check_age: true), class: "btn btn-sm btn-success" do %>
    <i class="bi bi-arrow-repeat me-1"></i>Renouveler
  <% end %>
<% end %>
```

**Problème :** Le lien ne passe pas le paramètre `renew_from`, donc aucune pré-remplissage n'est effectué.

**2. Dans la vue `_membership_card.html.erb` :**
```erb
<!-- Ligne 104-106 : Actuellement -->
<% else %>
  <%= link_to new_membership_path(type: 'adult'), class: "btn btn-sm btn-success" do %>
    <i class="bi bi-arrow-repeat me-1"></i>Renouveler
  <% end %>
<% end %>
```

**Problème :** Même problème, pas de paramètre `renew_from`.

**3. Dans le contrôleur :** Aucune gestion du paramètre `renew_from` pour les adultes.

**4. Dans le formulaire `adult_form.html.erb` :** Aucune gestion de `@old_membership`.

---

### 🎯 Solution Recommandée : Ajouter le Renouvellement pour les Adultes

#### Étape 1 : Modifier le Contrôleur

**Fichier :** `app/controllers/memberships_controller.rb`

**Ajouter après la ligne 57 (gestion enfants) :**
```ruby
# Si renouvellement depuis une adhésion expirée (pour adultes)
if type == "adult" && params[:renew_from].present?
  old_membership = current_user.memberships.find_by(id: params[:renew_from])
  if old_membership && !old_membership.is_child_membership? && old_membership.expired?
    @old_membership = old_membership
    # Pré-remplir les informations depuis l'ancienne adhésion
    # Note: on ne pré-remplit PAS with_tshirt pour permettre de choisir un nouveau T-shirt
    @membership = Membership.new(
      is_child_membership: false,
      first_name: old_membership.first_name || current_user.first_name,
      last_name: old_membership.last_name || current_user.last_name,
      email: current_user.email, # Toujours depuis le compte utilisateur
      phone: old_membership.phone || current_user.phone,
      date_of_birth: old_membership.date_of_birth || current_user.date_of_birth,
      address: old_membership.address || current_user.address,
      city: old_membership.city || current_user.city,
      postal_code: old_membership.postal_code || current_user.postal_code,
      country: old_membership.country || current_user.country || "FR",
      category: old_membership.category,
      with_tshirt: false,
      tshirt_size: nil,
      tshirt_qty: 0
    )
  end
end
```

**Note importante :** Pour les adultes, certaines informations peuvent venir de `current_user` (email, nom, prénom) car elles sont liées au compte utilisateur, contrairement aux enfants où tout vient de l'ancienne adhésion.

---

#### Étape 2 : Modifier la Vue `index.html.erb`

**Fichier :** `app/views/memberships/index.html.erb`

**Remplacer la ligne 338-341 :**
```erb
<!-- AVANT -->
<% else %>
  <%= link_to new_membership_path(check_age: true), class: "btn btn-sm btn-success" do %>
    <i class="bi bi-arrow-repeat me-1"></i>Renouveler
  <% end %>
<% end %>

<!-- APRÈS -->
<% else %>
  <%= link_to new_membership_path(type: 'adult', renew_from: membership.id), class: "btn btn-sm btn-success" do %>
    <i class="bi bi-arrow-repeat me-1"></i>Renouveler
  <% end %>
<% end %>
```

---

#### Étape 3 : Modifier la Vue `_membership_card.html.erb`

**Fichier :** `app/views/memberships/_membership_card.html.erb`

**Remplacer la ligne 104-106 :**
```erb
<!-- AVANT -->
<% else %>
  <%= link_to new_membership_path(type: 'adult'), class: "btn btn-sm btn-success" do %>
    <i class="bi bi-arrow-repeat me-1"></i>Renouveler
  <% end %>
<% end %>

<!-- APRÈS -->
<% else %>
  <%= link_to new_membership_path(type: 'adult', renew_from: membership.id), class: "btn btn-sm btn-success" do %>
    <i class="bi bi-arrow-repeat me-1"></i>Renouveler
  <% end %>
<% end %>
```

---

#### Étape 4 : Modifier le Formulaire Adulte

**Fichier :** `app/views/memberships/adult_form.html.erb`

**1. Modifier le Hero Section (lignes 14-15) :**
```erb
<!-- AVANT -->
<h1 class="hero-title">MON ADHÉSION</h1>
<p class="hero-subtitle">Rejoignez Grenoble Roller et profitez de tous les avantages</p>

<!-- APRÈS -->
<h1 class="hero-title">
  <% if @old_membership %>
    RENOUVELLEMENT D'ADHÉSION
  <% else %>
    MON ADHÉSION
  <% end %>
</h1>
<p class="hero-subtitle">
  <% if @old_membership %>
    Renouvellement de votre adhésion pour la saison <%= @season %>
  <% else %>
    Rejoignez Grenoble Roller et profitez de tous les avantages
  <% end %>
</p>
```

**2. Ajouter un message d'information après le titre de l'étape 2 (après ligne 94) :**
```erb
<% if @old_membership %>
  <div class="alert alert-info mb-4">
    <i class="bi bi-info-circle me-2"></i>
    <strong>Renouvellement d'adhésion</strong> : Vos informations ont été pré-remplies depuis votre dernière adhésion.
    Vous pouvez les modifier si nécessaire.
  </div>
<% end %>
```

**3. Pré-remplir les champs avec les valeurs de `@membership` (si présentes) :**

Les champs sont déjà pré-remplis avec `@user` (lignes 101, 110, 119, 133, 214, 228, 237), mais il faut aussi prendre en compte `@membership` si présent :

```erb
<!-- Exemple pour le prénom (ligne 99-103) -->
<%= f.text_field :first_name,
    class: "form-control form-control-lg",
    value: @membership&.first_name || @user.first_name.presence,
    required: true,
    onblur: "validateField(this)" %>
```

**Note :** Appliquer cette logique à tous les champs :
- `first_name` : `@membership&.first_name || @user.first_name.presence`
- `last_name` : `@membership&.last_name || @user.last_name.presence`
- `phone` : `@membership&.phone || @user.phone.presence`
- `date_of_birth` : `@membership&.date_of_birth || @user.date_of_birth`
- `address` : `@membership&.address || @user.address.presence`
- `city` : `@membership&.city || @user.city.presence`
- `postal_code` : `@membership&.postal_code || @user.postal_code.presence`
- `country` : `@membership&.country || @user.country || "FR"`

**4. Ajouter l'initialisation JavaScript (après la ligne 1125, dans le DOMContentLoaded) :**
```javascript
// Initialiser les valeurs si renouvellement depuis une adhésion expirée
<% if @old_membership %>
  // Initialiser la date de naissance si elle est pré-remplie
  <% if @membership&.date_of_birth %>
    setTimeout(() => {
      updateAdultDateOfBirth();
      updateAdultAge(); // Calculer l'âge et afficher/masquer les messages
    }, 100);
  <% end %>

  // Sélectionner la catégorie si elle était pré-remplie
  <% if @membership&.category %>
    const categoryRadio = document.getElementById('category_<%= @membership.category %>');
    if (categoryRadio) {
      categoryRadio.checked = true;
      selectCategory('<%= @membership.category %>');
    }
  <% end %>
<% end %>
```

---

### 📊 Comparaison : Enfants vs Adultes (après implémentation)

| Aspect | Enfants | Adultes (après implémentation) |
|--------|---------|--------------------------------|
| **Paramètre URL** | `renew_from: membership.id` | `renew_from: membership.id` ✅ |
| **Contrôleur** | Gère `renew_from` pour `type == "child"` | Gère `renew_from` pour `type == "adult"` ✅ |
| **Pré-remplissage** | Depuis `old_membership` uniquement | Depuis `old_membership` + `current_user` (fallback) ✅ |
| **Titre dynamique** | "RÉADHÉSION DE [NOM ENFANT]" | "RENOUVELLEMENT D'ADHÉSION" ✅ |
| **Message info** | Affiche nom enfant | Message générique ✅ |
| **Initialisation JS** | Pré-remplit date, catégorie | Pré-remplit date, catégorie ✅ |

---

### ✅ Avantages de cette Approche

1. **Cohérence** : Même logique pour enfants et adultes
2. **Réutilisabilité** : Code similaire, facile à maintenir
3. **Expérience utilisateur** : Renouvellement simplifié pour tous
4. **Sécurité** : Vérification que l'adhésion appartient à l'utilisateur et est expirée
5. **Flexibilité** : Fallback sur `current_user` pour les adultes (données toujours à jour)

---

### ⚠️ Points d'Attention

1. **Données utilisateur vs adhésion** : Pour les adultes, certaines données peuvent venir de `current_user` (email, nom, prénom) car elles sont liées au compte. Il faut décider quelle source prioriser.

2. **Validation** : S'assurer que les données pré-remplies passent toutes les validations (âge, format téléphone, etc.)

3. **Catégorie** : La catégorie peut avoir changé entre les saisons. Permettre de la modifier facilement.

4. **T-shirt** : Ne pas pré-remplir `with_tshirt` pour permettre de choisir un nouveau T-shirt à chaque renouvellement.

---

### 📝 Checklist d'Implémentation

#### Backend
- [ ] Ajouter gestion `renew_from` pour `type == "adult"` dans le contrôleur
- [ ] Pré-remplir `@membership` avec données de `old_membership` + fallback `current_user`
- [ ] Vérifier sécurité : `old_membership` appartient à `current_user` et est expirée

#### Frontend - Vue `index.html.erb`
- [ ] Modifier lien "Renouveler" dans section Historique (ligne 338-341)
- [ ] Ajouter paramètre `renew_from: membership.id`

#### Frontend - Vue `_membership_card.html.erb`
- [ ] Modifier lien "Renouveler" pour adhésions expirées (ligne 104-106)
- [ ] Ajouter paramètre `renew_from: membership.id`

#### Frontend - Formulaire `adult_form.html.erb`
- [ ] Ajouter titre dynamique dans Hero Section
- [ ] Ajouter message d'information après titre étape 2
- [ ] Pré-remplir tous les champs avec `@membership` (fallback `@user`)
- [ ] Ajouter initialisation JavaScript pour date de naissance et catégorie

#### Tests
- [ ] Tester renouvellement avec adhésion expirée
- [ ] Vérifier pré-remplissage correct des champs
- [ ] Vérifier que les modifications sont possibles
- [ ] Vérifier validation avant soumission

---

**Date de création :** 2025-01-XX  
**Auteur :** Analyse comparative  
**Statut :** ⚠️ Incohérences identifiées - Action requise
