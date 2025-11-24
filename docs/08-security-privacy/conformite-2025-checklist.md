---
title: "Checklist Conformité 2025 - Formulaire Inscription"
status: "active"
version: "1.0"
created: "2025-01-21"
tags: ["accessibility", "wcag", "security", "rgpd", "ux", "conformity"]
---

# Checklist de Conformité 2025 - Formulaire d'Inscription

**Date** : 2025-01-21  
**Branche** : `feature/devise-quick-wins`  
**Status** : En cours d'implémentation

---

## 📋 WCAG 2.2 (AA) - Accessibilité

### ✅ 2.5.8 - Cibles tactiles ≥ 24×24px
- [x] **Boutons** : Minimum 44×44px (recommandé) ou 24×24px minimum
- [x] **Liens** : Padding suffisant pour zone tactile ≥ 24×24px
- [ ] **Checkboxes/Radios** : Zone tactile ≥ 24×24px
- [ ] **Icônes** : Zone tactile ≥ 24×24px avec padding

**Action** : Vérifier et ajuster les styles CSS pour tous les éléments interactifs.

### ✅ 2.4.11 - Focus clairement visible
- [x] **Outline** : Minimum 2px, contraste ≥ 3:1 avec le fond
- [x] **Focus visible** : Outline visible sur tous les éléments focusables
- [ ] **Focus-visible** : Utiliser `:focus-visible` pour navigation clavier uniquement

**Action** : Vérifier tous les états `:focus` et `:focus-visible`.

### ✅ 3.3.7 - Pas de redondance d'entrée
- [x] **Confirmation mot de passe** : Remplacé par toggle "Afficher/Masquer" ✅
- [x] **Validation temps réel** : Feedback visuel immédiat (indicateur force) ✅
- [x] **Indicateur force** : Déjà implémenté ✅

**Status** : ✅ Implémenté - Toggle show/hide créé avec `password_toggle_controller.js`

### ✅ 3.3.1 - Erreurs associées aux champs
- [x] **aria-describedby** : Erreurs liées aux champs concernés ✅
- [x] **aria-invalid** : Champs marqués en erreur ✅
- [x] **IDs uniques** : Chaque erreur a un ID unique ✅

**Status** : ✅ Implémenté - Tous les champs ont aria-describedby et aria-invalid

### ✅ 3.2.6 - Aide cohérente
- [x] **Placeholders** : Cohérents et informatifs
- [x] **Labels** : Toujours présents et associés
- [x] **Aide contextuelle** : Textes d'aide cohérents

---

## 🔒 Sécurité

### ✅ Mot de passe ≥ 14-16 caractères
- [x] **Minimum** : Passé de 6 à 14 caractères minimum ✅
- [x] **Recommandation** : Message utilisateur "Minimum 14 caractères recommandés" ✅
- [x] **Message utilisateur** : Mis à jour dans formulaire et traductions ✅

**Status** : ✅ Implémenté - `config.password_length = 14..128` dans `devise.rb`

### ⏳ Vérification contre bases de fuites (Pwned Passwords)
- [ ] **Gem** : `pwned` ou `have_i_been_pwned`
- [ ] **Validation** : Vérifier mot de passe contre base Have I Been Pwned
- [ ] **Message** : "Ce mot de passe a été compromis dans une fuite de données"

**Action** : Ajouter gem et validation (optionnel mais recommandé).

### ⏳ MFA proposé (au moins recommandé)
- [ ] **Recommandation** : Message informatif sur MFA
- [ ] **Future** : Implémentation MFA complète (TOTP/SMS)

**Action** : Ajouter message informatif (implémentation future).

### ✅ Rate limiting implémenté côté serveur
- [x] **Gem** : `rack-attack` ajouté au Gemfile ✅
- [x] **Limites** : 5 tentatives/connexion par IP/15min ✅
- [x] **Limites** : 3 inscriptions par IP/heure ✅
- [x] **Limites** : 3 reset password par IP/heure ✅
- [x] **Protection DDoS** : 300 requêtes/IP/minute ✅

**Status** : ✅ Implémenté - `config/initializers/rack_attack.rb` créé

---

## 📱 UX/Mobile

### 🔄 Multi-step form pour 8+ champs
- [ ] **Étape 1** : Identité (Prénom, Nom, Email, Téléphone)
- [ ] **Étape 2** : Sécurité (Mot de passe, Toggle show/hide)
- [ ] **Étape 3** : Profil (Bio)
- [ ] **Navigation** : Boutons Précédent/Suivant
- [ ] **Indicateur** : Barre de progression

**Action** : Créer formulaire multi-étapes avec Stimulus.

### ✅ Validation temps réel avec feedback visuel
- [x] **Indicateur force** : Déjà implémenté ✅
- [ ] **Validation email** : Format valide en temps réel
- [ ] **Validation téléphone** : Format valide en temps réel
- [ ] **Feedback immédiat** : Messages d'erreur avant soumission

**Action** : Améliorer validation temps réel.

### ✅ Types d'input HTML5 optimisés
- [x] **Email** : `type="email"` ✅
- [x] **Téléphone** : `type="tel"` + `inputmode="tel"` ✅
- [x] **Prénom/Nom** : `autocomplete="given-name"` / `autocomplete="family-name"` ✅
- [x] **Mot de passe** : `autocomplete="new-password"` ✅

**Status** : ✅ Implémenté - Tous les attributs HTML5 optimisés

### ✅ Autofill compatible (autocomplete complet)
- [x] **Email** : `autocomplete="email"` ✅
- [x] **Mot de passe** : `autocomplete="new-password"` ✅
- [x] **Prénom** : `autocomplete="given-name"` ✅
- [x] **Nom** : `autocomplete="family-name"` ✅
- [x] **Téléphone** : `autocomplete="tel"` ✅

**Status** : ✅ Implémenté - Tous les attributs autocomplete configurés

---

## 📜 RGPD

### ✅ Consentement explicite (CGU + politique)
- [x] **Checkbox obligatoire** : "J'accepte les CGU et la Politique de Confidentialité" ✅
- [x] **Liens** : Vers `/cgu` et `/politique-confidentialite` (ouvrent dans nouvel onglet) ✅
- [x] **Validation** : Impossible de s'inscrire sans accepter ✅
- [x] **Message erreur** : Affiché si non coché ✅

**Status** : ✅ Implémenté - Checkbox avec validation dans `RegistrationsController`

### ✅ Opt-in newsletter séparé
- [x] **Checkbox séparée** : "Je souhaite recevoir la newsletter" (non obligatoire) ✅
- [x] **RGPD** : Checkbox séparée et clairement identifiée comme optionnelle ✅
- [ ] **Future** : Implémentation newsletter complète avec double opt-in

**Status** : ✅ Checkbox ajoutée (implémentation backend future)

### ✅ Transparence collecte données
- [x] **Politique** : Page `/politique-confidentialite` créée ✅
- [x] **CGU** : Page `/cgu` créée ✅
- [x] **Lien visible** : Dans le formulaire d'inscription (checkbox consentement) ✅

**Status** : ✅ Implémenté - Liens vers CGU et Politique dans checkbox consentement

---

## 📊 Priorités d'Implémentation

### 🔴 Priorité Haute (Conformité légale) - ✅ TERMINÉ
1. ✅ WCAG 2.2 - Cibles tactiles ≥ 24×24px ✅
2. ✅ WCAG 2.2 - Focus visible ✅
3. ✅ WCAG 2.2 - Erreurs associées (aria-describedby) ✅
4. ✅ RGPD - Consentement explicite CGU ✅
5. ✅ Sécurité - Mot de passe ≥ 14 caractères ✅

### 🟡 Priorité Moyenne (Meilleure UX) - ✅ TERMINÉ
6. ✅ WCAG 2.2 - Remplacer confirmation par toggle ✅
7. ⏳ UX - Multi-step form (optionnel, 8 champs gérés en 1 page)
8. ✅ UX - Types input HTML5 optimisés ✅
9. ✅ Sécurité - Rate limiting ✅

### 🟢 Priorité Basse (Améliorations futures)
10. ⏳ Sécurité - Pwned Passwords (optionnel)
11. ⏳ Sécurité - MFA recommandé (futur)
12. ✅ RGPD - Newsletter opt-in ✅

---

## 📝 Notes Techniques

### Dépendances à ajouter
- `rack-attack` : Rate limiting
- `pwned` (optionnel) : Vérification mots de passe compromis

### Fichiers à modifier
- `app/views/devise/registrations/new.html.erb` : Formulaire multi-étapes
- `app/javascript/controllers/password_strength_controller.js` : Toggle show/hide
- `app/assets/stylesheets/_style.scss` : Styles conformité WCAG
- `config/initializers/devise.rb` : Longueur mot de passe
- `config/initializers/rack_attack.rb` : Rate limiting
- `app/models/user.rb` : Validation RGPD consentement

---

**Dernière mise à jour** : 2025-01-21

