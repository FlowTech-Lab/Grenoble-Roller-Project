# 📋 PLAN : PAGE DE PRÉSENTATION DE L'ASSOCIATION GRENOBLE ROLLER

**Date de création** : 2025-11-04  
**Objectif** : Créer une page complète de présentation de l'association avec intégration dans la navbar

---

## 🎯 OBJECTIFS

### Objectifs Principaux
1. **Informer** : Présenter l'association Grenoble Roller aux visiteurs
2. **Engager** : Inciter les visiteurs à adhérer ou participer
3. **Rassurer** : Communiquer les valeurs et la mission de l'association
4. **Transmettre** : Donner accès aux documents importants (statuts, règlement intérieur)

### Objectifs Techniques
- Créer une route `/association` ou `/about`
- Ajouter un lien dans la navbar
- Page responsive (mobile-first)
- Accessible (WCAG 2.1 AA)
- Performance optimisée

---

## 📚 INFORMATIONS RÉCUPÉRÉES DU PROJET

### Informations depuis FIL_CONDUCTEUR_PROJET.md

#### 🏢 **Présentation Association**
- Page d'accueil avec valeurs :
  - **Convivialité**
  - **Sécurité**
  - **Dynamisme**
  - **Respect**
- Présentation du bureau et CA
- Règlement intérieur et statuts
- Lutte contre les violences

#### 🎪 **Activités de l'Association**
- **Événements** : Randos vendredi soir
- **Initiation** : Séances samedi 10h15-12h00
- **Parcours** : 4-15km
- **Matériel** : Système de prêt de matériel
- **Adhésions** : 10€, 56,55€, 58€

#### 👥 **Structure**
- Gestion des rôles : Membre, Staff, Admin
- Système d'adhésion

---

## 🎨 STRUCTURE DE LA PAGE (UX/UI)

### Architecture de la Page

```
┌─────────────────────────────────────────┐
│  HERO BANNER                            │
│  - Titre accrocheur                     │
│  - Image/photos roller                  │
│  - CTA "Adhérer" / "Découvrir"         │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  SECTION 1 : QUI SOMMES-NOUS ?          │
│  - Texte de présentation                │
│  - Histoire de l'association            │
│  - Mission                              │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  SECTION 2 : NOS VALEURS                │
│  ┌──────┐  ┌──────┐  ┌──────┐         │
│  │Conv. │  │Sécur.│  │Dynam.│         │
│  └──────┘  └──────┘  └──────┘         │
│  ┌──────┐                             │
│  │Respect│                             │
│  └──────┘                             │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  SECTION 3 : NOS ACTIVITÉS              │
│  - Randos vendredi soir                │
│  - Initiation samedi 10h15-12h00       │
│  - Prêt de matériel                    │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  SECTION 4 : BUREAU & ÉQUIPE            │
│  - Présentation du bureau              │
│  - Présentation du CA                  │
│  - Photos + descriptions               │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  SECTION 5 : ADHÉSION                   │
│  - Tarifs : 10€, 56,55€, 58€          │
│  - CTA "Adhérer maintenant"            │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  SECTION 6 : DOCUMENTS                  │
│  - Règlement intérieur                 │
│  - Statuts                             │
│  - Lutte contre les violences          │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  SECTION 7 : CONTACT                    │
│  - Formulaire de contact               │
│  - Réseaux sociaux                     │
└─────────────────────────────────────────┘
```

---

## 📝 CONTENU DÉTAILLÉ PAR SECTION

### 🎯 HERO BANNER
**Objectif** : Accrocher immédiatement le visiteur

**Contenu** :
- **Titre** : "Grenoble Roller - La communauté de passionnés de roller à Grenoble"
- **Sous-titre** : "Rejoignez une association dynamique qui partage sa passion pour le roller"
- **CTA Principal** : "Adhérer à l'association"
- **CTA Secondaire** : "Découvrir nos activités"
- **Image** : Photo de groupe ou action roller (utiliser image existante ou placeholder)

**Design** :
- Utiliser `.banner-hero` existant
- Style Liquid Design 2025
- Overlay avec texte blanc
- Responsive mobile-first

---

### 📖 SECTION 1 : QUI SOMMES-NOUS ?
**Titre** : "Qui sommes-nous ?"

**Contenu à développer** :
- Histoire de l'association (à compléter)
- Mission : "Promouvoir la pratique du roller à Grenoble en toute sécurité et convivialité"
- Vision : "Créer une communauté soudée de passionnés de roller"

**Format** :
- 2 colonnes sur desktop
- 1 colonne sur mobile
- Texte + image optionnelle

---

### 💎 SECTION 2 : NOS VALEURS
**Titre** : "Nos valeurs"

**4 Valeurs principales** :

#### 1. 🤝 **CONVIVIALITÉ**
- **Icône** : `bi-people` ou `bi-heart`
- **Description** : "Nous favorisons un esprit d'échange et de partage dans une atmosphère chaleureuse"
- **Couleur** : Primary (bleu)

#### 2. 🛡️ **SÉCURITÉ**
- **Icône** : `bi-shield-check`
- **Description** : "La sécurité de tous est notre priorité, que ce soit dans la pratique ou l'organisation"
- **Couleur** : Success (vert)

#### 3. ⚡ **DYNAMISME**
- **Icône** : `bi-lightning-charge`
- **Description** : "Une association active avec des événements réguliers et une énergie constante"
- **Couleur** : Warning (orange)

#### 4. 🙏 **RESPECT**
- **Icône** : `bi-hand-thumbs-up` ou `bi-award`
- **Description** : "Respect de chacun, de l'environnement et des règles établies"
- **Couleur** : Info (bleu clair)

**Design** :
- Grille 2x2 sur desktop
- 1 colonne sur mobile
- Cards avec icônes Bootstrap Icons
- Effet hover (liquid design)

---

### 🎪 SECTION 3 : NOS ACTIVITÉS
**Titre** : "Nos activités"

**Activités principales** :

#### 🗓️ **Randos du Vendredi Soir**
- **Description** : "Chaque vendredi soir, partez à la découverte de Grenoble en roller"
- **Distance** : 4-15km selon les parcours
- **Horaire** : Vendredi soir (à préciser)
- **Icône** : `bi-calendar-event`

#### 🎓 **Initiation Samedi Matin**
- **Description** : "Apprenez ou perfectionnez votre technique avec nos séances d'initiation"
- **Horaire** : Samedi 10h15-12h00
- **Matériel** : Prêt de matériel disponible
- **Icône** : `bi-book`

#### 🎒 **Prêt de Matériel**
- **Description** : "Pas de matériel ? Nous proposons un service de prêt pour démarrer"
- **Icône** : `bi-bag`

**Design** :
- Cards avec images/icônes
- Liens vers pages détaillées (si existantes)
- CTA "En savoir plus"

---

### 👥 SECTION 4 : BUREAU & ÉQUIPE
**Titre** : "Bureau & Conseil d'Administration"

**Contenu** :
- Présentation des membres du bureau
- Présentation du CA
- Photos (optionnelles - respect RGPD)
- Rôles et responsabilités

**Format** :
- Cards avec photos + descriptions
- Grid responsive
- Peut être dynamique (si modèle User existe avec rôle admin/staff)

**Note** : À adapter selon les données disponibles

---

### 💰 SECTION 5 : ADHÉSION
**Titre** : "Adhérer à l'association"

**Tarifs** (selon FIL_CONDUCTEUR) :
- **Tarif 1** : 10€
- **Tarif 2** : 56,55€
- **Tarif 3** : 58€

**À préciser** :
- Différences entre les tarifs
- Période d'adhésion (annuelle ?)
- Inclusions (assurance, accès activités, etc.)

**Cadeau de bienvenue** :
- 🎁 **Gourde en métal offerte** : Mentionner clairement que chaque adhésion comprend une gourde en métal offerte
- Badge "Cadeau inclus" ou icône cadeau visible
- Mise en avant avec couleur/style différenciant

**Design** :
- Cards avec tarifs
- Badge "Populaire" sur tarif recommandé
- Badge "🎁 Gourde offerte" bien visible
- **CTA Principal** : Bouton "Adhérer maintenant" → Lien vers boutique HelloAsso
- Note : "L'objet sera ajouté automatiquement à votre commande"
- Utiliser `.btn-liquid-primary` pour le CTA principal
- Utiliser `.card-liquid` pour les cards de tarifs

**Structure** :
- Card avec prix en évidence
- Liste des avantages (à compléter selon tarif)
- Badge gourde offerte
- CTA "Adhérer" → Boutique HelloAsso
- Note explicative sur l'ajout automatique de l'objet

---

### 📄 SECTION 6 : DOCUMENTS
**Titre** : "Documents officiels"

**Documents à proposer** :
- 📋 **Règlement intérieur** : PDF téléchargeable
- 📜 **Statuts de l'association** : PDF téléchargeable
- 🛡️ **Lutte contre les violences** : Page ou document dédié

**Design** :
- Liste avec icônes
- Boutons de téléchargement
- Modals ou liens directs

---

### 📧 SECTION 7 : CONTACT
**Titre** : "Nous contacter"

**Contenu** :
- Formulaire de contact (si existe)
- Email de contact
- Réseaux sociaux (liens)
- Adresse (si applicable)

**Design** :
- Formulaire stylisé
- Liens vers réseaux sociaux avec icônes
- CTA "Envoyer un message"

---

## 🛠️ IMPLÉMENTATION TECHNIQUE

### Routes Rails
```ruby
# config/routes.rb
get 'association', to: 'pages#association', as: 'association'
# ou
get 'about', to: 'pages#about', as: 'about'
```

### Contrôleur
```ruby
# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def index; end
  def association; end  # Nouvelle action
end
```

### Vue
```erb
# app/views/pages/association.html.erb
<!-- Structure complète avec toutes les sections -->
```

### Navbar
```erb
<!-- Ajouter dans app/views/layouts/_navbar.html.erb -->
<li class="nav-item">
  <%= link_to association_path, class: "nav-link" do %>
    <i class="bi bi-info-circle me-1"></i>Association
  <% end %>
</li>
```

---

## 🎨 STYLES CSS - COMPOSANTS DISPONIBLES DANS UI-KIT

### Classes Liquid Design (déjà existantes)

#### Boutons
- `.btn-liquid-primary` : Bouton principal avec gradient bleu
- `.btn-liquid-success` : Bouton vert (pour actions positives)
- `.btn-liquid-danger` : Bouton rouge (pour actions destructives)
- `.btn-outline-primary` : Bouton outline bleu
- `.btn-outline-light` : Bouton outline blanc (pour hero banner)

#### Cards
- `.card-liquid` : Card avec effet glassmorphism
- `.card-liquid-primary` : Card avec header gradient bleu
- `.card-event` : Card spécialisée pour événements
- `.card-user` : Card pour présenter utilisateurs/membres
- `.card-city` : Card pour présenter villes/lieux

#### Banners
- `.banner-hero` : Hero banner principal (grand format)
- `.banner-page` : Banner pour pages internes (format réduit)
- `.banner-overlay` : Overlay pour effet de contraste
- `.banner-content` : Contenu du banner
- `.banner-title` : Titre du banner
- `.banner-subtitle` : Sous-titre du banner
- `.banner-actions` : Zone des boutons CTA
- `.banner-icon` : Icône dans le banner

#### Forms
- `.form-control-liquid` : Input avec effet glassmorphism

#### Alerts & Badges
- `.alert-liquid-primary` : Alerte bleue
- `.alert-liquid-success` : Alerte verte
- `.alert-liquid-warning` : Alerte orange
- `.alert-liquid-danger` : Alerte rouge
- `.badge-liquid-primary` : Badge bleu
- `.badge-liquid-success` : Badge vert
- `.badge-liquid-danger` : Badge rouge

#### Typography
- `.text-liquid-primary` : Texte couleur primaire
- `.text-liquid-primary-light` : Texte couleur primaire claire
- `.text-liquid-primary-dark` : Texte couleur primaire foncée
- `.text-liquid-success` : Texte couleur succès
- `.text-liquid-warning` : Texte couleur warning
- `.text-liquid-danger` : Texte couleur danger
- `.text-liquid-info` : Texte couleur info

#### Effets & Animations
- `.shadow-liquid` : Ombre douce
- `.shadow-liquid-lg` : Grande ombre douce
- `.rounded-liquid` : Bordures arrondies
- `.rounded-liquid-lg` : Grandes bordures arrondies
- `.liquid-fade-in` : Animation fade in
- `.liquid-float` : Animation float

#### Navbar
- `.navbar-liquid` : Navbar avec effet glassmorphism
- `.navbar-grenoble-roller` : Navbar spécifique Grenoble Roller

### Composants UI-Kit disponibles à utiliser

#### Atoms (composants de base)
- Boutons liquides (tous les variants)
- Forms liquides
- Cards liquides
- Badges et alerts liquides
- Typography avec classes liquid

#### Molecules (composants combinés)
- Banners (hero et page)
- Cards d'événements (`.card-event`)
- Cards utilisateurs (`.card-user`)
- Formulaires d'authentification (`.auth-form`)

#### Organisms (composants complexes)
- Sections de commentaires
- Calendrier d'événements
- Présentation de ressources
- Footer Grenoble Roller (`.footer-grenoble-roller`)

### Classes à utiliser pour la page Association

#### Section Valeurs
- `.card-liquid` : Pour chaque valeur
- `.badge-liquid-primary`, `.badge-liquid-success`, etc. : Pour les icônes/couleurs
- Grid Bootstrap : `row` + `col-md-6 col-lg-3`

#### Section Activités
- `.card-event` : Pour les activités (adaptable)
- `.card-liquid` : Alternative pour cards activités
- Icônes Bootstrap Icons : `bi-calendar-event`, `bi-book`, `bi-bag`

#### Section Adhésion
- `.card-liquid` : Pour les cards de tarifs
- `.badge-liquid-primary` : Pour "Gourde offerte" ou "Populaire"
- `.btn-liquid-primary` : Pour CTA "Adhérer maintenant"
- Icône cadeau : `bi-gift` ou `bi-gift-fill`

#### Section Documents
- Liste avec icônes Bootstrap Icons
- `.btn-outline-primary` : Pour boutons de téléchargement
- Icônes : `bi-file-earmark-pdf`, `bi-download`

#### Section Contact
- `.form-control-liquid` : Pour formulaire de contact
- `.btn-liquid-primary` : Pour bouton submit
- `.alert-liquid-success` : Pour message de confirmation

### Images disponibles dans le projet
- `app/app/assets/images/img/roller.png` : Photo roller (peut servir pour sections)
- `app/app/assets/images/img/Affiche-reprise.jpg` : Affiche événement
- `app/app/assets/images/img/bannersmall3.png` : Banner small
- `app/app/assets/images/logo/` : Logos (color, white, nb)
- `app/app/assets/images/img/Veste.png` : Photo veste (peut servir pour boutique/adhesion)

### Bonnes pratiques d'utilisation des images
- **Petites photos** : Utiliser pour illustrer les sections (valeurs, activités)
  - Photo `roller.png` : Pour section activités ou hero
  - Photo `Affiche-reprise.jpg` : Pour section événements
  - Photo `Veste.png` : Pour section boutique/adhésion
  - Photos dans layout alterné (gauche/droite) pour rythme visuel
- **Positionnement** : Alterner image gauche/droite pour rythme visuel
- **Responsive** : Toujours utiliser `img-fluid` de Bootstrap
- **Lazy loading** : Ajouter `loading="lazy"` pour performance
- **Alt text** : Toujours renseigner les attributs alt pour accessibilité
- **Tailles recommandées** :
  - Hero banner : Pleine largeur
  - Sections valeurs/activités : Max 400px de large
  - Illustrations : 200-300px de large (petites photos stylées)

### Exemples d'utilisation des images par section

#### Section Valeurs
- Petites photos optionnelles à côté de chaque valeur
- Utiliser `roller.png` pour valeurs liées à l'activité
- Format : Petite illustration (200px) avec overlay ou border

#### Section Activités
- `Affiche-reprise.jpg` : Pour illustrer les randos vendredi
- `roller.png` : Pour section initiation
- Photos en background ou en side pour enrichir visuellement

#### Section Adhésion
- `Veste.png` : Pour illustrer les goodies/boutique
- Photo de gourde si disponible (sinon icône)
- Style moderne avec effet glassmorphism sur l'image

### Responsive
- Breakpoints Bootstrap :
  - `col-12` : Mobile
  - `col-md-6` : Tablet
  - `col-lg-4` ou `col-lg-3` : Desktop

---

## 📱 BONNES PRATIQUES WEB

### Accessibilité (WCAG 2.1 AA)
- ✅ Contraste de couleurs suffisant
- ✅ Textes alternatifs pour images
- ✅ Structure sémantique (h1, h2, sections)
- ✅ Navigation au clavier
- ✅ Labels pour formulaires
- ✅ ARIA labels si nécessaire

### Performance
- ✅ Images optimisées (WebP, lazy loading)
- ✅ CSS minifié
- ✅ Pas de JavaScript bloquant
- ✅ Cache browser

### SEO
- ✅ Meta description unique
- ✅ Titre H1 unique par page
- ✅ Structure sémantique HTML5
- ✅ Balises meta Open Graph
- ✅ Schema.org markup (Organization)

### Responsive Design
- ✅ Mobile-first approach
- ✅ Breakpoints Bootstrap
- ✅ Images responsive
- ✅ Touch-friendly (boutons min 44x44px)

---

## 🔍 INFORMATIONS À COMPLÉTER

### Contenu manquant
- [ ] Histoire détaillée de l'association
- [ ] Liste complète des membres du bureau
- [ ] Photos officielles (avec autorisations)
- [ ] Détails des tarifs d'adhésion (différences entre 10€, 56,55€, 58€)
- [ ] **URL boutique HelloAsso** pour adhésion
- [ ] **Configuration HelloAsso** : Ajout automatique gourde en métal dans panier
- [ ] Documents PDF (statuts, règlement intérieur)
- [ ] Informations de contact complètes
- [ ] Liens réseaux sociaux

### Données techniques
- [ ] Vérifier si modèle User/Admin existe
- [ ] **Intégration HelloAsso** :
  - [ ] URL de la boutique HelloAsso
  - [ ] Configuration produit "Adhésion" avec gourde en métal
  - [ ] Vérifier que la gourde s'ajoute automatiquement au panier lors de l'adhésion
  - [ ] Tester le flux d'adhésion complet
- [ ] Vérifier système de contact
- [ ] Vérifier stockage documents (Active Storage ?)

### Intégration HelloAsso - Détails
**Configuration requise** :
1. **Produit Adhésion** dans HelloAsso avec options de tarifs (10€, 56,55€, 58€)
2. **Produit Gourde en métal** à ajouter automatiquement
3. **Configuration panier** : Lorsqu'un utilisateur sélectionne une adhésion, la gourde doit être ajoutée automatiquement (gratuite)
4. **Lien** : Bouton "Adhérer maintenant" doit pointer vers la page produit HelloAsso

**Texte à afficher** :
- "🎁 Gourde en métal offerte avec chaque adhésion !"
- "L'objet sera ajouté automatiquement à votre commande"
- Badge visible sur les cards de tarifs

---

## ✅ CHECKLIST DE RÉALISATION

### Phase 1 : Setup
- [ ] Créer la route `/association`
- [ ] Ajouter l'action `association` dans `PagesController`
- [ ] Créer le fichier `association.html.erb`
- [ ] Ajouter le lien dans la navbar

### Phase 2 : Structure
- [ ] Hero banner (`.banner-hero`)
- [ ] Section "Qui sommes-nous ?" (texte + image optionnelle)
- [ ] Section "Nos valeurs" (4 cards `.card-liquid` en grid)
- [ ] Section "Nos activités" (cards avec icônes)
- [ ] Section "Bureau & équipe" (`.card-user` ou `.card-liquid`)
- [ ] Section "Adhésion" :
  - [ ] Cards tarifs (`.card-liquid`)
  - [ ] Badge "🎁 Gourde offerte" (`.badge-liquid-primary`)
  - [ ] CTA "Adhérer maintenant" (`.btn-liquid-primary` → Boutique HelloAsso)
  - [ ] Note explicative sur ajout automatique objet
- [ ] Section "Documents" (liste avec icônes + boutons téléchargement)
- [ ] Section "Contact" (formulaire `.form-control-liquid`)

### Phase 3 : Styles
- [ ] Styles responsive
- [ ] Effets hover (liquid design)
- [ ] Optimisation mobile
- [ ] Accessibilité (contrastes, labels)

### Phase 4 : Contenu
- [ ] Rédaction des textes
- [ ] Intégration des images (utiliser images disponibles dans `app/app/assets/images/`)
- [ ] Ajout photos petites pour illustrer sections (valeurs, activités)
- [ ] Mise en avant gourde offerte (badge + texte explicatif)
- [ ] Lien boutique HelloAsso pour adhésion
- [ ] Note sur ajout automatique objet dans commande
- [ ] Liens vers documents
- [ ] Vérification des CTA (tous fonctionnels)

### Phase 5 : Tests
- [ ] Tests responsive (mobile, tablet, desktop)
- [ ] Tests accessibilité
- [ ] Tests de performance
- [ ] Vérification des liens
- [ ] Tests navigateurs (Chrome, Firefox, Safari)

---

## 📚 RESSOURCES & RÉFÉRENCES

### Fichiers du projet à consulter
- `Ressources/FIL_CONDUCTEUR_PROJET.md` : Informations fonctionnelles
- `app/views/pages/index.html.erb` : Structure de référence
- `app/views/layouts/_navbar.html.erb` : Navbar à modifier
- `app/assets/stylesheets/_style.scss` : Styles existants
- `UI-Kit/` : Design system de référence

### Bonnes pratiques générales
- **Structure** : Hero → Contenu principal → CTA → Footer
- **Hiérarchie visuelle** : Titre H1 → H2 sections → H3 sous-sections
- **CTAs** : Maximum 2-3 CTA par page, bien visibles
- **Longueur** : Contenu scannable, pas de blocs de texte trop longs
- **Images** : Photos authentiques, de qualité, optimisées

### Exemples de pages "À propos" réussies
- Sections claires et bien délimitées
- Utilisation d'icônes et visuels
- Appels à l'action visibles
- Design moderne et accessible
- Mobile-friendly

---

## 🚀 PROCHAINES ÉTAPES

1. **Valider le plan** avec l'équipe
2. **Collecter le contenu** manquant (textes, photos, documents)
3. **Créer la structure** HTML de base
4. **Ajouter les styles** CSS
5. **Intégrer le contenu** final
6. **Tester** et optimiser
7. **Déployer** sur staging puis production

---

## 🎓 BONNES PRATIQUES WEB MODERNES (2024-2025)

### Structure de Contenu
1. **Hero Section** : Première impression forte (3-5 secondes d'attention)
2. **Valeur Proposée** : Communiquer rapidement ce qui rend unique
3. **Preuve Sociale** : Témoignages, chiffres, membres actifs
4. **Call-to-Action** : Toujours visible, action claire
5. **Transparence** : Documents officiels, contact facile

### Éléments qui Convertissent
- ✅ **Chiffres clés** : Nombre de membres, événements/an, années d'existence
- ✅ **Témoignages** : Citations de membres satisfaits
- ✅ **Preuve sociale** : Photos d'événements, vidéos
- ✅ **Urgence/Limitation** : "Places limitées", "Inscription ouverte"
- ✅ **Garanties** : "Sécurité assurée", "Matériel fourni"

### Design Moderne (2024-2025)
- **Glassmorphism** : Effets de verre (déjà dans Liquid Design)
- **Micro-interactions** : Animations subtiles au hover
- **Photographie authentique** : Photos réelles vs stock photos
- **Typographie hiérarchisée** : Tailles de police variées
- **Espace blanc** : Respiration visuelle
- **Cards modulaires** : Sections facilement scannables

### Techniques de Rédaction
- **Titres accrocheurs** : Poser des questions, utiliser des chiffres
- **Paragraphes courts** : 2-3 lignes max par paragraphe
- **Listes à puces** : Facilite la lecture rapide
- **Vocabulaire accessible** : Éviter le jargon technique
- **Ton convivial** : S'adresser directement au visiteur ("vous")

---

## 📊 EXEMPLE DE HIÉRARCHIE VISUELLE

```
H1 : "Grenoble Roller - Votre association de roller à Grenoble"
  ↓
H2 : "Qui sommes-nous ?"
  ↓
  Paragraphe introductif (2-3 lignes)
  ↓
H3 : "Notre mission"
  ↓
  Texte de mission (2-3 lignes)
  ↓
H2 : "Nos valeurs"
  ↓
  Cards des 4 valeurs (grid)
  ↓
H2 : "Nos activités"
  ↓
  Cards des activités (grid)
  ↓
[...]
```

---

## 🎯 MÉTRIQUES DE SUCCÈS

### Objectifs à mesurer
- **Taux de conversion** : Visiteurs → Adhésions
- **Temps sur page** : > 2 minutes = bon engagement
- **Taux de rebond** : < 50% = contenu pertinent
- **Clics sur CTA** : Taux de clic > 3% = efficace
- **Téléchargements** : Documents les plus consultés

### KPIs
- Nombre de visites sur `/association`
- Taux de conversion (adhésions depuis la page)
- Engagement (temps, scroll depth)
- Partages sociaux

---

## 🔗 INTÉGRATION AVEC L'EXISTANT

### Liens vers autres pages
- **Page d'accueil** : Retour vers `/`
- **Événements** : Lien vers calendrier/événements
- **Initiation** : Lien vers page initiation (si existe)
- **Boutique** : Lien vers HelloAsso ou boutique
- **Contact** : Lien vers formulaire de contact

### Navigation
- **Breadcrumb** : Accueil > Association
- **Menu navbar** : Lien "Association" toujours visible
- **Footer** : Lien "À propos" / "Association"

---

## 🚨 POINTS D'ATTENTION

### Contenu sensible
- ⚠️ **RGPD** : Autorisations pour photos de membres
- ⚠️ **Données personnelles** : Ne pas afficher d'informations sensibles
- ⚠️ **Mentions légales** : Lien vers page dédiée si nécessaire

### Technique
- ⚠️ **Performance** : Images optimisées (WebP, lazy loading)
- ⚠️ **SEO** : Meta tags, Open Graph, Schema.org
- ⚠️ **Accessibilité** : Tests avec lecteurs d'écran
- ⚠️ **Cross-browser** : Tests sur Chrome, Firefox, Safari, Edge

### Contenu
- ⚠️ **Mise à jour** : Prévoir un système pour mettre à jour les infos
- ⚠️ **Traduction** : Si multi-langue prévu, structure i18n
- ⚠️ **Documents** : Formats accessibles (PDF, aussi HTML si possible)

---

**Note** : Ce plan est évolutif et peut être ajusté selon les besoins et les retours.

**Prochaine étape** : Valider ce plan et commencer l'implémentation par la création de la route et de la structure de base.
