---
title: "Plan de Test - Parcours Inscription & Profil"
status: "active"
version: "1.0"
created: "2025-11-24"
tags: ["testing", "user-journey", "devise", "registration", "profile"]
---

# Plan de Test - Parcours Inscription & Profil

**Date** : 2025-11-24  
**Branche** : `feature/devise-quick-wins`  
**Objectif** : Valider le parcours complet d'inscription et de modification du profil

---

## 🎯 Scénarios de Test

### 1. Inscription - Cas Nominal ✅

**Prérequis** : Utilisateur non connecté

**Étapes** :
1. Accéder à `/users/sign_up`
2. Remplir le formulaire :
   - Email : `test@example.com`
   - Prénom : `Jean`
   - Mot de passe : `cafe-roller-grenoble` (12+ caractères)
   - Niveau : Sélectionner "Intermédiaire"
   - Cocher "J'accepte les CGU et la Politique"
3. Cliquer sur "Créer mon compte"

**Résultats attendus** :
- ✅ Redirection vers `/events`
- ✅ Message flash : "Bienvenue Jean ! 🎉 Découvrez les événements à venir."
- ✅ Email de bienvenue envoyé (vérifier logs)
- ✅ Email de confirmation envoyé (vérifier logs)
- ✅ Utilisateur connecté automatiquement
- ✅ Accès immédiat au site (période de grâce 2 jours)

**Points de vérification** :
- [ ] Formulaire soumis sans erreur
- [ ] Message de bienvenue personnalisé avec prénom
- [ ] Redirection correcte vers événements
- [ ] Emails envoyés (vérifier `rails console` ou logs)

---

### 2. Inscription - Validation des Erreurs ⚠️

#### 2.1 Email invalide
- **Action** : Saisir `email-invalide`
- **Attendu** : Message d'erreur "Email n'est pas valide"

#### 2.2 Prénom manquant
- **Action** : Laisser prénom vide
- **Attendu** : Message d'erreur "Prénom doit être rempli(e)"

#### 2.3 Mot de passe trop court
- **Action** : Saisir `12345678901` (11 caractères)
- **Attendu** : Message d'erreur "Le mot de passe est trop court (minimum 12 caractères)"

#### 2.4 Niveau non sélectionné
- **Action** : Ne pas sélectionner de niveau
- **Attendu** : Message d'erreur "Niveau doit être rempli(e)"

#### 2.5 Consentement RGPD non coché
- **Action** : Ne pas cocher "J'accepte les CGU et la Politique"
- **Attendu** : Message d'erreur "Vous devez accepter les Conditions Générales d'Utilisation et la Politique de Confidentialité pour créer un compte."

---

### 3. Inscription - Toggle Mot de Passe 👁️

**Étapes** :
1. Saisir un mot de passe
2. Cliquer sur l'icône œil (toggle)

**Résultats attendus** :
- ✅ Le mot de passe devient visible
- ✅ L'icône change (œil → œil barré)
- ✅ `aria-label` mis à jour : "Masquer le mot de passe"
- ✅ `aria-pressed` mis à jour : `true`

---

### 4. Accès Immédiat (Période de Grâce) 🎁

**Prérequis** : Utilisateur inscrit mais email non confirmé

**Étapes** :
1. S'inscrire avec un email valide
2. Ne pas confirmer l'email
3. Naviguer sur le site

**Résultats attendus** :
- ✅ Accès immédiat à toutes les pages publiques
- ✅ Consultation des événements possible
- ✅ Consultation du panier possible
- ⚠️ **Action bloquée** : S'inscrire à un événement → Redirection avec message "Vous devez confirmer votre adresse email"
- ⚠️ **Action bloquée** : Passer une commande → Redirection avec message "Vous devez confirmer votre adresse email"

---

### 5. Profil - Consultation ✅

**Prérequis** : Utilisateur connecté

**Étapes** :
1. Accéder à `/users/edit`
2. Vérifier les champs affichés

**Résultats attendus** :
- ✅ Prénom (obligatoire, pré-rempli)
- ✅ Nom (optionnel, pré-rempli si renseigné)
- ✅ Email (obligatoire, pré-rempli)
- ✅ Téléphone (optionnel, pré-rempli si renseigné)
- ✅ Niveau (obligatoire, cards Bootstrap, pré-sélectionné)
- ✅ Biographie (optionnel, pré-remplie si renseignée)
- ✅ Section "Modifier le mot de passe"
- ✅ Section "Zone de danger" (suppression compte)

---

### 6. Profil - Modification ✅

**Prérequis** : Utilisateur connecté

**Étapes** :
1. Accéder à `/users/edit`
2. Modifier :
   - Nom : `Dupont`
   - Téléphone : `06 12 34 56 78`
   - Niveau : Changer vers "Avancé"
   - Biographie : "Passionné de roller depuis 5 ans"
3. Saisir le mot de passe actuel
4. Cliquer sur "Mettre à jour mon profil"

**Résultats attendus** :
- ✅ Redirection vers `/users/edit` (ou page précédente)
- ✅ Message flash : "Votre compte a été mis à jour avec succès."
- ✅ Modifications sauvegardées en base
- ✅ Affichage mis à jour immédiatement

---

### 7. Profil - Validation des Erreurs ⚠️

#### 7.1 Prénom manquant
- **Action** : Vider le champ prénom
- **Attendu** : Message d'erreur "Prénom doit être rempli(e)"

#### 7.2 Email invalide
- **Action** : Saisir `email-invalide`
- **Attendu** : Message d'erreur "Email n'est pas valide"

#### 7.3 Mot de passe actuel incorrect
- **Action** : Saisir un mauvais mot de passe actuel
- **Attendu** : Message d'erreur "Mot de passe actuel est incorrect"

#### 7.4 Mot de passe actuel manquant
- **Action** : Ne pas saisir le mot de passe actuel
- **Attendu** : Message d'erreur "Mot de passe actuel doit être rempli(e)"

---

### 8. Profil - Skill Level Cards 🎯

**Étapes** :
1. Accéder à `/users/edit`
2. Vérifier l'affichage des cards niveau
3. Cliquer sur une autre card

**Résultats attendus** :
- ✅ 3 cards affichées (Débutant, Intermédiaire, Avancé)
- ✅ Card actuelle pré-sélectionnée (bordure active)
- ✅ Changement de sélection fonctionnel
- ✅ Icônes visibles (person, person-check, trophy)
- ✅ Responsive (3 colonnes sur mobile)

---

### 9. Accessibilité WCAG 2.2 ♿

#### 9.1 Navigation clavier
- **Action** : Naviguer avec Tab dans le formulaire d'inscription
- **Attendu** :
  - ✅ Focus visible (outline 3px)
  - ✅ Ordre logique (Email → Prénom → Password → Niveau → CGU → Submit)
  - ✅ Tous les éléments focusables accessibles

#### 9.2 Erreurs associées
- **Action** : Soumettre formulaire avec erreurs
- **Attendu** :
  - ✅ `aria-describedby` pointe vers les messages d'erreur
  - ✅ `aria-invalid="true"` sur les champs en erreur
  - ✅ Messages d'erreur visibles et lisibles

#### 9.3 Cibles tactiles
- **Vérification** :
  - ✅ Boutons ≥ 44×44px
  - ✅ Checkboxes ≥ 24×24px
  - ✅ Liens avec padding suffisant

---

### 10. Responsive Design 📱

**Étapes** :
1. Tester sur mobile (375px)
2. Tester sur tablette (768px)
3. Tester sur desktop (1920px)

**Résultats attendus** :
- ✅ Formulaire d'inscription centré et lisible
- ✅ Skill level cards : 3 colonnes sur mobile, responsive
- ✅ Boutons accessibles (taille tactile suffisante)
- ✅ Pas de débordement horizontal

---

## 🐛 Bugs Connus / À Vérifier

- [ ] Vérifier que les emails sont bien envoyés (config SMTP)
- [ ] Vérifier que la période de grâce fonctionne (2 jours)
- [ ] Vérifier que la confirmation email bloque bien les actions critiques
- [ ] Vérifier que le toggle password fonctionne sur tous les navigateurs

---

## ✅ Checklist Finale

### Inscription
- [ ] Formulaire fonctionnel (4 champs)
- [ ] Validation côté client (HTML5)
- [ ] Validation côté serveur (Rails)
- [ ] Messages d'erreur clairs
- [ ] Redirection après inscription
- [ ] Email de bienvenue envoyé
- [ ] Email de confirmation envoyé
- [ ] Accès immédiat (période de grâce)

### Profil
- [ ] Affichage correct des champs
- [ ] Modification fonctionnelle
- [ ] Validation des erreurs
- [ ] Skill level cards fonctionnelles
- [ ] Redirection après modification

### Accessibilité
- [ ] WCAG 2.2 (AA) conforme
- [ ] Navigation clavier fonctionnelle
- [ ] Erreurs associées aux champs
- [ ] Cibles tactiles suffisantes

### Responsive
- [ ] Mobile (375px)
- [ ] Tablette (768px)
- [ ] Desktop (1920px)

---

**Dernière mise à jour** : 2025-11-24

