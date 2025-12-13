---
title: "Gestion du Stock de Rollers (RollerStock) - Grenoble Roller"
status: "active"
version: "1.0"
created: "2025-01-30"
updated: "2025-01-30"
tags: ["roller-stock", "equipment", "inventory", "initiations"]
---

# Gestion du Stock de Rollers (RollerStock)

**Dernière mise à jour** : 2025-01-30

Ce document décrit le système de gestion de l'inventaire des rollers en prêt pour les initiations et événements.

---

## 📋 Vue d'Ensemble

Le modèle `RollerStock` permet de gérer l'inventaire des rollers disponibles en prêt pour les participants aux initiations et événements. Chaque taille de roller a une quantité disponible qui peut être suivie et mise à jour.

### Cas d'Usage

- **Initiations** : Prêt de rollers aux participants qui n'ont pas leur propre équipement
- **Événements** : Prêt ponctuel de rollers si nécessaire
- **Gestion admin** : Suivi des stocks, activation/désactivation de tailles

---

## 🏗️ Modèle : `RollerStock`

**Fichier** : `app/models/roller_stock.rb`

### Attributs

| Attribut | Type | Description |
|----------|------|-------------|
| `size` | string | Taille du roller (en EU : 28 à 48) |
| `quantity` | integer | Quantité disponible (>= 0) |
| `is_active` | boolean | Taille activée/désactivée |

### Constantes

```ruby
SIZES = %w[28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48].freeze
```

**Tailles supportées** : 28 à 48 (système de pointure européenne)

### Validations

- `size` : présence, unicité, inclusion dans `SIZES`
- `quantity` : présence, >= 0, entier
- `is_active` : inclusion dans `[true, false]`

### Scopes

- `active` : Tailles actives (`is_active = true`)
- `available` : Tailles actives avec stock > 0
- `ordered_by_size` : Tri par taille numérique (ordre croissant)

### Méthodes

#### Instance

- `available?` : Retourne `true` si actif et quantité > 0
- `out_of_stock?` : Retourne `true` si quantité <= 0
- `size_with_stock` : Format "XX (Y disponible(s))" pour affichage

#### Classe

- `ransackable_attributes` : Attributs recherchables (ActiveAdmin)
- `ransackable_associations` : Associations recherchables (aucune)

### Hashid

Le modèle utilise `include Hashid::Rails` pour générer des identifiants URL-friendly.

---

## 🔗 Intégration avec Attendance et WaitlistEntry

### Validation des Tailles

Les modèles `Attendance` et `WaitlistEntry` utilisent `RollerStock::SIZES` pour valider les tailles :

```ruby
# Dans Attendance
validates :roller_size, presence: true, if: :needs_equipment?
validates :roller_size, inclusion: { in: RollerStock::SIZES }, if: :needs_equipment?

# Dans WaitlistEntry
validates :roller_size, presence: true, if: :needs_equipment?
validates :roller_size, inclusion: { in: RollerStock::SIZES }, if: :needs_equipment?
```

### Champ `needs_equipment`

Dans les formulaires d'inscription :

- Si `needs_equipment = true` → `roller_size` est obligatoire
- `roller_size` doit être dans `RollerStock::SIZES`
- Utilisé pour :
  - **Attendance** : Inscriptions aux événements/initiations
  - **WaitlistEntry** : Inscriptions en liste d'attente

### Affichage dans les Formulaires

**Exemple** : Dropdown de sélection de taille

```erb
<%= f.select :roller_size, 
    options_for_select(
      RollerStock.available.ordered_by_size.map { |rs| 
        [rs.size_with_stock, rs.size] 
      },
      selected: f.object.roller_size
    ),
    { include_blank: "Sélectionner une taille" },
    { required: true, class: "form-select" }
%>
```

**Format** : "35 (3 disponibles)" ou "36 (1 disponible)"

---

## 🎯 Cas d'Usage

### 1. Inscription avec Prêt de Rollers

**Scénario** : Participant sans rollers veut s'inscrire à une initiation

1. Coche `needs_equipment = true`
2. Sélectionne `roller_size` dans le dropdown
3. Le système valide que la taille est dans `RollerStock::SIZES`
4. L'inscription est créée avec ces informations
5. L'organisateur peut ensuite voir les demandes de matériel

### 2. Gestion Admin du Stock

**ActiveAdmin** : Interface admin pour gérer le stock

- Lister toutes les tailles
- Modifier les quantités
- Activer/désactiver des tailles
- Rechercher/filtrer par taille, quantité, statut

**Actions** :
- `quantity += 1` : Ajout de rollers (achat, retour)
- `quantity -= 1` : Retrait de rollers (prêt, perte)
- `is_active = false` : Désactiver une taille (plus disponible)

### 3. Affichage Stock Disponible

**Dans les formulaires** :
- Seules les tailles actives avec stock > 0 sont affichées
- Format : "XX (Y disponible(s))"
- Tri par taille numérique

**Dans les exports admin** :
- Liste des demandes d'équipement avec tailles
- Export CSV des participants avec matériel demandé

---

## 📊 Exports et Rapports

### Export Demandes d'Équipement

**Fichier** : `app/admin/attendances.rb` (ActiveAdmin)

```ruby
# Export CSV des participants avec demande de matériel
csv << [att.user.full_name, att.user.email, att.user.phone, att.roller_size]
```

**Utilisation** : Permet aux organisateurs de préparer les rollers à prêter

### Notes d'Équipement

Le champ `equipment_note` (text) dans `Attendance` permet d'ajouter des notes supplémentaires sur la demande d'équipement.

---

## 🔄 Workflow Gestion Stock

### Ajout de Rollers

1. Admin va dans ActiveAdmin → RollerStock
2. Sélectionne la taille ou crée une nouvelle entrée
3. Augmente `quantity`
4. Active `is_active` si nécessaire

### Prêt de Rollers

1. Participant s'inscrit avec `needs_equipment = true` et `roller_size`
2. Organisateur exporte la liste des demandes
3. Rollers préparés et prêtés le jour de l'initiation
4. **Note** : La quantité n'est pas automatiquement décrémentée (gestion manuelle)

### Retour de Rollers

1. Après l'événement, rollers retournés
2. Admin met à jour `quantity` (ajoute les retours)

---

## ⚠️ Limitations Actuelles

### Pas de Réservation Automatique

- Le système ne réserve pas automatiquement les rollers
- La quantité n'est pas décrémentée lors de l'inscription
- Gestion manuelle par l'organisateur

**Raison** : Les rollers peuvent être prêtés de manière flexible, et tous les participants ne se présentent pas toujours.

### Pas de Gestion par Événement

- Le stock est global (pas par événement)
- Pas de réservation spécifique à un événement
- L'organisateur doit vérifier manuellement la disponibilité

**Amélioration future possible** : Système de réservation par événement avec décrémentation automatique.

---

## 📝 Notes Techniques

### Tri Numérique

Le tri par taille utilise `CAST(size AS INTEGER)` pour trier numériquement :

```ruby
scope :ordered_by_size, -> { order(Arel.sql("CAST(size AS INTEGER)")) }
```

**Raison** : Sans cast, "28" < "3" (tri alphabétique), ce qui est incorrect.

### ActiveAdmin Integration

Le modèle expose `ransackable_attributes` et `ransackable_associations` pour permettre la recherche et le filtrage dans ActiveAdmin.

### Hashid

Utilisation de `Hashid::Rails` pour générer des identifiants URL-friendly (utile pour les liens admin ou API).

---

## 🔗 Références

- **Modèle** : `app/models/roller_stock.rb`
- **Intégration Attendance** : `app/models/attendance.rb` (champ `roller_size`, validation)
- **Intégration WaitlistEntry** : `app/models/waitlist_entry.rb` (champ `roller_size`, validation)
- **Admin** : ActiveAdmin configuration (à vérifier dans `app/admin/`)

---

## 🎯 Améliorations Futures Possibles

1. **Réservation automatique** : Décrémentation automatique lors de l'inscription
2. **Gestion par événement** : Stock réservé par événement avec libération après
3. **Alertes stock faible** : Notification admin quand quantité < seuil
4. **Historique prêts** : Suivi des prêts par participant/événement
5. **États des rollers** : Suivi de l'état (neuf, usé, réparation)

---

**Version** : 1.0  
**Dernière mise à jour** : 2025-01-30

