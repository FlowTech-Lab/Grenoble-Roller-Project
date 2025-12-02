# Adhésions - Règles Questionnaire de Santé par Catégorie

**Date** : 2025-01-30  
**Status** : ✅ Implémenté

---

## 📋 RÈGLES IMPLÉMENTÉES

### **ADHÉSION STANDARD (10€)**

**Comportement** :
- ✅ Questionnaire présent (9 questions)
- ✅ Pas obligatoire de tout cocher "NON" pour continuer
- ✅ Juste demander de répondre honnêtement
- ✅ Si réponse "OUI" → Pas d'upload certificat obligatoire
- ✅ Affichage : "Consultez votre médecin avant de pratiquer"

**Validation** :
- Aucune validation stricte
- Pas de blocage si certificat non fourni
- Message informatif seulement

---

### **LICENCE FFRS (56.55€)**

**Comportement** :
- ✅ Questionnaire OBLIGATOIRE (toutes les questions doivent être répondues)
- ✅ Si toutes réponses "NON" → Génération attestation automatique (si renouvellement)
- ✅ Si au moins 1 "OUI" → Upload certificat OBLIGATOIRE
- ✅ Si nouvelle licence FFRS → Upload certificat OBLIGATOIRE (même si toutes réponses NON)

**Validation** :
- Toutes les questions doivent être répondues
- Si réponse "OUI" → Certificat obligatoire (bloque la soumission)
- Si nouvelle licence FFRS → Certificat obligatoire même si toutes réponses NON (bloque la soumission)
- Si renouvellement FFRS avec toutes réponses NON → Attestation auto générée (TODO)

---

## 🔧 IMPLÉMENTATION TECHNIQUE

### **Formulaires (adult_form.html.erb et child_form.html.erb)**

**Modifications** :
- Messages d'introduction adaptés selon la catégorie
- Messages d'alerte différents pour Standard vs FFRS
- Upload certificat affiché uniquement pour FFRS avec réponse OUI
- Message de recommandation pour Standard avec réponse OUI

**JavaScript** :
- Fonction `checkHealthQuestions()` adaptée pour détecter la catégorie
- Affichage/masquage dynamique selon Standard/FFRS
- Validation conditionnelle du champ certificat

---

### **Controller (memberships_controller.rb)**

**Méthodes modifiées** :
- `create_adult_membership` : Validation selon catégorie avant création
- `create_child_membership_from_params` : Validation selon catégorie avant création
- `update` : Validation selon catégorie lors de la mise à jour

**Logique de validation** :

```ruby
if is_ffrs
  if has_health_issue
    # Certificat obligatoire
  elsif all_answered_no
    # Vérifier si nouvelle licence FFRS
    if !previous_ffrs
      # Certificat obligatoire même si toutes NON
    else
      # Attestation auto (TODO)
    end
  else
    # Bloque : toutes questions doivent être répondues
  end
else
  # STANDARD : Pas de validation stricte
end
```

---

## 📝 TODO

### **Génération Attestation Automatique FFRS**

**À implémenter** :
- Générer un PDF d'attestation de santé automatique
- Stocker dans Active Storage
- Envoyer par email à l'adhérent
- Disponible dans ActiveAdmin

**Conditions** :
- Licence FFRS
- Toutes réponses "NON"
- Renouvellement (pas nouvelle licence)

**Complexité estimée** : 4h (génération PDF + email)

---

## ✅ TESTS À EFFECTUER

### **Adhésion Standard**
- [ ] Répondre à toutes les questions "NON" → Doit pouvoir continuer
- [ ] Répondre à au moins une question "OUI" → Message recommandation affiché
- [ ] Ne pas répondre à toutes les questions → Doit pouvoir continuer
- [ ] Soumettre sans certificat → Doit fonctionner

### **Licence FFRS**
- [ ] Répondre à toutes les questions "NON" (nouvelle licence) → Certificat obligatoire
- [ ] Répondre à toutes les questions "NON" (renouvellement) → Attestation auto (TODO)
- [ ] Répondre à au moins une question "OUI" → Certificat obligatoire
- [ ] Ne pas répondre à toutes les questions → Bloque la soumission
- [ ] Soumettre sans certificat (si requis) → Bloque la soumission

---

**Date de création** : 2025-01-30  
**Dernière mise à jour** : 2025-01-30

