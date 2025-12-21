# Flux Utilisateur - Gestion Boutique (AdminPanel)

**Date** : 2025-12-21  
**Version** : 1.0  
**Contexte** : Documentation du flux utilisateur actuel pour la gestion des produits et variantes dans l'AdminPanel

---

## 📋 RÉSUMÉ EXÉCUTIF

L'AdminPanel offre **deux méthodes** pour créer des variantes de produits :
1. **Génération automatique** : Lors de la création d'un produit, sélectionner les types d'options → toutes les combinaisons sont créées automatiquement
2. **Création manuelle** : Ajouter des variantes une par une à un produit existant

---

## 🛒 FLUX COMPLET : GESTION BOUTIQUE

### 1️⃣ LISTE DES PRODUITS (`/admin-panel/products`)

**Page** : `app/views/admin_panel/products/index.html.erb`

**Actions disponibles** :
- ✅ **Voir** : Détail d'un produit
- ✅ **Modifier** : Éditer un produit
- ✅ **Supprimer** : Supprimer un produit
- ✅ **Nouveau produit** : Créer un nouveau produit
- ✅ **Filtres** : Recherche par nom, catégorie, statut
- ✅ **Export CSV** : Exporter la liste des produits

**Flux** :
```
Index Produits
  └─> [Nouveau produit] → Formulaire création
  └─> [Voir] → Page détail produit
  └─> [Modifier] → Formulaire édition
  └─> [Supprimer] → Confirmation → Retour index
```

---

### 2️⃣ CRÉATION D'UN PRODUIT (`/admin-panel/products/new`)

**Page** : `app/views/admin_panel/products/new.html.erb`  
**Formulaire** : `app/views/admin_panel/products/_form.html.erb`

#### Étape 1 : Informations de base
- **Nom** * (max 140 caractères)
- **Slug** * (URL-friendly, max 160 caractères)
- **Catégorie** * (sélection)
- **Description** (optionnel)
- **Prix de base** * (en centimes, ex: 4000 = 40€)
- **Devise** * (EUR/USD)
- **Stock initial** (optionnel)
- **Image** (upload ou URL)

#### Étape 2 : Génération automatique de variantes (OPTIONNEL)

**⚠️ IMPORTANT** : Cette option n'apparaît QUE lors de la création d'un nouveau produit (pas lors de l'édition)

**Comment ça marche** :
1. Dans la section "Options" (colonne de droite), cocher les types d'options à combiner
   - Exemple : Cocher "Taille" et "Couleur"
2. Définir le stock initial par variante (optionnel, défaut: 0)
3. Cliquer sur "Créer le produit"

**Résultat** :
- Le produit est créé
- Le service `ProductVariantGenerator` génère automatiquement toutes les combinaisons
- Exemple : Taille (S, M, L) × Couleur (Rouge, Bleu) = **6 variantes créées**
- Redirection vers la page détail du produit

**Code** : `app/controllers/admin_panel/products_controller.rb:60-77`

#### Étape 3 : Sans génération automatique
- Si aucune option n'est cochée, le produit est créé **sans variantes**
- Il faudra ajouter des variantes manuellement ensuite

**Flux** :
```
Nouveau Produit
  ├─> Remplir formulaire
  ├─> [Optionnel] Cocher types d'options pour génération auto
  └─> [Créer le produit]
       ├─> Avec options → Génération auto variantes → Page détail
       └─> Sans options → Produit créé → Page détail (0 variante)
```

---

### 3️⃣ PAGE DÉTAIL PRODUIT (`/admin-panel/products/:id`)

**Page** : `app/views/admin_panel/products/show.html.erb`

**Informations affichées** :
- Détails du produit (nom, slug, catégorie, prix, stock, statut)
- Image du produit
- **Liste des variantes** avec :
  - SKU
  - Options associées (badges)
  - Prix
  - Stock
  - Statut
  - Actions (Modifier, Supprimer)

**Actions disponibles** :
- ✅ **Modifier** : Éditer le produit
- ✅ **Retour** : Retour à la liste
- ✅ **Nouvelle variante** : Créer une variante manuellement
- ✅ **Modifier variante** : Éditer une variante existante
- ✅ **Supprimer variante** : Supprimer une variante

**Flux** :
```
Détail Produit
  ├─> [Modifier] → Formulaire édition produit
  ├─> [Nouvelle variante] → Formulaire création variante
  ├─> [Modifier variante] → Formulaire édition variante
  └─> [Supprimer variante] → Confirmation → Retour détail
```

---

### 4️⃣ CRÉATION MANUELLE D'UNE VARIANTE (`/admin-panel/products/:product_id/product_variants/new`)

**Page** : `app/views/admin_panel/product_variants/new.html.erb`

**Quand utiliser** :
- Ajouter une variante à un produit existant
- Créer une variante spécifique (pas toutes les combinaisons)
- Ajouter une variante après avoir créé le produit sans options

**Formulaire** :
- **SKU** * (identifiant unique, validation en temps réel)
- **Prix** * (en centimes)
- **Devise** * (EUR/USD)
- **Stock** (optionnel)
- **Statut** (actif/inactif)
- **Options associées** (checkboxes) :
  - Sélectionner les options exactes (ex: Taille M + Couleur Rouge)
  - Plusieurs options possibles (ex: Taille M + Couleur Rouge + Matériel Coton)
- **Image** (upload ou URL)

**Flux** :
```
Nouvelle Variante
  ├─> Remplir SKU, prix, stock
  ├─> [Optionnel] Cocher options spécifiques
  └─> [Créer la variante] → Retour page détail produit
```

---

### 5️⃣ ÉDITION D'UNE VARIANTE (`/admin-panel/products/:product_id/product_variants/:id/edit`)

**Page** : `app/views/admin_panel/product_variants/edit.html.erb`

**Formulaire** :
- Même formulaire que création
- Options actuelles affichées dans la colonne de droite
- Possibilité de modifier les options associées (checkboxes)

**Flux** :
```
Édition Variante
  ├─> Modifier SKU, prix, stock, statut
  ├─> [Optionnel] Modifier options associées
  └─> [Mettre à jour] → Retour page détail produit
```

---

## 🔄 COMPARAISON : GÉNÉRATION AUTO vs CRÉATION MANUELLE

| Critère | Génération Automatique | Création Manuelle |
|---------|------------------------|-------------------|
| **Quand** | Lors de la création produit | Sur produit existant |
| **Nombre** | Toutes les combinaisons | Une variante à la fois |
| **Exemple** | Taille (3) × Couleur (2) = 6 variantes | 1 variante spécifique |
| **SKU** | Généré automatiquement | Saisi manuellement |
| **Options** | Toutes les combinaisons | Options choisies |
| **Cas d'usage** | Produit avec plusieurs tailles/couleurs | Ajouter une variante spécifique |

---

## 📊 FLUX UTILISATEUR COMPLET (Diagramme)

```
┌─────────────────────────────────────────────────────────────┐
│                    LISTE PRODUITS                           │
│              (/admin-panel/products)                        │
│                                                              │
│  [Nouveau produit] → [Voir] → [Modifier] → [Supprimer]     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              CRÉATION PRODUIT                                │
│         (/admin-panel/products/new)                         │
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Informations : Nom, Slug, Catégorie, Prix, Image │     │
│  └────────────────────────────────────────────────────┘     │
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │  [OPTIONNEL] Génération auto variantes            │     │
│  │  ☐ Taille (S, M, L)                                │     │
│  │  ☐ Couleur (Rouge, Bleu)                          │     │
│  │  Stock initial: [0]                                 │     │
│  └────────────────────────────────────────────────────┘     │
│                                                              │
│  [Créer le produit]                                         │
└─────────────────────────────────────────────────────────────┘
                            │
                ┌────────────┴────────────┐
                ▼                         ▼
    ┌──────────────────────┐  ┌──────────────────────┐
    │  AVEC OPTIONS        │  │  SANS OPTIONS        │
    │  → 6 variantes auto  │  │  → 0 variante        │
    └──────────────────────┘  └──────────────────────┘
                │                         │
                └────────────┬────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              DÉTAIL PRODUIT                                 │
│         (/admin-panel/products/:id)                        │
│                                                              │
│  Informations produit                                        │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Variantes (6)                                     │     │
│  │  [Nouvelle variante] ← Pour ajouter manuellement  │     │
│  │  ┌────────────────────────────────────────────┐    │     │
│  │  │ SKU | Options | Prix | Stock | Actions     │    │     │
│  │  │ ... | ...     | ...  | ...   | [Mod] [Del] │    │     │
│  │  └────────────────────────────────────────────┘    │     │
│  └────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│         CRÉATION VARIANTE MANUELLE                         │
│  (/admin-panel/products/:id/product_variants/new)          │
│                                                              │
│  SKU: [VESTE-M-ROUGE] ← Saisi manuellement                 │
│  Prix: [4000] centimes                                      │
│  Stock: [10]                                                │
│  Options:                                                   │
│    ☑ Taille: M                                              │
│    ☑ Couleur: Rouge                                         │
│  [Créer la variante] → Retour détail produit                │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 CAS D'USAGE CONCRETS

### Cas 1 : Veste avec 3 tailles × 3 couleurs = 9 variantes

**Méthode recommandée** : Génération automatique

1. Aller sur "Nouveau produit"
2. Remplir : Nom "Veste Grenoble Roller", Prix 4000, etc.
3. Dans "Générer des variantes automatiquement" :
   - ☑ Taille (S, M, L)
   - ☑ Couleur (Rouge, Bleu, Noir)
   - Stock initial : 10
4. Cliquer "Créer le produit"
5. **Résultat** : 9 variantes créées automatiquement (S-Rouge, S-Bleu, S-Noir, M-Rouge, etc.)

### Cas 2 : Produit simple sans variantes (ex: Casquette unique)

**Méthode** : Création sans options

1. Aller sur "Nouveau produit"
2. Remplir : Nom "Casquette", Prix 1500, etc.
3. Ne rien cocher dans "Générer des variantes"
4. Cliquer "Créer le produit"
5. **Résultat** : Produit créé sans variantes (ou avec 1 variante par défaut si nécessaire)

### Cas 3 : Ajouter une nouvelle taille à un produit existant

**Méthode** : Création manuelle

1. Aller sur le produit existant
2. Cliquer "Nouvelle variante"
3. Remplir :
   - SKU : "VESTE-XL-ROUGE"
   - Prix : 4000
   - Stock : 5
   - Options : ☑ Taille XL, ☑ Couleur Rouge
4. Cliquer "Créer la variante"
5. **Résultat** : Nouvelle variante ajoutée au produit

---

## ⚠️ POINTS D'ATTENTION

### Génération automatique
- ✅ **Avantage** : Rapide pour créer beaucoup de variantes
- ⚠️ **Attention** : Génère TOUTES les combinaisons (peut être beaucoup)
- ⚠️ **Limitation** : Disponible uniquement lors de la création produit

### Création manuelle
- ✅ **Avantage** : Contrôle précis, une variante à la fois
- ✅ **Flexible** : Peut ajouter des variantes à tout moment
- ⚠️ **Attention** : SKU doit être unique (validation en temps réel)

### Options
- Les options doivent être créées AVANT dans ActiveAdmin (`/activeadmin/option_types`)
- Les variantes peuvent avoir plusieurs options (ex: Taille + Couleur + Matériel)
- Les options sont affichées sous forme de badges dans la liste des variantes

---

## 🔧 FICHIERS CLÉS

### Controllers
- `app/controllers/admin_panel/products_controller.rb` : Gestion produits
- `app/controllers/admin_panel/product_variants_controller.rb` : Gestion variantes

### Services
- `app/services/product_variant_generator.rb` : Génération automatique

### Vues
- `app/views/admin_panel/products/index.html.erb` : Liste produits
- `app/views/admin_panel/products/new.html.erb` : Création produit
- `app/views/admin_panel/products/show.html.erb` : Détail produit
- `app/views/admin_panel/products/_form.html.erb` : Formulaire produit
- `app/views/admin_panel/product_variants/new.html.erb` : Création variante
- `app/views/admin_panel/product_variants/edit.html.erb` : Édition variante

### Routes
- `config/routes.rb` : Routes AdminPanel (lignes 8-15)

---

## 📝 AMÉLIORATIONS POSSIBLES

### Court terme
- [ ] Afficher un aperçu du nombre de variantes qui seront créées avant validation
- [ ] Permettre la génération automatique depuis la page détail produit
- [ ] Ajouter un bouton "Dupliquer variante" pour créer rapidement une variante similaire

### Moyen terme
- [ ] Import CSV pour créer plusieurs variantes en une fois
- [ ] Édition en masse des variantes (changer prix/stock de plusieurs variantes)
- [ ] Prévisualisation des combinaisons avant génération

---

**Document créé le** : 2025-12-21  
**Dernière mise à jour** : 2025-12-21  
**Version** : 1.0
