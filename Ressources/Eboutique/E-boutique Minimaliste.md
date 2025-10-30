## E-boutique Minimaliste : Guide Complet des Meilleures Pratiques
Pour une e-boutique minimaliste avec peu d'articles, voici l'approche optimale basée sur les standards 2025 et les bonnes pratiques éprouvées.

### Principes fondamentaux
- **Prioriser l'espace blanc, la clarté et l'accessibilité**.
- **Mobile-first**: ~80% du trafic e-commerce vient du mobile.

## Responsive Product Grid: Breakpoints et Cartes

### Breakpoints standards

| Appareil | Colonnes | Largeur de carte | Gap | Padding |
| --- | --- | --- | --- | --- |
| Mobile (< 640px) | 1 | 100% - padding | 16px | 16px |
| Tablette (640–1024px) | 2 | ~320–350px | 24px | 24px |
| Desktop (1024–1440px) | 3 | ~300–320px | 24px | 32px |
| Large Desktop (> 1440px) | 4 | ~260–280px | 24px | 40px |

### Approche mobile-first avec CSS Grid

```css
.product-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 16px;
  padding: 16px;
}

@media (min-width: 640px) {
  .product-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 24px;
  }
}

@media (min-width: 1024px) {
  .product-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}
```

### Dimensionnement des cartes produits
- **Ratios d'image cohérents**:
  - 1:1 (carré) — moderne, scannable, top mobile
  - 4:5 (portrait) — traditionnel, laisse de l'espace pour la description
- Pour des images hétérogènes, utiliser `object-fit: cover`.

```css
.image-container {
  position: relative;
  width: 100%;
  padding-bottom: 100%; /* Aspect ratio 1:1 */
  overflow: hidden;
}

.image-container img {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
}
```

**Hauteurs recommandées**
- Mobile: image 200–250px
- Tablette: image 300–320px
- Desktop: image 300–320px
- Hauteur totale carte (~370–400px): image + texte (titre 28–48px + prix ~20px) + padding

## Hiérarchie typographique et espacement
- **Titre**: 14–16px, `font-weight: 500`, 2 lignes max
- **Prix**: 16–18px, `font-weight: 600`
- **Description**: 12–13px, optionnelle, souvent cachée sur mobile
- **Padding interne**: 12px (mobile) → 16px (desktop)
- **Gap**: 16px (mobile) → 24px (desktop)
- **White space généreux** pour structurer visuellement et éviter la surcharge.

## Cas particulier: peu d'articles (5–12)
- **Centrer** la grille si le nombre < colonnes prévues
- **Augmenter légèrement** les dimensions des cartes (max ~380px)
- Optionnel: **featured products** via bento layout (certaines cartes plus grandes)

```css
.product-card:first-child {
  grid-column: 1 / 3; /* Span 2 colonnes */
}

@media (max-width: 1024px) {
  .product-card:first-child {
    grid-column: span 1; /* Normal sur petit écran */
  }
}
```

## Optimisations recommandées

### Performance & UX
- **Lazy-load images**: `loading="lazy"`
- **Formats**: WebP optimisé + fallback JPEG
- **Hover léger**: `transform: translateY(-2px)`, `box-shadow`
- **Border subtile**: `1px #e0e0e0`
- **Border-radius**: `8px`

### Accessibilité
- **Alt text** descriptif sur images
- **Contraste** ≥ 4.5:1
- **Focus states** visibles au clavier
- **HTML sémantique**: `<article>` par carte

## Molécule Carte Produit Optimisée (production)

Structure en zones distinctes pour hiérarchie claire et CTA dominant:

- Zone 1: Image 1:1 avec `badge` stock en overlay
- Zone 2: Contenu statique (titre 2 lignes max, description 2 lignes)
- Zone 3: Options séparées avec bordures (taille / couleur)
- Zone 4: Footer vertical: prix + badge promo, puis bouton pleine largeur

```html
<article class="card card-product card-liquid rounded-liquid">
  <div class="card-product-image-wrapper">
    <div class="card-product-image">
      <img src=".../T-shirt.png" alt="T-shirt Grenoble Roller" loading="lazy" decoding="async">
    </div>
    <span class="badge badge-liquid-success badge-stock">En stock</span>
  </div>
  <div class="card-body">
    <div class="product-content">
      <h5 class="product-title mb-2">T-shirt Grenoble Roller</h5>
      <p class="product-description mb-3 small text-muted">Polyester respirant – parfait pour le sport.</p>
    </div>
    <div class="product-options-section mb-3">
      <div class="product-options">
        <select class="form-select form-select-sm" aria-label="Choisir taille">
          <option selected>Choisir taille</option>
          <option>XS</option><option>S</option><option>M</option><option>L</option><option>XL</option>
        </select>
        <select class="form-select form-select-sm" aria-label="Choisir couleur">
          <option selected>Blanc</option>
        </select>
      </div>
    </div>
    <div class="spacer"></div>
    <div class="product-footer">
      <div class="price-section-vertical">
        <div class="price-display">
          <span class="price">10,00€</span>
          <!-- <span class="price-old">30,00€</span> -->
        </div>
        <!-- <span class="badge text-bg-warning badge-promo">Promo</span> -->
      </div>
      <button class="btn btn-liquid-primary btn-add">
        <i class="bi bi-plus-lg" aria-hidden="true"></i>
        <span class="btn-text">Ajouter au panier</span>
      </button>
    </div>
  </div>
  </article>
```

CSS clés (extraits alignés avec `UI-Kit/style.css`):

```css
/* Image 1:1 */
.card-product-image-wrapper { position: relative; width: 100%; aspect-ratio: 1/1; overflow: hidden; }
.card-product-image { position: absolute; inset: 0; }
.card-product-image img { width: 100%; height: 100%; object-fit: cover; }
.badge-stock { position: absolute; top: 0.75rem; left: 0.75rem; z-index: 10; font-weight: 600; }

/* Options séparées */
.product-options-section { padding: 8px 0; border-top: 1px solid var(--liquid-glass-border); border-bottom: 1px solid var(--liquid-glass-border); }
.product-options { display: flex; flex-wrap: wrap; gap: 0.5rem; }

/* Footer vertical + CTA pleine largeur */
.product-footer { display: flex; flex-direction: column; gap: 8px; padding-top: 8px; border-top: 1px solid var(--liquid-glass-border); }
.price-section-vertical { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.price-display { display: flex; align-items: baseline; gap: 6px; }
.badge-promo { font-size: 10px; padding: 2px 6px; font-weight: 600; }
.btn-add { width: 100%; display: inline-flex; align-items: center; justify-content: center; gap: .5rem; }

/* Petits écrans: bascule prix sur 2 lignes si nécessaire */
@media (max-width: 420px) {
  .product-footer { align-items: flex-start; }
  .price-display { width: 100%; flex-wrap: wrap; }
}
```

Bénéfices:
- Zones séparées: meilleure scannabilité et compréhension.
- Bouton pleine largeur: cible de clic améliorée et conversion.
- Badge promo non masqué, prix lisible même en espace réduit.
- Composable: masquer facilement options ou promo via classes (`no-options`, `no-promo`).

## Règles d'or minimaliste
- ✅ **À faire**: 1 colonne mobile / 2–3 desktop; gap ≥ 24px; images 1:1 ou 4:5 uniformes; `object-fit: cover`; padding généreux; border subtile; micro-animations légères.
- ❌ **À éviter**: > 4 colonnes; gap < 16px; ratios mélangés; textes > 2 lignes; trop d'infos/carte; transformations importantes au hover.