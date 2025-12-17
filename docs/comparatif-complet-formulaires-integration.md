# Comparatif Complet : Formulaires d'Adhésion Enfant vs Adulte + Intégration Essai Gratuit

**Date :** 2025-01-13  
**Version :** 2.0 - Analyse complète avec partials et intégration essai gratuit

> 📚 **Index Documentation :** Voir [`INDEX-FORMULAIRES-ADHESION.md`](./INDEX-FORMULAIRES-ADHESION.md) pour la vue d'ensemble  
> 🗓️ **Plan de Sprints :** Voir [`plan-sprints-formulaires-adhesion.md`](./plan-sprints-formulaires-adhesion.md) pour le planning d'exécution  
> 🔄 **Renouvellement Adulte :** Voir [`comparatif-formulaires-enfant-adulte.md`](./comparatif-formulaires-enfant-adulte.md) section "RENOUVELLEMENT D'ADHÉSION"  
> 🎁 **Essai Gratuit :** Voir [`ESSAI_GRATUIT_ENFANTS.md`](./ESSAI_GRATUIT_ENFANTS.md) pour la spécification complète

---

## 📋 Fichiers Analysés

### Formulaires Principaux
- [`app/views/memberships/child_form.html.erb`](../app/views/memberships/child_form.html.erb) - Formulaire enfant (1304 lignes)
- [`app/views/memberships/adult_form.html.erb`](../app/views/memberships/adult_form.html.erb) - Formulaire adulte (1275 lignes)
- [`app/views/memberships/teen_form.html.erb`](../app/views/memberships/teen_form.html.erb) - Formulaire ado (non analysé ici)

### Partials Utilisés
- [`app/views/memberships/_form_stepper.html.erb`](../app/views/memberships/_form_stepper.html.erb) - Stepper commun (98 lignes)
- [`app/views/memberships/_membership_card.html.erb`](../app/views/memberships/_membership_card.html.erb) - Carte adhésion
- [`app/views/memberships/_child_mini_card.html.erb`](../app/views/memberships/_child_mini_card.html.erb) - Mini carte enfant

### Contrôleurs
- [`app/controllers/memberships_controller.rb`](../app/controllers/memberships_controller.rb) - Logique backend (1127 lignes)

### Modèles
- [`app/models/membership.rb`](../app/models/membership.rb) - Modèle Membership
- [`app/models/attendance.rb`](../app/models/attendance.rb) - Modèle Attendance (pour essai gratuit)

### Vues Index
- [`app/views/memberships/index.html.erb`](../app/views/memberships/index.html.erb) - Liste des adhésions

---

## 🔍 ANALYSE COMPLÈTE PAR SECTION

### 1. STRUCTURE GÉNÉRALE ET PARTIALS

#### Hero Section
| Aspect | Child Form | Adult Form | Fichier | Ligne | Cohérence |
|--------|-----------|------------|---------|-------|-----------|
| Titre dynamique | ✅ Oui (`@old_membership`) | ❌ Non (fixe) | `child_form.html.erb` | 14-19 | ⚠️ **INCOHÉRENT** |
| Sous-titre dynamique | ✅ Oui (`@old_membership`) | ❌ Non (fixe) | `adult_form.html.erb` | 14-15 | ⚠️ **INCOHÉRENT** |
| Badges saison | ✅ Identique | ✅ Identique | Les deux | ~29-37 | ✅ OK |
| Progress bar | ✅ Identique | ✅ Identique | Les deux | ~40-50 | ✅ OK |

**Problème identifié :**
- Le formulaire enfant gère la réadhésion (`@old_membership`) mais pas le formulaire adulte
- **Impact :** Les adultes ne peuvent pas renouveler leur adhésion avec pré-remplissage
- **Fichiers concernés :**
  - `app/views/memberships/adult_form.html.erb` (lignes 14-15)
  - `app/controllers/memberships_controller.rb` (lignes 59-77)

#### Stepper (Partial Commun)
| Aspect | Child Form | Adult Form | Fichier | Cohérence |
|--------|-----------|------------|---------|-----------|
| Utilisation partial | ✅ Oui | ✅ Oui | `_form_stepper.html.erb` | ✅ OK |
| Paramètres | `form_type: 'child'` | `form_type: 'adult'` | Les deux | ✅ OK |
| Étapes définies | 5 étapes (sans T-shirt) | 5 étapes (sans T-shirt) | `_form_stepper.html.erb` | ✅ OK |
| Logique conditionnelle | ✅ Selon `form_type` | ✅ Selon `form_type` | `_form_stepper.html.erb` | ✅ OK |

**✅ Bon point :** Le stepper est bien factorisé dans un partial commun.

---

### 2. FORMULAIRE (form_with)

#### ID du formulaire
| Child Form | Adult Form | Fichier | Cohérence |
|-----------|------------|---------|-----------|
| `id: "child_membership_form"` | `id: "adult_membership_form"` | Les deux | ✅ OK |

#### Champs cachés
| Champ | Child Form | Adult Form | Fichier | Ligne | Cohérence |
|-------|-----------|------------|---------|-------|-----------|
| Type | `is_child_membership: true` | `type: "adult"` | Les deux | ~62, ~47 | ⚠️ **INCOHÉRENT** |
| T-shirt | `with_tshirt: false` | `with_tshirt: false` | Les deux | ~63, ~48 | ✅ OK |
| Paiement | `payment_method: "helloasso"` | `payment_method: "helloasso"` | Les deux | ~62, ~49 | ✅ OK |

**Problème identifié :**
- Le formulaire enfant utilise `is_child_membership: true`
- Le formulaire adulte utilise `type: "adult"`
- **Impact :** Logique backend potentiellement différente, risque de bugs
- **Fichiers concernés :**
  - `app/views/memberships/child_form.html.erb` (ligne 63)
  - `app/views/memberships/adult_form.html.erb` (ligne 47)
  - `app/controllers/memberships_controller.rb` (lignes 183, 201)

---

### 3. ÉTAPE 1 : CATÉGORIE

#### Structure HTML
| Aspect | Child Form | Adult Form | Fichier | Ligne | Cohérence |
|--------|-----------|------------|---------|-------|-----------|
| Titre section | "Choisissez l'adhésion" | "Choisissez votre adhésion" | Les deux | ~53, ~54 | ✅ OK |
| Intro | "Sélectionnez la formule qui correspond à votre enfant" | "Sélectionnez la formule qui vous correspond" | Les deux | ~54, ~57 | ✅ OK |
| Sélection par défaut | `key == :standard && @membership.nil?` | `key == :standard` | Les deux | ~74, ~68 | ⚠️ **INCOHÉRENT** |

**Problème identifié :**
- Child form : vérifie `@membership.nil?` en plus
- Adult form : sélectionne toujours `:standard` par défaut
- **Impact :** Comportement différent lors du chargement initial
- **Fichiers concernés :**
  - `app/views/memberships/child_form.html.erb` (ligne ~74)
  - `app/views/memberships/adult_form.html.erb` (ligne ~68)

---

### 4. ÉTAPE 2 : INFORMATIONS

#### Champs présents
| Champ | Child Form | Adult Form | Fichier | Ligne | Cohérence |
|-------|-----------|------------|---------|-------|-----------|
| Prénom | `child_first_name` | `first_name` | Les deux | ~122, ~99 | ✅ OK |
| Nom | `child_last_name` | `last_name` | Les deux | ~132, ~108 | ✅ OK |
| Email | ❌ Pas de champ | ✅ `email` (readonly) | `adult_form.html.erb` | ~117 | ✅ OK |
| Téléphone | ❌ Pas de champ | ✅ `phone` (avec masque) | `adult_form.html.erb` | ~131 | ✅ OK |
| Date de naissance | `child_date_of_birth` | `date_of_birth` | Les deux | ~141, ~156 | ✅ OK |

#### Date de naissance - Années disponibles
| Child Form | Adult Form | Fichier | Ligne | Cohérence |
|-----------|------------|---------|-------|-----------|
| `Date.today.year.downto(Date.today.year - 18)` | `Date.today.year.downto(Date.today.year - 120)` | Les deux | ~182, ~182 | ✅ OK |

#### Date de naissance - Validation JavaScript
| Aspect | Child Form | Adult Form | Fichier | Ligne | Cohérence |
|--------|-----------|------------|---------|-------|-----------|
| Fonction update | `updateChildDateOfBirth()` | `updateAdultDateOfBirth()` | Les deux | ~576, ~550 | ✅ OK |
| Fonction âge | `checkChildAge()` | `updateAdultAge()` | Les deux | ~594, ~568 | ⚠️ **INCOHÉRENT** |
| Validation min | < 6 ans bloqué | < 16 ans bloqué | Les deux | ~639, ~616 | ✅ OK |

**Problème identifié :**
- Noms de fonctions différents (`checkChildAge` vs `updateAdultAge`)
- **Impact :** Code moins maintenable, risque de confusion
- **Fichiers concernés :**
  - `app/views/memberships/child_form.html.erb` (ligne 594)
  - `app/views/memberships/adult_form.html.erb` (ligne 568)

#### Date de naissance - Messages d'erreur
| Aspect | Child Form | Adult Form | Fichier | Ligne | Cohérence |
|--------|-----------|------------|---------|-------|-----------|
| Message < 6/16 ans | "L'adhésion n'est pas possible pour les enfants de moins de 6 ans." | "L'adhésion adulte n'est pas possible pour les personnes de moins de 16 ans..." | Les deux | ~649, ~634 | ✅ OK |
| Affichage âge | `child_age_display` | `adult_age_display` | Les deux | ~598, ~573 | ✅ OK |
| Inférence catégorie | ✅ Oui (ENFANT/ADOLESCENT) | ❌ Non | `child_form.html.erb` | ~732-742 | ⚠️ **INCOHÉRENT** |

**Problème identifié :**
- Le formulaire enfant affiche une inférence de catégorie automatique
- Le formulaire adulte ne le fait pas
- **Impact :** Expérience utilisateur incohérente
- **Fichiers concernés :**
  - `app/views/memberships/child_form.html.erb` (lignes 732-742)

---

### 5. ÉTAPE 3 : SECTION SPÉCIFIQUE

#### Child Form : Autorisation parentale
- Section affichée si âge < 16 ans
- Signature digitale avec nom parent + nom enfant
- Prix affiché dynamiquement
- **Fichier :** `app/views/memberships/child_form.html.erb` (lignes ~380-450)

#### Adult Form : Coordonnées
- Adresse, ville, code postal, pays
- Champ adresse avec autocomplétion
- **Fichier :** `app/views/memberships/adult_form.html.erb` (lignes ~200-250)

**Cohérence :** ✅ OK (différence attendue, sections différentes)

---

### 6. QUESTIONNAIRE DE SANTÉ

#### Textes
| Aspect | Child Form | Adult Form | Fichier | Ligne | Cohérence |
|--------|-----------|------------|---------|-------|-----------|
| Intro | "concernant la santé de votre enfant" | "concernant votre santé" | Les deux | ~280, ~270 | ✅ OK |

#### Messages Standard avec réponse OUI
| Aspect | Child Form | Adult Form | Fichier | Ligne | Cohérence |
|--------|-----------|------------|---------|-------|-----------|
| Titre | "Conseil avant la pratique" | "Consultez votre médecin avant de pratiquer" | Les deux | ~350, ~340 | ⚠️ **INCOHÉRENT** |
| Message | "Nous vous recommandons fortement de consulter votre médecin avant la pratique le roller." | "Vous avez indiqué avoir des problèmes de santé. Nous vous recommandons fortement de consulter votre médecin avant de pratiquer le roller." | Les deux | ~351, ~341 | ⚠️ **INCOHÉRENT** |

**Problème identifié :**
- Formulations différentes pour le même cas d'usage
- **Impact :** Expérience utilisateur incohérente
- **Fichiers concernés :**
  - `app/views/memberships/child_form.html.erb` (lignes ~350-351)
  - `app/views/memberships/adult_form.html.erb` (lignes ~340-341)

#### Logique JavaScript
| Aspect | Child Form | Adult Form | Fichier | Ligne | Cohérence |
|--------|-----------|------------|---------|-------|-----------|
| Appel dans `updateCategorySelection()` | ✅ Oui | ✅ Oui | Les deux | ~565, ~520 | ✅ OK |
| Appel dans `checkChildAge()` / `updateAdultAge()` | ✅ Oui | ✅ Oui (corrigé) | Les deux | ~735, ~735 | ✅ OK |

**✅ Corrigé :** L'appel dans `updateAdultAge()` a été ajouté.

---

### 7. CONSENTEMENTS

#### RGPD
| Aspect | Child Form | Adult Form | Fichier | Ligne | Cohérence |
|--------|-----------|------------|---------|-------|-----------|
| Texte | "J'autorise Grenoble Roller à collecter les données **de l'enfant** pour l'adhésion" | "J'autorise Grenoble Roller à collecter **mes données** pour l'adhésion" | Les deux | ~420, ~426 | ✅ OK |

#### Communication
- Identique dans les deux formulaires ✅
- **Fichiers :** Les deux formulaires (lignes ~440-460)

#### FFRS
- Identique dans les deux formulaires ✅
- **Fichiers :** Les deux formulaires (lignes ~464-480)

---

### 8. VALIDATION JAVASCRIPT

#### Fonction `validateField()`

**Validation téléphone :**
| Aspect | Child Form | Adult Form | Fichier | Ligne | Cohérence |
|--------|-----------|------------|---------|-------|-----------|
| Validation | ❌ Pas de validation (pas de champ) | ✅ Validation présente | `adult_form.html.erb` | ~800 | ✅ OK |
| Format exemple | N/A | "06 12 34 56 78" (avec espaces) | `adult_form.html.erb` | ~800 | ⚠️ **À vérifier** |
| Pattern | N/A | `[0-9]{2} [0-9]{2} [0-9]{2} [0-9]{2} [0-9]{2}` | `adult_form.html.erb` | ~137 | ⚠️ **À vérifier** |

**Validation code postal :**
| Aspect | Child Form | Adult Form | Fichier | Cohérence |
|--------|-----------|------------|---------|-----------|
| Validation | ❌ Pas de validation | ✅ Validation présente | `adult_form.html.erb` | ✅ OK |

#### Fonction `validateForm()`

**Validation date de naissance :**
| Aspect | Child Form | Adult Form | Fichier | Cohérence |
|--------|-----------|------------|---------|-----------|
| Vérification jour/mois/année | ✅ Oui | ✅ Oui | Les deux | ✅ OK |
| Vérification âge minimum | < 6 ans | < 16 ans | Les deux | ✅ OK |
| Vérification autorisation parentale | ✅ Oui (si nécessaire) | N/A | `child_form.html.erb` | ✅ OK |

**Validation questionnaire santé :**
- Identique dans les deux formulaires ✅

**Validation certificat médical :**
- Identique dans les deux formulaires ✅

---

### 9. BOUTONS DE SOUMISSION

#### Bouton principal
| Aspect | Child Form | Adult Form | Fichier | Ligne | Cohérence |
|--------|-----------|------------|---------|-------|-----------|
| Texte | "Ajouter l'enfant" | "Valider et payer" | Les deux | ~519, ~496 | ⚠️ **INCOHÉRENT** |
| Classe | `btn-liquid-warning` | `btn-liquid-primary` | Les deux | ~520, ~497 | ⚠️ **INCOHÉRENT** |
| ID | `submit_btn` | `submit_btn` | Les deux | ~521, ~498 | ✅ OK |
| Gestion paiement | `onclick` définit `payment_method` | `onclick` définit `payment_method` | Les deux | ~522, ~499 | ✅ OK |

**Problème identifié :**
- Textes et styles différents pour la même action
- **Impact :** Expérience utilisateur incohérente
- **Fichiers concernés :**
  - `app/views/memberships/child_form.html.erb` (lignes 519-522)
  - `app/views/memberships/adult_form.html.erb` (lignes 496-499)

#### Bouton secondaire "Espèces/Chèques"
| Aspect | Child Form | Adult Form | Fichier | Ligne | Cohérence |
|--------|-----------|------------|---------|-------|-----------|
| Texte | "Déjà adhérent / Espèces / Chèques" | "Déjà adhérent / Espèces / Chèques" | Les deux | ~523, ~500 | ✅ OK |
| Type | `f.submit` | `button type="button"` | Les deux | ~523, ~500 | ⚠️ **INCOHÉRENT** |
| Gestion | `onclick` avec confirmation | Gestionnaire `click` séparé | Les deux | ~526, ~1218 | ⚠️ **INCOHÉRENT** |

**Problème identifié :**
- Approche différente pour gérer le bouton "Espèces/Chèques"
- Child : `f.submit` avec `onclick`
- Adult : `button type="button"` avec gestionnaire `click` séparé
- **Impact :** Code incohérent, risque de bugs
- **Fichiers concernés :**
  - `app/views/memberships/child_form.html.erb` (lignes 523-526)
  - `app/views/memberships/adult_form.html.erb` (lignes 500, 1218-1245)

---

### 10. SCRIPTS JAVASCRIPT

#### Initialisation DOMContentLoaded
| Fonction | Child Form | Adult Form | Fichier | Ligne | Cohérence |
|----------|-----------|------------|---------|-------|-----------|
| `updateCategorySelection()` | ✅ Oui | ✅ Oui | Les deux | ~1163, ~1129 | ✅ OK |
| `checkChildAge()` / `updateAdultAge()` | ✅ Oui | ✅ Oui | Les deux | ~1163, ~1130 | ✅ OK |
| `checkHealthQuestions()` | ✅ Oui | ✅ Oui | Les deux | ~1164, ~1131 | ✅ OK |
| `checkAllConsents()` | ✅ Oui | ✅ Oui | Les deux | ~1165, ~1132 | ✅ OK |
| `validateForm()` | ✅ Oui | ✅ Oui | Les deux | ~1166, ~1133 | ✅ OK |

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
```
**Fichier :** `app/views/memberships/child_form.html.erb` (lignes 1279-1284)

**Adult Form :**
```javascript
// Vérifier l'âge avant soumission
const day = document.getElementById('date_of_birth_day')?.value;
const month = document.getElementById('date_of_birth_month')?.value;
const year = document.getElementById('date_of_birth_year')?.value;
// ... validation âge < 16 ans
```
**Fichier :** `app/views/memberships/adult_form.html.erb` (lignes 1255-1270)

**Problème identifié :**
- Logique de validation avant soumission différente
- Child form : retire les `required` des champs cachés
- Adult form : vérifie l'âge avant soumission
- **Impact :** Comportement différent, risque de bugs
- **Fichiers concernés :**
  - `app/views/memberships/child_form.html.erb` (lignes 1279-1290)
  - `app/views/memberships/adult_form.html.erb` (lignes 1248-1280)

---

### 11. RENOUVELLEMENT D'ADHÉSION

> 📖 **Détails d'Implémentation :** Voir [`comparatif-formulaires-enfant-adulte.md`](./comparatif-formulaires-enfant-adulte.md) - Section "RENOUVELLEMENT D'ADHÉSION" pour les exemples de code détaillés.

#### Backend (Contrôleur)
| Aspect | Child | Adult | Fichier | Ligne | Statut |
|--------|-------|-------|---------|-------|--------|
| Gestion `renew_from` | ✅ Oui | ✅ Oui (corrigé) | `memberships_controller.rb` | 40-57, 59-77 | ✅ OK |
| Vérifications sécurité | ✅ Oui | ✅ Oui | `memberships_controller.rb` | 42, 62 | ✅ OK |
| Pré-remplissage `@membership` | ✅ Oui | ✅ Oui | `memberships_controller.rb` | 46-55, 69-75 | ✅ OK |

**✅ Corrigé :** Le renouvellement adulte backend a été implémenté. Voir [`comparatif-formulaires-enfant-adulte.md`](./comparatif-formulaires-enfant-adulte.md) pour les détails d'implémentation frontend.

#### Frontend - Vues Index
| Aspect | Child | Adult | Fichier | Ligne | Statut |
|--------|-------|-------|---------|-------|--------|
| Lien renouvellement | ✅ Oui | ⚠️ À corriger | `index.html.erb` | 334-337, 338-341 | ⚠️ **À FAIRE** |
| Paramètre `renew_from` | ✅ Oui | ❌ Non | `index.html.erb` | 406, 475 | ⚠️ **À FAIRE** |

**Fichiers concernés :**
- `app/views/memberships/index.html.erb` (lignes 338-341, 475)

#### Frontend - Vue Membership Card
| Aspect | Child | Adult | Fichier | Ligne | Statut |
|--------|-------|-------|---------|-------|--------|
| Lien renouvellement | ✅ Oui | ⚠️ À corriger | `_membership_card.html.erb` | 99-102, 104-106 | ⚠️ **À FAIRE** |
| Paramètre `renew_from` | ✅ Oui | ❌ Non | `_membership_card.html.erb` | 416, 487 | ⚠️ **À FAIRE** |

**Fichiers concernés :**
- `app/views/memberships/_membership_card.html.erb` (lignes 104-106, 487)

#### Frontend - Formulaire Adulte
| Aspect | Statut | Fichier | Ligne | Notes |
|--------|--------|---------|-------|-------|
| Titre dynamique Hero | ⚠️ À faire | `adult_form.html.erb` | 14-15 | Ajouter logique `@old_membership` |
| Message info étape 2 | ⚠️ À faire | `adult_form.html.erb` | ~94 | Ajouter alert info si `@old_membership` |
| Pré-remplissage champs | ⚠️ À faire | `adult_form.html.erb` | ~99-250 | Utiliser `@membership&.xxx \|\| @user.xxx` |
| Initialisation JS | ✅ Oui (corrigé) | `adult_form.html.erb` | 1198-1216 | ✅ Corrigé |

**✅ Partiellement corrigé :** L'initialisation JS est faite, mais les vues et le pré-remplissage des champs restent à faire.

---

### 12. ESSAI GRATUIT ENFANTS (Nouvelle Fonctionnalité)

> 📖 **Spécification Complète :** Voir [`ESSAI_GRATUIT_ENFANTS.md`](./ESSAI_GRATUIT_ENFANTS.md) pour tous les détails techniques, scénarios utilisateurs et modifications nécessaires.

#### État Actuel
| Aspect | Statut | Fichier | Notes |
|--------|--------|---------|-------|
| Essai gratuit parent | ✅ Implémenté | `attendances_controller.rb` | Fonctionne |
| Essai gratuit enfant | ❌ Non implémenté | - | Bloqué par adhésion requise |
| Création enfant sans adhésion | ❌ Non implémenté | `memberships_controller.rb` | Nécessite adhésion |

**Pour plus de détails :** Voir [`ESSAI_GRATUIT_ENFANTS.md`](./ESSAI_GRATUIT_ENFANTS.md) - Section "État Actuel"

#### Modifications Nécessaires (Résumé)

**1. Modèle Membership**
- **Fichier :** [`app/models/membership.rb`](../app/models/membership.rb)
- **Action :** Ajouter support status `'trial'` pour enfants sans adhésion payée
- **Ligne :** À déterminer (enum status)

**2. Contrôleur Attendances**
- **Fichier :** [`app/controllers/initiations/attendances_controller.rb`](../app/controllers/initiations/attendances_controller.rb)
- **Action :** Modifier logique essai gratuit pour distinguer parent/enfant
- **Ligne :** ~91

**3. Policy Initiation**
- **Fichier :** [`app/policies/event/initiation_policy.rb`](../app/policies/event/initiation_policy.rb)
- **Action :** Modifier `can_register_to_initiation?` pour gérer essai enfant
- **Ligne :** ~92

**4. Modèle Attendance**
- **Fichier :** [`app/models/attendance.rb`](../app/models/attendance.rb)
- **Action :** Modifier validation `can_use_free_trial` pour distinguer parent/enfant
- **Ligne :** ~130

**5. Formulaire Création Enfant**
- **Fichier :** [`app/views/memberships/child_form.html.erb`](../app/views/memberships/child_form.html.erb)
- **Action :** Ajouter option "Créer sans adhésion (pour essai gratuit)"
- **Ligne :** À déterminer (après boutons submit)

**6. Formulaire Inscription Initiation**
- **Fichier :** À déterminer (probablement `app/views/initiations/show.html.erb`)
- **Action :** Afficher option essai gratuit si enfant sans adhésion
- **Ligne :** À déterminer

---

## 🚨 PROBLÈMES CRITIQUES IDENTIFIÉS

### Priorité CRITIQUE (Bloquants)

1. **Champs cachés incohérents**
   - **Child :** `is_child_membership: true`
   - **Adult :** `type: "adult"`
   - **Fichiers :** `child_form.html.erb` (ligne 63), `adult_form.html.erb` (ligne 47), `memberships_controller.rb` (lignes 183, 201)
   - **Action :** Unifier la logique backend

2. **Bouton "Espèces/Chèques" ne fonctionne pas (adulte)**
   - **Problème :** Crée toujours un paiement HelloAsso au lieu d'une adhésion sans paiement
   - **Fichiers :** `adult_form.html.erb` (lignes 500, 1218-1245), `memberships_controller.rb` (ligne 195)
   - **Action :** Corriger le gestionnaire `click` et la soumission du formulaire

3. **Renouvellement adulte incomplet**
   - **Problème :** Backend OK, mais vues et pré-remplissage manquants
   - **Fichiers :** `index.html.erb` (lignes 338-341), `_membership_card.html.erb` (lignes 104-106), `adult_form.html.erb` (lignes 14-15, ~94, ~99-250)
   - **Action :** Compléter les vues et le pré-remplissage

### Priorité HAUTE (Important)

4. **Validation téléphone - Format d'exemple différent**
   - **Child :** N/A (pas de champ)
   - **Adult :** "06 12 34 56 78" (avec espaces)
   - **Fichiers :** `adult_form.html.erb` (lignes ~137, ~800)
   - **Action :** Uniformiser le format d'exemple et le pattern

5. **Messages questionnaire santé incohérents**
   - **Child :** "Conseil avant la pratique"
   - **Adult :** "Consultez votre médecin avant de pratiquer"
   - **Fichiers :** `child_form.html.erb` (lignes ~350-351), `adult_form.html.erb` (lignes ~340-341)
   - **Action :** Harmoniser les messages

6. **Boutons submit incohérents**
   - **Child :** "Ajouter l'enfant" (warning)
   - **Adult :** "Valider et payer" (primary)
   - **Fichiers :** `child_form.html.erb` (lignes 519-522), `adult_form.html.erb` (lignes 496-499)
   - **Action :** Harmoniser les textes et styles

7. **Validation avant soumission différente**
   - **Child :** Retire les `required` des champs cachés
   - **Adult :** Vérifie l'âge avant soumission
   - **Fichiers :** `child_form.html.erb` (lignes 1279-1290), `adult_form.html.erb` (lignes 1248-1280)
   - **Action :** Unifier la logique de validation

### Priorité MOYENNE (Amélioration)

8. **Inférence catégorie manquante (adulte)**
   - **Child :** Affiche inférence catégorie automatique
   - **Adult :** Ne l'affiche pas
   - **Fichiers :** `child_form.html.erb` (lignes 732-742)
   - **Action :** Ajouter inférence catégorie pour adultes ou la retirer des enfants

9. **Sélection catégorie par défaut différente**
   - **Child :** `key == :standard && @membership.nil?`
   - **Adult :** `key == :standard`
   - **Fichiers :** `child_form.html.erb` (ligne ~74), `adult_form.html.erb` (ligne ~68)
   - **Action :** Unifier la logique de sélection par défaut

10. **Nommage fonctions JavaScript incohérent**
    - **Child :** `checkChildAge()`
    - **Adult :** `updateAdultAge()`
    - **Fichiers :** `child_form.html.erb` (ligne 594), `adult_form.html.erb` (ligne 568)
    - **Action :** Harmoniser les noms de fonctions

---

## 📋 TODOLIST COMPLÈTE D'INTÉGRATION

### PHASE 1 : CORRECTIONS CRITIQUES (Priorité 1)

#### 1.1 Backend - Unification Champs Cachés
- [ ] **Tâche 1.1.1** : Analyser utilisation `is_child_membership` vs `type` dans `memberships_controller.rb`
  - **Fichier :** `app/controllers/memberships_controller.rb`
  - **Lignes :** 183, 201, 203, 206
  - **Action :** Décider schéma cible (recommandation : `is_child_membership` comme source de vérité, `type` pour router vues)
- [ ] **Tâche 1.1.2** : Unifier champs cachés dans `adult_form.html.erb`
  - **Fichier :** `app/views/memberships/adult_form.html.erb`
  - **Ligne :** 47
  - **Action :** Remplacer `type: "adult"` par logique cohérente avec enfant
- [ ] **Tâche 1.1.3** : Vérifier cohérence dans `memberships_controller.rb#create`
  - **Fichier :** `app/controllers/memberships_controller.rb`
  - **Lignes :** 183-210
  - **Action :** S'assurer que la détection du type fonctionne avec le nouveau schéma

#### 1.2 Backend - Correction Bouton "Espèces/Chèques" (Adulte)
- [ ] **Tâche 1.2.1** : Corriger gestionnaire `click` pour bouton "Espèces/Chèques"
  - **Fichier :** `app/views/memberships/adult_form.html.erb`
  - **Lignes :** 1218-1245
  - **Action :** Vérifier que `payment_method_field` est bien défini avant soumission, ajouter logs de débogage
- [ ] **Tâche 1.2.2** : Harmoniser avec formulaire enfant
  - **Fichier :** `app/views/memberships/child_form.html.erb`
  - **Lignes :** 523-526
  - **Action :** Utiliser la même approche (soit `f.submit` avec `onclick`, soit `button` avec gestionnaire séparé)
- [ ] **Tâche 1.2.3** : Tester flux complet "Espèces/Chèques"
  - **Action :** Vérifier que `create_without_payment` est bien appelé et crée l'adhésion sans paiement HelloAsso

#### 1.3 Frontend - Renouvellement Adulte (Compléter)
- [ ] **Tâche 1.3.1** : Modifier lien renouvellement dans `index.html.erb`
  - **Fichier :** `app/views/memberships/index.html.erb`
  - **Lignes :** 338-341
  - **Action :** Remplacer `check_age: true` par `type: 'adult', renew_from: membership.id`
- [ ] **Tâche 1.3.2** : Modifier lien renouvellement dans `_membership_card.html.erb`
  - **Fichier :** `app/views/memberships/_membership_card.html.erb`
  - **Lignes :** 104-106
  - **Action :** Ajouter paramètre `renew_from: membership.id`
- [ ] **Tâche 1.3.3** : Ajouter titre dynamique Hero dans `adult_form.html.erb`
  - **Fichier :** `app/views/memberships/adult_form.html.erb`
  - **Lignes :** 14-15
  - **Action :** Ajouter logique `@old_membership` comme dans `child_form.html.erb` (lignes 14-19)
- [ ] **Tâche 1.3.4** : Ajouter message info étape 2 dans `adult_form.html.erb`
  - **Fichier :** `app/views/memberships/adult_form.html.erb`
  - **Ligne :** ~94 (après titre étape 2)
  - **Action :** Ajouter `alert alert-info` conditionnel si `@old_membership`
- [ ] **Tâche 1.3.5** : Pré-remplir champs avec `@membership` dans `adult_form.html.erb`
  - **Fichier :** `app/views/memberships/adult_form.html.erb`
  - **Lignes :** ~99-250 (tous les champs)
  - **Action :** Utiliser `@membership&.xxx || @user.xxx.presence` pour chaque champ :
    - `first_name` (ligne ~101)
    - `last_name` (ligne ~110)
    - `phone` (ligne ~133)
    - `date_of_birth` (lignes ~156-182)
    - `address` (ligne ~214)
    - `city` (ligne ~228)
    - `postal_code` (ligne ~237)
    - `country` (ligne ~246)

### PHASE 2 : HARMONISATION (Priorité 2)

#### 2.1 Validation Téléphone
- [ ] **Tâche 2.1.1** : Choisir format de référence (avec ou sans espaces)
  - **Recommandation :** Avec espaces "06 12 34 56 78" (plus lisible)
- [ ] **Tâche 2.1.2** : Aligner placeholder dans `adult_form.html.erb`
  - **Fichier :** `app/views/memberships/adult_form.html.erb`
  - **Ligne :** ~135
  - **Action :** Utiliser le format choisi
- [ ] **Tâche 2.1.3** : Aligner pattern dans `adult_form.html.erb`
  - **Fichier :** `app/views/memberships/adult_form.html.erb`
  - **Ligne :** ~137
  - **Action :** Utiliser le pattern correspondant au format choisi
- [ ] **Tâche 2.1.4** : Aligner message erreur dans `validateField()` (adult_form)
  - **Fichier :** `app/views/memberships/adult_form.html.erb`
  - **Ligne :** ~800
  - **Action :** Utiliser le format choisi dans le message d'erreur
- [ ] **Tâche 2.1.5** : Vérifier masque Stimulus `phone-mask`
  - **Fichier :** `app/views/memberships/adult_form.html.erb`
  - **Ligne :** ~130-142
  - **Action :** S'assurer que le masque est cohérent avec le format choisi

#### 2.2 Questionnaire de Santé
- [ ] **Tâche 2.2.1** : Comparer textes `health_standard_yes_info` et `health_standard_no_info`
  - **Fichiers :** `child_form.html.erb` (lignes ~350-351), `adult_form.html.erb` (lignes ~340-341)
  - **Action :** Lister toutes les différences
- [ ] **Tâche 2.2.2** : Uniformiser textes questionnaire santé
  - **Fichiers :** `child_form.html.erb`, `adult_form.html.erb`
  - **Action :** Harmoniser ton, structure, mentions FFRS
- [ ] **Tâche 2.2.3** : Vérifier logique `checkHealthQuestions()` identique
  - **Fichiers :** `child_form.html.erb` (ligne ~765), `adult_form.html.erb` (ligne ~936)
  - **Action :** Comparer les deux fonctions et harmoniser

#### 2.3 Boutons Soumission
- [ ] **Tâche 2.3.1** : Choisir libellés cibles pour boutons principaux
  - **Recommandation :** 
    - Enfant : "Valider l'adhésion enfant"
    - Adulte : "Valider et payer"
- [ ] **Tâche 2.3.2** : Harmoniser classes CSS boutons principaux
  - **Fichiers :** `child_form.html.erb` (ligne ~520), `adult_form.html.erb` (ligne ~497)
  - **Action :** Utiliser la même classe (recommandation : `btn-liquid-primary`)
- [ ] **Tâche 2.3.3** : Harmoniser gestion bouton "Espèces/Chèques"
  - **Fichiers :** `child_form.html.erb` (lignes 523-526), `adult_form.html.erb` (lignes 500, 1218-1245)
  - **Action :** Utiliser la même approche (recommandation : `f.submit` avec `onclick` comme enfant)

#### 2.4 Validation JavaScript
- [ ] **Tâche 2.4.1** : Comparer fonctions `validateForm()` enfant/adulte
  - **Fichiers :** `child_form.html.erb` (ligne ~850), `adult_form.html.erb` (ligne ~850)
  - **Action :** Extraire patterns communs
- [ ] **Tâche 2.4.2** : Aligner gestion champs required cachés
  - **Fichiers :** `child_form.html.erb` (lignes 1279-1290), `adult_form.html.erb` (lignes 1248-1280)
  - **Action :** Unifier la logique (recommandation : combiner les deux approches)
- [ ] **Tâche 2.4.3** : Aligner messages d'erreur
  - **Fichiers :** Les deux formulaires
  - **Action :** Uniformiser format et contenu des messages
- [ ] **Tâche 2.4.4** : Aligner désactivation boutons
  - **Fichiers :** Les deux formulaires
  - **Action :** Utiliser la même logique de désactivation

### PHASE 3 : AMÉLIORATIONS (Priorité 3)

#### 3.1 Sélection Catégorie par Défaut
- [ ] **Tâche 3.1.1** : Décider règle de sélection par défaut
  - **Recommandation :** `key == :standard && @membership.nil?` (comme enfant)
- [ ] **Tâche 3.1.2** : Simplifier logique enfant si nécessaire
  - **Fichier :** `app/views/memberships/child_form.html.erb`
  - **Ligne :** ~74
- [ ] **Tâche 3.1.3** : Aligner adulte sur même condition
  - **Fichier :** `app/views/memberships/adult_form.html.erb`
  - **Ligne :** ~68

#### 3.2 Inférence Catégorie
- [ ] **Tâche 3.2.1** : Décider si ajouter inférence catégorie pour adultes
  - **Options :** 
    - Ajouter pour adultes (cohérence)
    - Retirer pour enfants (simplicité)
- [ ] **Tâche 3.2.2** : Implémenter la décision
  - **Fichiers :** Selon décision (`child_form.html.erb` lignes 732-742, ou `adult_form.html.erb`)

#### 3.3 Nommage Fonctions JavaScript
- [ ] **Tâche 3.3.1** : Harmoniser noms fonctions âge
  - **Options :**
    - `checkChildAge()` → `updateChildAge()` (cohérence avec adulte)
    - `updateAdultAge()` → `checkAdultAge()` (cohérence avec enfant)
- [ ] **Tâche 3.3.2** : Renommer fonction choisie
  - **Fichiers :** Selon décision
- [ ] **Tâche 3.3.3** : Mettre à jour tous les appels
  - **Fichiers :** Les deux formulaires

#### 3.4 Callbacks Questionnaire Santé
- [ ] **Tâche 3.4.1** : Vérifier quand `checkHealthQuestions()` est appelée
  - **Fichiers :** Les deux formulaires
  - **Points à vérifier :**
    - Changement de catégorie ✅ (déjà fait)
    - Changement de réponses ✅ (déjà fait)
    - Changement d'âge ✅ (corrigé pour adulte)
- [ ] **Tâche 3.4.2** : Ajouter/retirer appels manquants
  - **Action :** S'assurer que les deux formulaires ont les mêmes points de recalcul

### PHASE 4 : ESSAI GRATUIT ENFANTS (Nouvelle Fonctionnalité)

> 📖 **Spécification Complète :** Voir [`ESSAI_GRATUIT_ENFANTS.md`](./ESSAI_GRATUIT_ENFANTS.md) pour tous les détails techniques, scénarios utilisateurs et modifications nécessaires.

#### 4.1 Backend - Modèle Membership
- [ ] **Tâche 4.1.1** : Ajouter support status `'trial'` dans enum
  - **Fichier :** `app/models/membership.rb`
  - **Action :** Ajouter `trial: 3` dans enum `status`
- [ ] **Tâche 4.1.2** : Modifier validations pour accepter status `trial`
  - **Fichier :** `app/models/membership.rb`
  - **Action :** Adapter validations pour permettre enfants sans adhésion payée

#### 4.2 Backend - Contrôleur Attendances
- [ ] **Tâche 4.2.1** : Modifier logique essai gratuit dans `attendances_controller.rb`
  - **Fichier :** `app/controllers/initiations/attendances_controller.rb`
  - **Ligne :** ~91
  - **Action :** Distinguer essai gratuit parent vs enfant
- [ ] **Tâche 4.2.2** : Vérifier si enfant a déjà utilisé son essai
  - **Fichier :** `app/controllers/initiations/attendances_controller.rb`
  - **Action :** Utiliser `child_membership_id` pour vérifier essai par enfant

#### 4.3 Backend - Policy Initiation
- [ ] **Tâche 4.3.1** : Modifier `can_register_to_initiation?` dans `initiation_policy.rb`
  - **Fichier :** `app/policies/event/initiation_policy.rb`
  - **Ligne :** ~92
  - **Action :** Gérer essai gratuit pour enfants avec `child_membership_id`
- [ ] **Tâche 4.3.2** : Distinguer parent/enfant dans la vérification
  - **Fichier :** `app/policies/event/initiation_policy.rb`
  - **Action :** Vérifier essai par `child_membership_id` si présent

#### 4.4 Backend - Modèle Attendance
- [ ] **Tâche 4.4.1** : Modifier validation `can_use_free_trial` dans `attendance.rb`
  - **Fichier :** `app/models/attendance.rb`
  - **Ligne :** ~130
  - **Action :** Distinguer vérification parent vs enfant
- [ ] **Tâche 4.4.2** : Vérifier essai par `child_membership_id` si présent
  - **Fichier :** `app/models/attendance.rb`
  - **Action :** Utiliser `child_membership_id` pour grouper les essais par enfant

#### 4.5 Frontend - Formulaire Création Enfant
- [ ] **Tâche 4.5.1** : Ajouter option "Créer sans adhésion (pour essai gratuit)" dans `child_form.html.erb`
  - **Fichier :** `app/views/memberships/child_form.html.erb`
  - **Ligne :** Après boutons submit (~527)
  - **Action :** Ajouter checkbox ou bouton pour créer avec status `trial`
- [ ] **Tâche 4.5.2** : Modifier contrôleur pour accepter création avec status `trial`
  - **Fichier :** `app/controllers/memberships_controller.rb`
  - **Action :** Permettre création membership avec `status: 'trial'` si option cochée

#### 4.6 Frontend - Formulaire Inscription Initiation
- [ ] **Tâche 4.6.1** : Identifier fichier formulaire inscription initiation
  - **Action :** Chercher vue qui affiche formulaire d'inscription
- [ ] **Tâche 4.6.2** : Afficher option essai gratuit si enfant sans adhésion
  - **Fichier :** À déterminer
  - **Action :** Afficher checkbox "Utiliser essai gratuit" si `membership.status == 'trial'`
- [ ] **Tâche 4.6.3** : Gérer soumission avec essai gratuit
  - **Fichier :** Contrôleur attendances
  - **Action :** Créer attendance avec `free_trial_used: true` et `child_membership_id`

#### 4.7 Frontend - Flux Conversion Essai → Adhésion
- [ ] **Tâche 4.7.1** : Ajouter bouton "Adhérer maintenant" sur enfant avec status `trial`
  - **Fichier :** `app/views/memberships/index.html.erb` ou `_membership_card.html.erb`
  - **Action :** Afficher bouton si `membership.status == 'trial'`
- [ ] **Tâche 4.7.2** : Créer action "upgrade" dans contrôleur
  - **Fichier :** `app/controllers/memberships_controller.rb`
  - **Action :** Méthode pour convertir `trial` → `pending` avec paiement
- [ ] **Tâche 4.7.3** : Rediriger vers formulaire paiement après upgrade
  - **Fichier :** `app/controllers/memberships_controller.rb`
  - **Action :** Après upgrade, rediriger vers HelloAsso ou formulaire paiement

### PHASE 5 : TESTS ET VALIDATION

#### 5.1 Tests Scénarios Renouvellement
- [ ] **Tâche 5.1.1** : Test adhésion adulte initiale
  - **Action :** Créer nouvelle adhésion adulte, vérifier flux complet
- [ ] **Tâche 5.1.2** : Test renouvellement adulte depuis historique
  - **Action :** Cliquer "Renouveler" sur adhésion expirée, vérifier pré-remplissage
- [ ] **Tâche 5.1.3** : Test adhésion enfant initiale
  - **Action :** Créer nouvelle adhésion enfant, vérifier flux complet
- [ ] **Tâche 5.1.4** : Test renouvellement enfant
  - **Action :** Cliquer "Réadhérer" sur adhésion expirée, vérifier pré-remplissage
- [ ] **Tâche 5.1.5** : Test cas limites âge (14, 15, 16, 17, 18 ans)
  - **Action :** Tester chaque tranche d'âge, vérifier validations
- [ ] **Tâche 5.1.6** : Test catégories Standard/FFRS avec/sans certificat
  - **Action :** Tester chaque combinaison, vérifier questionnaire santé

#### 5.2 Tests Scénarios Essai Gratuit
- [ ] **Tâche 5.2.1** : Test création enfant sans adhésion (status trial)
  - **Action :** Créer enfant avec option "essai gratuit", vérifier status `trial`
- [ ] **Tâche 5.2.2** : Test inscription initiation avec essai gratuit enfant
  - **Action :** Inscrire enfant `trial` à initiation avec essai gratuit, vérifier `free_trial_used`
- [ ] **Tâche 5.2.3** : Test limite 1 essai gratuit par enfant
  - **Action :** Essayer d'utiliser essai gratuit 2 fois pour même enfant, vérifier blocage
- [ ] **Tâche 5.2.4** : Test plusieurs enfants avec essais gratuits
  - **Action :** Créer 2 enfants `trial`, utiliser essai pour chacun, vérifier indépendance
- [ ] **Tâche 5.2.5** : Test conversion essai → adhésion
  - **Action :** Cliquer "Adhérer maintenant" sur enfant `trial`, vérifier upgrade et paiement

#### 5.3 Tests Validation JavaScript
- [ ] **Tâche 5.3.1** : Test validation téléphone format
  - **Action :** Tester différents formats, vérifier validation
- [ ] **Tâche 5.3.2** : Test validation date de naissance
  - **Action :** Tester dates invalides, vérifier messages d'erreur
- [ ] **Tâche 5.3.3** : Test validation questionnaire santé
  - **Action :** Tester différentes combinaisons, vérifier affichage certificat
- [ ] **Tâche 5.3.4** : Test boutons submit désactivés/activés
  - **Action :** Vérifier que boutons se désactivent correctement selon validation

---

## 📊 RÉSUMÉ DES TÂCHES PAR PRIORITÉ

### Priorité CRITIQUE (15 tâches)
- Phase 1.1 : Unification champs cachés (3 tâches)
- Phase 1.2 : Correction bouton "Espèces/Chèques" (3 tâches)
- Phase 1.3 : Renouvellement adulte complet (5 tâches)
- Phase 5.1 : Tests renouvellement (6 tâches)

### Priorité HAUTE (18 tâches)
- Phase 2.1 : Validation téléphone (5 tâches)
- Phase 2.2 : Questionnaire santé (3 tâches)
- Phase 2.3 : Boutons soumission (3 tâches)
- Phase 2.4 : Validation JavaScript (4 tâches)
- Phase 5.2 : Tests essai gratuit (5 tâches)

### Priorité MOYENNE (10 tâches)
- Phase 3.1 : Sélection catégorie (3 tâches)
- Phase 3.2 : Inférence catégorie (2 tâches)
- Phase 3.3 : Nommage fonctions (3 tâches)
- Phase 3.4 : Callbacks santé (2 tâches)

### Priorité BASSE (12 tâches)
- Phase 4.1-4.7 : Essai gratuit enfants (12 tâches)

**TOTAL : 55 tâches**

---

## 🎯 RECOMMANDATIONS STRATÉGIQUES

### Approche Recommandée

1. **Phase 1 d'abord** : Corriger les problèmes bloquants avant d'ajouter de nouvelles fonctionnalités
2. **Phase 2 ensuite** : Harmoniser pour éviter de nouvelles incohérences
3. **Phase 3 optionnelle** : Améliorations si temps disponible
4. **Phase 4 séparée** : Essai gratuit enfants comme feature séparée (peut être fait en parallèle)
5. **Phase 5 continue** : Tests à chaque phase

### Ordre d'Exécution Suggéré

1. **Sprint 1** : Phase 1.1 + 1.2 (Unification + Correction bouton) - 1-2 jours
2. **Sprint 2** : Phase 1.3 (Renouvellement adulte complet) - 1 jour
3. **Sprint 3** : Phase 2.1 + 2.2 (Téléphone + Santé) - 1 jour
4. **Sprint 4** : Phase 2.3 + 2.4 (Boutons + Validation JS) - 1 jour
5. **Sprint 5** : Phase 3 (Améliorations) - 1 jour
6. **Sprint 6** : Phase 4 (Essai gratuit) - 2-3 jours
7. **Sprint 7** : Phase 5 (Tests complets) - 1-2 jours

**Estimation totale : 8-11 jours de développement**

---

**Date de création :** 2025-01-13  
**Version :** 2.0  
**Statut :** 📋 Analyse complète - Prêt pour implémentation

---

## 🔗 Liens Vers Autres Documents

- 📚 **[Index Documentation](./INDEX-FORMULAIRES-ADHESION.md)** - Vue d'ensemble de tous les documents
- 🗓️ **[Plan de Sprints](./plan-sprints-formulaires-adhesion.md)** - Planning d'exécution avec cases à cocher (55 tâches)
- 🔄 **[Comparatif Initial (v1.0)](./comparatif-formulaires-enfant-adulte.md)** - Section "RENOUVELLEMENT D'ADHÉSION" avec exemples de code détaillés
- 🎁 **[Essai Gratuit Enfants](./ESSAI_GRATUIT_ENFANTS.md)** - Spécification complète de la fonctionnalité (Sprint 6)

---

## 📋 Consolidation des Documents

### Éviter les Doublons

Ce document (v2.0) **remplace et consolide** l'analyse comparative initiale (v1.0) avec :
- ✅ Analyse complète incluant les partials
- ✅ Liens vers fichiers avec numéros de lignes précis
- ✅ Todolist complète de 55 tâches organisées en phases
- ✅ Intégration de l'essai gratuit enfants

**Le document v1.0** (`comparatif-formulaires-enfant-adulte.md`) reste utile uniquement pour :
- Section "RENOUVELLEMENT D'ADHÉSION" avec exemples de code détaillés
- Référence historique de l'analyse initiale

**Pour éviter les doublons :**
- ✅ Utiliser ce document (v2.0) comme référence principale
- ✅ Consulter v1.0 uniquement pour les détails d'implémentation renouvellement adulte
- ✅ Suivre le plan de sprints pour l'exécution
