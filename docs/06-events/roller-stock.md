---
title: "Gestion du Stock de Rollers (RollerStock) - Grenoble Roller"
status: "active"
version: "2.3"
created: "2025-01-30"
updated: "2026-06-07"
tags: ["roller-stock", "equipment", "inventory", "initiations"]
---

# Gestion du Stock de Rollers (RollerStock)

**Dernière mise à jour** : 2026-06-07

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
| `quantity` | integer | Stock **physique** (>= 0) ; les réservations actives sont calculées séparément |
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
- `available` : Tailles actives avec stock physique > 0 (legacy ; préférer `selectable_for_event` pour les formulaires)
- `ordered_by_size` : Tri par taille numérique (ordre croissant)

### Méthodes

#### Instance

- `available?` : Retourne `true` si actif et stock physique > 0
- `out_of_stock?` : Retourne `true` si stock physique <= 0
- `size_with_stock` : Format "XX (Y disponible(s))" pour affichage (stock physique)
- `available_quantity_for_size(size)` : Stock physique − réservations actives pour une taille
- `selectable_for_event(event)` : Tailles proposées à l'inscription (disponibilité tenant compte des réservations)

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
      RollerStock.selectable_for_event(event).map { |rs| 
        [rs.size_with_availability, rs.size] 
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

**Admin Panel** : `AdminPanel::RollerStocksController` — `/admin-panel/roller-stocks`

- Lister toutes les tailles
- Modifier les quantités **physiques**
- Activer/désactiver des tailles
- **Clôturer les prêts terminés** (batch `stock_returned_at`)

**Actions** :
- `quantity += N` : Ajout de rollers au parc (achat, réception)
- `quantity -= N` : Retrait du parc (perte, mise au rebut)
- `is_active = false` : Désactiver une taille (plus proposée à l'inscription)

Les prêts en cours ne modifient pas `quantity` ; ils créent des **réservations** via `Attendance`.

### 3. Affichage Stock Disponible

**Dans les formulaires** :
- Tailles actives avec au moins 1 paire disponible (physique − réservations)
- Format : "XX (Y disponible(s))"
- Tri par taille numérique

**Dans les exports admin** :
- Liste des demandes d'équipement avec tailles
- Export CSV des participants avec matériel demandé

---

## 📊 Exports et Rapports

### Export Demandes d'Équipement

**Admin Panel** : pages initiations / présences — export des participants avec matériel demandé.

### Notes d'Équipement

Le champ `equipment_note` (text) dans `Attendance` permet d'ajouter des notes supplémentaires sur la demande d'équipement.

---

## 🔄 Workflow Gestion Stock

### Ajout de Rollers

1. Admin va dans Admin Panel → Stock Rollers
2. Sélectionne la taille ou crée une nouvelle entrée
3. Augmente `quantity` (stock **physique**)
4. Active `is_active` si nécessaire

### Prêt de Rollers

1. Participant s'inscrit avec `needs_equipment = true` et `roller_size`
2. **Une réservation** est enregistrée ; le stock physique reste inchangé
3. Organisateur exporte la liste des demandes
4. Rollers préparés et prêtés le jour de l'initiation

**Gestion des réservations** :
- Inscription : vérifie la disponibilité (`physique − réservations`) puis réserve
- Annulation : libère la réservation
- Changement de taille : libère l'ancienne, réserve la nouvelle (si disponible)
- Clôture prêt (`stock_returned_at`) : libère toutes les réservations de l'initiation

### Retour de Rollers (historique v2.2 — remplacé en v2.3)

Voir la section **Limitations Actuelles** ci-dessous pour le comportement actuel (réservations + clôture).

---

## ✅ Fonctionnalités Implémentées

### Gestion du Stock (v2.3)

- **Stock physique** : `RollerStock.quantity` ajusté uniquement en admin
- **Réservations** : calculées depuis les inscriptions actives sur initiations non clôturées
- **Validation** à l'inscription : disponibilité = physique − réservations
- **Clôture prêt** : bouton **« Clôturer les prêts terminés »** (Stock Rollers) + **« Matériel rendu »** par initiation + job `ReturnRollerStockJob` (2h)

### Méthode `Event#return_roller_stock`

**Fichier** : `app/models/event.rb`

```ruby
def return_roller_stock
  return unless is_a?(Event::Initiation)
  return nil if stock_returned_at.present?

  # Marque stock_returned_at ; libère les réservations (stock physique inchangé)
end
```

**Méthode `Event#has_equipment_loaned?`** : Vérifie s'il y a du matériel prêté pour l'événement

### Bouton « Clôturer les prêts terminés » dans Gestion de stock

**Fichier** : `app/views/admin_panel/roller_stocks/index.html.erb`  
**Action** : `POST /admin-panel/roller-stocks/return_all`  
**Controller** : `AdminPanel::RollerStocksController#return_all`

- Clôture le matériel pour toutes les initiations **déjà terminées** non encore marquées « Matériel rendu ».
- Équivalent à cliquer « Matériel rendu » sur chaque initiation concernée.
- Le stock physique affiché ne change pas ; les réservations actives diminuent.

### Bouton "Matériel rendu" dans Présences

**Fichier** : `app/views/admin_panel/initiations/presences.html.erb`

- Affiché uniquement pour les initiations passées avec matériel prêté
- Masqué si le matériel a déjà été rendu (badge avec date affiché à la place)
- Action : `POST /admin-panel/initiations/:id/return_material`
- Permission : Grade INITIATION (level 40) ou plus

## ⚠️ Limitations Actuelles

### Stock physique + réservations par initiation

- **`RollerStock.quantity`** = inventaire **physique** réel (modifié uniquement dans l’admin stock).
- **Réservations** = inscriptions avec matériel sur une initiation dont `stock_returned_at` est nil.
- **Disponible** pour une taille = `stock physique − réservations actives` (toutes initiations non clôturées confondues).
- **Retour matériel** (`stock_returned_at`) = clôture les réservations de cette initiation ; le stock physique ne bouge pas.
- Après clôture, les mêmes paires redeviennent disponibles pour les initiations suivantes.

| Moment | Comportement |
|--------|--------------|
| Inscription avec matériel | Réservation enregistrée ; stock physique inchangé |
| Annulation | Réservation libérée |
| Initiation terminée + matériel rendu | `stock_returned_at` renseigné ; réservations clôturées |
| Admin stock | Ajuste le parc physique uniquement |

### Retour de Rollers

**Trois options** :

1. **Bouton « Clôturer les prêts terminés »** (Admin → Stock Rollers) : marque le matériel rendu pour toutes les initiations terminées non clôturées.
2. **Bouton « Matériel rendu »** par initiation (page Présences).
3. **Job automatique** `ReturnRollerStockJob` (tous les jours à 2h, activé en prod via `recurring.yml`).

---

## 📝 Notes Techniques

### Tri Numérique

Le tri par taille utilise `CAST(size AS INTEGER)` pour trier numériquement :

```ruby
scope :ordered_by_size, -> { order(Arel.sql("CAST(size AS INTEGER)")) }
```

**Raison** : Sans cast, "28" < "3" (tri alphabétique), ce qui est incorrect.

### ActiveAdmin Integration

Legacy ActiveAdmin resources may still exist for reference; **operational stock management** uses Admin Panel (`roller_stocks`).

Le modèle expose `ransackable_attributes` pour recherche admin.

### Hashid

Utilisation de `Hashid::Rails` pour générer des identifiants URL-friendly (utile pour les liens admin ou API).

---

## 🔗 Références

- **Modèle** : `app/models/roller_stock.rb`
- **Intégration Attendance** : `app/models/attendance.rb` (champ `roller_size`, validation)
- **Intégration WaitlistEntry** : `app/models/waitlist_entry.rb` (champ `roller_size`, validation)
- **Admin** : `app/controllers/admin_panel/roller_stocks_controller.rb`

---

## 🎯 Améliorations Futures Possibles

1. ~~**Stock par initiation**~~ : implémenté via réservations + clôture (`stock_returned_at`)
2. **Alertes stock faible** : Notification admin quand quantité < seuil
3. **Historique prêts** : Suivi des prêts par participant/événement
4. **États des rollers** : Suivi de l'état (neuf, usé, réparation)

---

## 📝 Changelog

### Version 2.3 (2026-06-05)
- ✅ **Réservations par initiation** : `RollerStock.quantity` = parc physique ; disponibilité = physique − réservations actives
- ✅ Suppression des callbacks décrément/incrément sur `Attendance`
- ✅ Bouton renommé « Clôturer les prêts terminés » ; `return_roller_stock` ne modifie plus le stock physique
- ✅ Job `ReturnRollerStockJob` actif (2h via `recurring.yml`)
- ⚠️ **Post-déploiement** : ajuster le stock physique en admin si des décréments legacy ont faussé les quantités

### Version 2.2 (2026-01-31)
- ✅ **Bouton "Tout remettre en stock"** dans Gestion de stock (Admin Panel → Stock Rollers) : remet en stock tous les rollers des initiations déjà terminées et non encore marquées « Matériel rendu », et marque chaque initiation comme si « Matériel rendu » avait été cliqué. Idéal pour rattrapage global.
- ⏸️ **Retour automatique désactivé** : `ReturnRollerStockJob` reste désactivé (schedule.rb + recurring.yml) en attente de validation par le staff. Utiliser le bouton "Tout remettre en stock" ou "Matériel rendu" par initiation en attendant.
- ✅ Documentation : impact et usage du bouton "Tout remettre en stock" décrits avec les autres options de retour.

### Version 2.1 (2026-01-31)
- ✅ **Correction job** : `ReturnRollerStockJob` traite toutes les initiations **déjà terminées** (plus de fenêtre 24h sur le début). Job désactivé en 2.2 en attente validation staff.

### Version 2.0 (2025-01-13)
- ✅ Ajout du bouton "Matériel rendu" dans la page Présences
- ✅ Gestion automatique du stock (décrémentation/incrémentation)
- ✅ Méthode `has_equipment_loaned?` pour vérifier le matériel prêté
- ✅ Permissions : Grade INITIATION (level 40) peut faire le retour matériel

### Version 1.0 (2025-01-30)
- Documentation initiale

---

**Version** : 2.3  
**Dernière mise à jour** : 2026-06-07

