# 🎨 LIQUID GLASS - Harmonisation Admin Panel

**Date** : 2025-01-XX | **Version** : 1.0

---

## 📋 Vue d'Ensemble

Guide pour harmoniser le design **Liquid Glass** du site principal avec le **Panel Admin**.

**Objectif** : Appliquer les mêmes classes CSS liquid glass dans toutes les vues admin pour un design cohérent.

---

## 🎯 Classes CSS à Utiliser

### **Cards (Cartes)**

**Remplacement** :
```erb
<!-- ❌ AVANT -->
<div class="card">
  <div class="card-body">...</div>
</div>

<!-- ✅ APRÈS -->
<div class="card card-liquid rounded-liquid shadow-liquid">
  <div class="card-body">...</div>
</div>
```

**Avec header coloré** :
```erb
<!-- ✅ Header primary (bleu) -->
<div class="card card-liquid-primary rounded-liquid shadow-liquid">
  <div class="card-header">
    <h5>Titre</h5>
  </div>
  <div class="card-body">...</div>
</div>
```

---

### **Buttons (Boutons)**

**Remplacement** :
```erb
<!-- ❌ AVANT -->
<%= link_to "Action", path, class: "btn btn-primary" %>
<%= link_to "Action", path, class: "btn btn-outline-primary" %>

<!-- ✅ APRÈS -->
<%= link_to "Action", path, class: "btn btn-liquid-primary" %>
<%= link_to "Action", path, class: "btn btn-outline-liquid-primary" %>
```

**Classes disponibles** :
- `btn-liquid-primary` - Bouton principal (gradient bleu)
- `btn-liquid-success` - Bouton succès (gradient vert)
- `btn-liquid-danger` - Bouton danger (gradient rouge)
- `btn-outline-liquid-primary` - Outline principal
- `btn-outline-liquid-success` - Outline succès
- `btn-outline-liquid-danger` - Outline danger

---

### **Badges**

**Remplacement** :
```erb
<!-- ❌ AVANT -->
<span class="badge bg-primary">Statut</span>
<span class="badge bg-success">Actif</span>
<span class="badge bg-danger">Erreur</span>
<span class="badge bg-secondary">Secondaire</span>

<!-- ✅ APRÈS -->
<span class="badge badge-liquid-primary">Statut</span>
<span class="badge badge-liquid-success">Actif</span>
<span class="badge badge-liquid-danger">Erreur</span>
<span class="badge badge-liquid-secondary">Secondaire</span>
```

**Classes disponibles** :
- `badge-liquid-primary` - Badge principal
- `badge-liquid-success` - Badge succès
- `badge-liquid-danger` - Badge danger
- `badge-liquid-secondary` - Badge secondaire

---

### **Alerts (Alertes)**

**Remplacement** :
```erb
<!-- ❌ AVANT -->
<div class="alert alert-success">Message</div>
<div class="alert alert-danger">Erreur</div>

<!-- ✅ APRÈS -->
<div class="alert alert-liquid-success">Message</div>
<div class="alert alert-liquid-danger">Erreur</div>
```

**Classes disponibles** :
- `alert-liquid-primary` - Alerte info
- `alert-liquid-success` - Alerte succès
- `alert-liquid-warning` - Alerte avertissement
- `alert-liquid-danger` - Alerte erreur

---

### **Forms (Formulaires)**

**Remplacement** :
```erb
<!-- ❌ AVANT -->
<%= f.text_field :name, class: "form-control" %>
<%= f.select :status, options, {}, { class: "form-select" } %>

<!-- ✅ APRÈS -->
<%= f.text_field :name, class: "form-control form-control-liquid" %>
<%= f.select :status, options, {}, { class: "form-select form-control-liquid" } %>
```

**Classe** : `form-control-liquid` (glassmorphism avec blur)

---

### **Text Colors (Couleurs de texte)**

**Remplacement** :
```erb
<!-- ❌ AVANT -->
<span class="text-primary">Texte</span>
<span class="text-success">Texte</span>

<!-- ✅ APRÈS -->
<span class="text-liquid-primary">Texte</span>
<span class="text-liquid-success">Texte</span>
```

**Classes disponibles** :
- `text-liquid-primary` - Texte bleu
- `text-liquid-success` - Texte vert
- `text-liquid-danger` - Texte rouge
- `text-liquid-warning` - Texte orange
- `text-liquid-info` - Texte cyan

---

### **Shadows (Ombres)**

**Remplacement** :
```erb
<!-- ❌ AVANT -->
<div class="card shadow-sm">...</div>
<div class="card shadow">...</div>

<!-- ✅ APRÈS -->
<div class="card shadow-liquid">...</div>
<div class="card shadow-liquid-lg">...</div>
```

**Classes disponibles** :
- `shadow-liquid` - Ombre légère
- `shadow-liquid-lg` - Ombre grande

---

### **Rounded (Bordures arrondies)**

**Remplacement** :
```erb
<!-- ❌ AVANT -->
<div class="card rounded">...</div>
<div class="card rounded-lg">...</div>

<!-- ✅ APRÈS -->
<div class="card rounded-liquid">...</div>
<div class="card rounded-liquid-lg">...</div>
```

**Classes disponibles** :
- `rounded-liquid` - Border-radius 1.6rem
- `rounded-liquid-lg` - Border-radius 2.4rem

---

## 📝 Checklist d'Harmonisation

### **Vues à Mettre à Jour**

- [x] `dashboard/index.html.erb` - Cards liquid ✅
- [x] `initiations/index.html.erb` - Cards + buttons + badges ✅
- [ ] `initiations/show.html.erb` - Cards + buttons + badges
- [ ] `initiations/presences.html.erb` - Cards + buttons
- [x] `orders/index.html.erb` - Cards + buttons + badges ✅
- [x] `orders/show.html.erb` - Cards + buttons + badges ✅
- [x] `products/index.html.erb` - Cards + buttons + badges ✅
- [ ] `products/show.html.erb` - Cards + buttons + badges
- [ ] `products/_form.html.erb` - Forms + alerts
- [ ] `roller_stocks/index.html.erb` - Cards + buttons
- [ ] `roller_stocks/show.html.erb` - Cards + buttons
- [ ] `roller_stocks/new.html.erb` - Forms + alerts
- [ ] `roller_stocks/edit.html.erb` - Forms + alerts
- [ ] `product_variants/new.html.erb` - Forms + alerts
- [ ] `product_variants/edit.html.erb` - Forms + alerts

### **Helpers Mis à Jour**

- [x] `AdminPanel::OrdersHelper#status_badge()` - Badges liquid glass pour statuts commandes ✅
- [x] `AdminPanel::ProductsHelper#active_badge()` - Badge liquid glass pour actif/inactif ✅
- [x] `AdminPanel::ProductsHelper#stock_badge()` - Badge liquid glass pour stock ✅

---

## 🎨 Exemples Complets

### **Dashboard avec Cards Liquid**

```erb
<div class="row g-3 mb-4">
  <div class="col-md-6 col-lg-3">
    <div class="card card-liquid rounded-liquid shadow-liquid">
      <div class="card-body">
        <h5 class="card-title text-muted">Utilisateurs</h5>
        <h3 class="mb-0">25</h3>
      </div>
    </div>
  </div>
</div>
```

### **Formulaire avec Liquid Glass**

```erb
<div class="card card-liquid rounded-liquid shadow-liquid mb-4">
  <div class="card-body">
    <%= form_with model: @product, class: "row g-3" do |f| %>
      <div class="col-md-6">
        <%= f.label :name, class: "form-label" %>
        <%= f.text_field :name, class: "form-control form-control-liquid" %>
      </div>
      <div class="col-12">
        <%= f.submit "Enregistrer", class: "btn btn-liquid-primary" %>
        <%= link_to "Annuler", path, class: "btn btn-outline-liquid-primary" %>
      </div>
    <% end %>
  </div>
</div>
```

### **Table avec Badges Liquid**

```erb
<div class="card card-liquid rounded-liquid shadow-liquid">
  <div class="card-body">
    <table class="table table-hover">
      <tbody>
        <tr>
          <td>Statut</td>
          <td>
            <span class="badge badge-liquid-success">Actif</span>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</div>
```

---

## 🔧 Variables CSS Disponibles

Toutes les variables liquid glass sont disponibles via `_style.scss` :

```scss
--liquid-glass-bg          // Background glassmorphism
--liquid-glass-border      // Border glassmorphism
--liquid-blur              // Blur effect (blur(12px))
--gradient-liquid-primary  // Gradient bleu
--gradient-liquid-success  // Gradient vert
--gradient-liquid-danger   // Gradient rouge
--transition-liquid        // Transition 300ms ease
--transition-liquid-fast   // Transition 200ms ease
--shadow-liquid            // Ombre légère
--shadow-liquid-lg         // Ombre grande
```

---

## ✅ Résultat Attendu

Après harmonisation, le Panel Admin aura :
- ✅ **Même design** que le site principal
- ✅ **Glassmorphism** cohérent partout
- ✅ **Transitions fluides** identiques
- ✅ **Couleurs harmonisées** (liquid primary, success, danger)
- ✅ **Ombres et bordures** arrondies cohérentes

---

**Retour** : [INDEX principal](./INDEX.md) | [Sidebar](./00-dashboard/sidebar.md)
