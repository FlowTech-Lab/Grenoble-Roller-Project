# 6. Gestion Enfants Multiples

[← Retour à l'index](index.md)

### 6.1. Fonctionnement du Formulaire

Le formulaire d'inscription permet d'inscrire **un seul enfant à la fois** via un dropdown :

```erb
<%= form.collection_select :child_membership_id, 
    child_memberships, 
    :id, 
    ->(m) { "#{m.child_first_name} #{m.child_last_name}" }, 
    { prompt: "Sélectionner un enfant" } %>
```

**Caractéristiques** :
- Un seul enfant peut être sélectionné par soumission
- Chaque enfant a son propre essai gratuit (indépendant)
- Le parent peut soumettre plusieurs fois pour inscrire plusieurs enfants

### 6.2. Calcul de Disponibilité Essai Gratuit

**Règle métier** : Tous les enfants créés ont automatiquement un essai gratuit disponible (implicite).

**Pour chaque enfant dans le dropdown** :

```ruby
# app/views/shared/_registration_form_fields.html.erb
# IMPORTANT : Utiliser .active pour exclure les attendances annulées
trial_children = child_memberships.select { |m| m.trial? || m.pending? }
trial_children_data = trial_children.map do |child|
  {
    id: child.id,
    name: "#{child.child_first_name} #{child.child_last_name}",
    status: child.status,  # "trial" ou "pending"
    has_used_trial: current_user.attendances.active
      .where(free_trial_used: true, child_membership_id: child.id)
      .exists?,
    can_use_trial: !current_user.attendances.active
      .where(free_trial_used: true, child_membership_id: child.id)
      .exists?
  }
end.to_json  # Convertir en JSON string pour injection dans JavaScript
```

**Passage des données au JavaScript** :
```erb
<!-- app/views/shared/_registration_form_fields.html.erb -->
<% if show_free_trial_children %>
  <script>
    // Données des enfants avec statut trial/pending
    // trial_children_data est déjà un JSON string (appel à .to_json dans le Ruby)
    const trialChildrenData<%= prefix_id %> = <%= raw trial_children_data %>;
    
    // Exemple de données injectées :
    // const trialChildrenData = [
    //   { id: 123, name: "Alice Dupont", status: "pending", has_used_trial: false, can_use_trial: true },
    //   { id: 124, name: "Bob Dupont", status: "trial", has_used_trial: false, can_use_trial: true }
    // ];
  </script>
<% end %>
```

**Logique** :
- Chaque enfant est vérifié indépendamment
- Si un enfant a utilisé son essai gratuit (attendance active), `has_used_trial = true`
- Si un enfant n'a pas utilisé son essai gratuit, `can_use_trial = true`

**Affichage dans le dropdown** :
```
Parent voit :
[ ] Enfant A (pending) - Essai disponible (optionnel)
[ ] Enfant B (trial) - Essai disponible (obligatoire)
[ ] Enfant C (pending) - Essai utilisé (déjà inscrit à Initiation 1)
```

**Texte affiché différemment selon le statut** :
- Si `status = "pending"` et `can_use_trial = true` : 
  - Checkbox affichée avec texte "Utiliser l'essai gratuit de [Nom Enfant]" (optionnel, pas cochée par défaut)
- Si `status = "trial"` et `can_use_trial = true` : 
  - Checkbox affichée avec texte "Utiliser l'essai gratuit de [Nom Enfant]" (obligatoire, cochée par défaut, `required = true`)
- Si `has_used_trial = true` : 
  - Checkbox masquée (essai déjà utilisé)

**Code HTML réel complet** :
```erb
<!-- app/views/shared/_registration_form_fields.html.erb -->
<% if show_free_trial_parent || show_free_trial_children %>
  <%# Champ caché pour garantir l'envoi de la valeur même si la checkbox est masquée %>
  <%= hidden_field_tag "use_free_trial_hidden#{prefix_id}", "0", id: "use_free_trial_hidden#{prefix_id}" %>
  
  <div class="mb-3 form-check" id="free_trial_container<%= prefix_id %>" style="<%= show_free_trial_parent || (show_free_trial_children && child_memberships.any? { |m| m.trial? }) ? '' : 'display: none;' %>">
    <!-- Checkbox essai gratuit -->
    <%= check_box_tag :use_free_trial, "1", false, { 
        class: "form-check-input", 
        id: "use_free_trial#{prefix_id}",
        aria: { describedby: "free_trial_help#{prefix_id}" },
        onchange: "window.toggleSubmitButton#{prefix_id} && window.toggleSubmitButton#{prefix_id}(); if (this.checked) { document.getElementById('use_free_trial_hidden#{prefix_id}').value = '1'; } else { document.getElementById('use_free_trial_hidden#{prefix_id}').value = '0'; }"
    } %>
    
    <%= label_tag "use_free_trial#{prefix_id}", class: "form-check-label", id: "use_free_trial_label#{prefix_id}" do %>
      <i class="bi bi-gift me-1" aria-hidden="true"></i>
      <span id="free_trial_text<%= prefix_id %>">Utiliser mon essai gratuit</span>
    <% end %>
    
    <small id="free_trial_help<%= prefix_id %>" class="text-muted d-block mt-1">
      <span id="free_trial_help_text<%= prefix_id %>">
        <% if is_initiation && event.allow_non_member_discovery? %>
          Vous pouvez utiliser votre essai gratuit maintenant ou vous inscrire dans les places découverte disponibles. Après cet essai, une adhésion sera requise pour continuer.
        <% else %>
          Vous n'avez pas encore utilisé votre essai gratuit. <strong>Cette case doit être cochée pour confirmer votre inscription.</strong> Après cet essai, une adhésion sera requise pour continuer.
        <% end %>
      </span>
    </small>
  </div>
  
  <% if show_free_trial_children %>
    <script>
      // Données des enfants avec statut trial/pending (déjà en JSON string)
      const trialChildrenData<%= prefix_id %> = <%= raw trial_children_data %>;
      
      // Le JavaScript met à jour dynamiquement le texte et l'état de la checkbox
      // selon l'enfant sélectionné (voir fonction updateFreeTrialDisplay)
    </script>
  <% end %>
<% end %>
```

**JavaScript qui gère l'affichage différencié** :
```javascript
// Pour enfant pending : checkbox optionnelle
if (selectedChild.status === "pending" && !selectedChild.has_used_trial) {
  freeTrialText.textContent = 'Utiliser l\'essai gratuit de ' + childNameEscaped;
  freeTrialHelpText.innerHTML = '<strong>Essai gratuit pour ' + childNameEscaped + ' :</strong> Cet enfant peut utiliser son essai gratuit pour cette initiation. <strong>Cette case est optionnelle.</strong> Après cet essai, une adhésion sera requise pour continuer.';
  if (freeTrialCheckbox) {
    freeTrialCheckbox.checked = false; // Pas cochée par défaut
    freeTrialCheckbox.required = false; // Pas obligatoire
  }
}

// Pour enfant trial : checkbox obligatoire
if (selectedChild.status === "trial" && !selectedChild.has_used_trial) {
  freeTrialText.textContent = 'Utiliser l\'essai gratuit de ' + childNameEscaped;
  freeTrialHelpText.innerHTML = '<strong>Essai gratuit pour ' + childNameEscaped + ' :</strong> Cet enfant peut utiliser son essai gratuit pour cette initiation. <strong>Cette case doit être cochée pour confirmer l\'inscription.</strong> Après cet essai, une adhésion sera requise pour continuer.';
  if (freeTrialCheckbox) {
    freeTrialCheckbox.checked = true; // Cochée par défaut
    freeTrialCheckbox.required = true; // Obligatoire
  }
}
```

### 6.3. Scénarios Multi-Enfants

#### Scénario 1 : Trois Enfants, Deux avec Essai Disponible

**Timeline** :
```
T0: Parent crée 3 enfants
    BD: memberships = [
      membership_A (status: "pending"),
      membership_B (status: "pending"),
      membership_C (status: "pending")
    ]
    BD: attendances = []

T1: Parent inscrit Enfant B à Initiation 1
    BD: attendances = [attendance_B1 (free_trial_used: true, child_membership_id: B.id)]

T2: Parent voit dropdown :
    - Enfant A : Essai disponible (can_use_trial = true)
    - Enfant B : Essai utilisé (has_used_trial = true)
    - Enfant C : Essai disponible (can_use_trial = true)

T3: Parent peut inscrire Enfant A et Enfant C (deux soumissions séparées)
```

**Résultat** : Parent peut inscrire Enfant A et Enfant C (deux soumissions séparées)

#### Scénario 2 : Tous les Enfants ont Utilisé leur Essai

**Timeline** :
```
T0: Parent crée 3 enfants
    BD: memberships = [A, B, C] (tous pending)
    BD: attendances = []

T1: Parent inscrit tous les enfants
    BD: attendances = [
      attendance_A1 (free_trial_used: true, child_membership_id: A.id),
      attendance_B1 (free_trial_used: true, child_membership_id: B.id),
      attendance_C1 (free_trial_used: true, child_membership_id: C.id)
    ]

T2: Parent voit dropdown :
    - Tous les enfants : Essai utilisé (has_used_trial = true pour tous)
    - Checkbox essai gratuit : Masquée
    - Message : "Adhésion requise pour continuer"
```

**Résultat** : Aucun enfant n'a d'essai disponible, message "Adhésion requise"

#### Scénario 3 : Parent a Utilisé son Essai, Enfants Non

**Timeline** :
```
T0: Parent crée 2 enfants
    BD: memberships = [A, B] (tous pending)
    BD: attendances = []

T1: Parent s'inscrit lui-même à Initiation 1 (utilise son essai)
    BD: attendances = [attendance_parent (free_trial_used: true, child_membership_id: nil)]

T2: Parent voit dropdown :
    - Enfant A : Essai disponible (can_use_trial = true)
    - Enfant B : Essai disponible (can_use_trial = true)
    - Checkbox essai gratuit parent : Masquée (déjà utilisé)
```

**Résultat** : Enfants peuvent utiliser leur essai indépendamment du parent

---

---

**Navigation** :
- [← Section précédente](05-cas-limites.md)
- [← Retour à l'index](index.md)
- [→ Section suivante](07-cycle-vie-statuts.md)
