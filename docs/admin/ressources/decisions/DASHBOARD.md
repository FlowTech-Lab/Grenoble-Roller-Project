# 📊 Dashboard - Panel Admin

**Objectif** : Dashboard simple et efficace pour le panel admin avec statistiques et accès rapides.

---

## 🎯 Fonctionnalités Essentielles

### 1. Statistiques Principales (8 cartes)

**Widgets à afficher** :
- Événements à valider (avec lien vers la liste)
- Nombre d'utilisateurs (avec lien)
- Commandes en attente (avec lien)
- CA boutique (commandes payées, période courante)
- Adhésions actives (avec lien)
- Adhésions en attente (avec lien)
- Revenus adhésions (saison courante)
- CA total (boutique + adhésions)

**Format** : Cartes Bootstrap avec icônes, chiffres, et liens vers les détails.

### 2. Sections Informatives

**Événements à valider** :
- Liste des 10 derniers événements en attente
- Tableau : Titre, Créateur, Date prévue, Nombre d'inscriptions
- Lien vers tous les événements à valider

**Statistiques Boutique** :
- Produits en catalogue
- Produits en rupture de stock
- Commandes payées/complétées
- CA boutique
- Liste des 5 dernières commandes (utilisateur, total, statut, date)

**Statistiques Adhésions** :
- Adhésions actives
- Adhésions en attente
- Adhésions personnelles (toutes saisons)
- Adhésions enfants (toutes saisons)
- Adhésions expirant bientôt (30j)
- Revenus adhésions
- Liste des 5 dernières adhésions (utilisateur, type, nom, total, statut, date)

### 3. Accès Rapide

Liens directs vers :
- Événements
- Utilisateurs
- Commandes
- Produits
- Messages de contact
- Adhésions

---

## 🎨 Structure Visuelle

**Layout** :
- Grille responsive : 4 colonnes desktop, 2 tablet, 1 mobile
- Utiliser Bootstrap `row-cols-1 row-cols-md-2 row-cols-lg-4`
- Cartes avec classes `card-liquid` pour cohérence design

**Organisation** :
- En-tête avec titre "Dashboard"
- Section statistiques (8 cartes)
- Sections informatives en dessous (tables/listes)
- Footer avec accès rapide

---

## 🛠️ Implémentation Progressive

### Phase 1 : MVP Simple (2-3 jours)
- Dashboard avec ordre fixe des widgets
- 8 cartes statistiques basiques
- Sections informatives simples (pas de lazy loading)
- Accès rapide en footer

### Phase 2 : Améliorations (optionnel, plus tard)
- Drag-drop pour réordonner les widgets (SortableJS)
- Lazy loading des widgets lourds (Turbo Frames)
- Personnalisation par utilisateur (ordre sauvegardé)

**Note** : Pour l'instant, on se concentre sur la Phase 1 - Dashboard simple et fonctionnel.

---

## 📋 Données Nécessaires

### Controller `Admin::DashboardController`

**Méthodes** :
- `index` : Affiche le dashboard avec toutes les statistiques

**Données à calculer** :
- Compteurs (événements, utilisateurs, commandes, adhésions)
- Totaux financiers (CA boutique, revenus adhésions)
- Listes récentes (derniers événements, commandes, adhésions)

**Optimisations** :
- Utiliser des requêtes SQL optimisées (compteurs, agrégats)
- Mettre en cache les statistiques lourdes si nécessaire
- Éviter les N+1 queries

---

## 🎯 Priorités

**Essentiel (MVP)** :
1. 8 cartes statistiques principales
2. Section événements à valider
3. Accès rapide

**Important (Phase 1)** :
4. Statistiques boutique
5. Statistiques adhésions

**Optionnel (Phase 2)** :
6. Personnalisation (drag-drop)
7. Lazy loading
8. Options utilisateur

---

## 📝 Notes d'Implémentation

### Réutilisation

- **Classes CSS** : Utiliser `card-liquid`, `btn-liquid-primary` existantes
- **Dark mode** : Hérite automatiquement (déjà implémenté)
- **Bootstrap** : Toutes les classes standards disponibles

### Structure Fichiers

```
app/
├── controllers/admin/
│   └── dashboard_controller.rb
├── views/admin/
│   └── dashboard/
│       └── index.html.erb
└── helpers/admin/
    └── dashboard_helper.rb  (si besoin)
```

### Routes

```ruby
namespace :admin do
  root 'dashboard#index'
  # ou
  get 'dashboard', to: 'dashboard#index'
end
```

---

**Version** : 1.0  
**Date** : 2025-01-27  
**Approche** : Simple et fonctionnel d'abord, améliorations ensuite
