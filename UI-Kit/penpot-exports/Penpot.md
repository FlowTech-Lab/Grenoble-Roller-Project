Structure de Code dans Penpot : Guide Complet pour Développeur DevOps
Format Natif et Architecture
Format .penpot : Zip + JSON
Le format natif Penpot est un fichier ZIP contenant une structure JSON entièrement lisible. Chaque fichier Penpot se décompose comme suit :​

text
fichier.penpot (ZIP archive)
├── data.json          # Structure complète du design
├── metadata.json      # Métadonnées du fichier
├── assets/            # Ressources binaires
│   ├── images/
│   ├── fonts/
│   └── shapes/
└── plugins/           # Données des plugins
Cette architecture ouverte signifie que vous pouvez extraire et manipuler les données JSON directement, idéal pour automatisation et intégration CI/CD.​

Structure des Layouts CSS
Flex Layout - Propriétés CSS Générées
Lorsque vous sélectionnez un élément avec Flex Layout, le panneau Inspect génère le code CSS suivant :​

Propriété Penpot	CSS Généré	Valeurs
Direction	flex-direction	row / column / row-reverse / column-reverse
Wrap	flex-wrap	nowrap / wrap
Align items	align-items	flex-start / center / flex-end
Justify content	justify-content	flex-start / center / flex-end / space-between / space-around / space-evenly
Gap (Row)	column-gap	Valeur en px
Gap (Column)	row-gap	Valeur en px
Padding	padding / padding-top / padding-right / padding-bottom / padding-left	Valeurs en px
Sizing (Fit width)	width	auto ou valeur fixe
Sizing (Fit height)	height	auto ou valeur fixe
Exemple CSS généré pour une navbar Flex :​

css
.navbar {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  padding: 12px 24px;
  width: 100%;
  height: 64px;
}

.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding: 8px 12px;
}
Grid Layout - Structure CSS
Pour les grids, Penpot génère une structure CSS complète :​

css
.grid-container {
  display: grid;
  grid-template-columns: 1fr 2fr 1fr;  /* Unités 'fr' supportées */
  grid-template-rows: auto 1fr auto;
  gap: 16px;  /* ou column-gap / row-gap séparé */
  padding: 20px;
}

/* Pour positionnement manuel */
.grid-item {
  grid-column: 1 / 3;  /* grid-column / grid-row générés */
  grid-row: 2;
  width: 100%;
  margin: 0;
}
Unités Grid supportées :​

fr (fractional units) : Portions de l'espace restant

auto : Taille ajustée au contenu

px : Pixels fixes

Structure des Composants
Composants - Propriétés de Base
Lors de la création d'un composant Penpot, la structure JSON contient :​

json
{
  "id": "component-id-uuid",
  "name": "Button/Primary",
  "type": "component",
  "parent_id": "board-id",
  "shapes": {
    "background": {
      "type": "rect",
      "fill": "#3B82F6",
      "stroke": null,
      "stroke-width": 0,
      "radius": 4
    },
    "label": {
      "type": "text",
      "content": "Click me",
      "font-family": "Inter",
      "font-size": 14,
      "font-weight": 600,
      "color": "#FFFFFF"
    }
  },
  "overrides": {
    "label": {
      "content": "customizable"
    }
  }
}
Variants - Structure Hiérarchique
Les variantes Penpot suivent une structure de nommage par propriétés :​

text
Button/Size-Small/State-Default
Button/Size-Small/State-Hover
Button/Size-Large/State-Default
Button/Size-Large/State-Hover
Structure JSON pour variantes :​

json
{
  "id": "component-main-id",
  "name": "Button",
  "type": "component",
  "variant_set": {
    "properties": [
      {
        "id": "prop-size",
        "name": "Size",
        "values": ["Small", "Large"]
      },
      {
        "id": "prop-state", 
        "name": "State",
        "values": ["Default", "Hover", "Active"]
      }
    ]
  },
  "variants": [
    {
      "id": "variant-small-default",
      "properties": {
        "Size": "Small",
        "State": "Default"
      },
      "shapes": { /* ... */ }
    }
  ]
}
Design Tokens - Format W3C DTCG
Structure JSON des Tokens
Penpot exporte les tokens au format W3C Design Tokens Community Group (W3C DTCG) :​

json
{
  "Global": {
    "color": {
      "primary": {
        "$value": "#3B82F6",
        "$type": "color",
        "$description": "Couleur primaire du système"
      },
      "success": {
        "$value": "#10B981",
        "$type": "color"
      }
    },
    "spacing": {
      "sm": {
        "$value": 8,
        "$type": "dimension"
      },
      "md": {
        "$value": 16,
        "$type": "dimension"
      }
    },
    "font": {
      "size": {
        "base": {
          "$value": 14,
          "$type": "dimension"
        }
      },
      "family": {
        "primary": {
          "$value": "Inter, sans-serif",
          "$type": "fontFamily"
        }
      }
    }
  }
}
Types de Tokens Supportés​
Type	Format JSON	Exemple
Color	"$type": "color"	"$value": "#FF0000" ou rgb(255,0,0)
Dimension	"$type": "dimension"	"$value": 16 (px par défaut)
Spacing	"$type": "spacing"	Référence dimension, p. ex. {space.md}
Border Radius	"$type": "borderRadius"	"$value": 8
Opacity	"$type": "opacity"	"$value": 0.5 ou 50%
Rotation	"$type": "rotation"	"$value": 45
Sizing	"$type": "sizing"	"$value": 100
Stroke Width	"$type": "strokeWidth"	"$value": 2
Typography (Composite)	Agrégation	font-family, font-size, font-weight, line-height
Aliases et Équations​
json
{
  "spacing": {
    "small": {
      "$value": 2,
      "$type": "dimension"
    },
    "medium": {
      "$value": "{spacing.small} * 2",  /* Équation */
      "$type": "dimension"
    },
    "scale": {
      "$value": 2,
      "$type": "number"
    }
  }
}
Opérations supportées : +, -, *, /, roundTo()​

Token Sets - Organisation Hiérarchique​
text
light/
├── colors.json
├── typography.json
└── spacing.json
dark/
├── colors.json
└── typography.json
$themes.json
$metadata.json
Structure des thèmes :

json
{
  "$themes": [
    {
      "id": "light-mode",
      "name": "Light Mode",
      "group": "Mode",
      "selectedTokenSets": {
        "light/colors": "enabled",
        "light/typography": "enabled",
        "shared/spacing": "enabled"
      }
    },
    {
      "id": "dark-mode",
      "name": "Dark Mode",
      "group": "Mode",
      "selectedTokenSets": {
        "dark/colors": "enabled",
        "dark/typography": "enabled",
        "shared/spacing": "enabled"
      }
    }
  ]
}
Inspect Mode - Génération de Code
CSS / HTML / SVG Export​
L'onglet Inspect génère trois types de code copiables :

CSS complet :

css
.component-name {
  position: absolute;
  left: 0px;
  top: 0px;
  width: 320px;
  height: 48px;
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  padding-left: 24px;
  padding-right: 24px;
  padding-top: 12px;
  padding-bottom: 12px;
  background-color: rgba(255, 255, 255, 1);
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}
HTML sémantiqu :

xml
<div class="navbar">
  <div class="nav-item">
    <svg><!-- icon --></svg>
    <span>Home</span>
  </div>
  <div class="nav-item">
    <svg><!-- icon --></svg>
    <span>About</span>
  </div>
</div>
SVG structuré :

text
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .fill { fill: #3B82F6; }
    </style>
  </defs>
  <rect class="fill" x="0" y="0" width="100" height="100" rx="8"/>
</svg>
Export Programmatique : @penpot-export
CLI Configuration​
Pour l'automatisation DevOps, utilisez @penpot-export/cli :

json
{
  "penpot_instance": "https://design.penpot.app",
  "penpot_token": "YOUR_API_TOKEN",
  "penpot_file_id": "52961d58-0a92-80c2-8003-2fc8ab8b34dd",
  "exports": [
    {
      "name": "components-css",
      "format": "css",
      "page": "Components",
      "output": "./src/styles/components.css"
    },
    {
      "name": "design-tokens",
      "format": "tokens",
      "output": "./tokens.json"
    }
  ]
}
Propriétés Partagées par Tous les Éléments
Tous les éléments Penpot contiennent ces propriétés de base :

json
{
  "id": "uuid-unique",
  "name": "Element Name",
  "type": "rect|circle|text|group|board|component",
  "parent_id": "parent-uuid",
  "hidden": false,
  "locked": false,
  "x": 0,
  "y": 0,
  "width": 100,
  "height": 100,
  "rotation": 0,
  "opacity": 1,
  "blend_mode": "normal",
  "fill": { /* color object */ },
  "stroke": { /* stroke object */ },
  "shadow": [ /* shadow objects */ ],
  "blur": { /* blur object */ },
  "z-index": 1
}
Pipeline Automatisation Recommandé
Pour exploit la structure de code Penpot en DevOps :​

1. Extraction des tokens :

bash
penpot-export export-tokens \
  --instance https://design.penpot.app \
  --file-id YOUR_FILE_ID \
  --output tokens.json
2. Génération CSS des composants :

bash
penpot-export export-css \
  --page Components \
  --output src/styles/
3. Versioning :

bash
git add tokens.json src/styles/
git commit -m "Design tokens sync from Penpot"
4. Synchronisation avec vos systèmes :

Tokens vers Tailwind ou CSS variables

Layouts Flex/Grid directement en CSS production

Variantes composants vers storybook ou histoire.js

Cette approche garantit une synchronisation parfaite design↔code avec un format 100% standardisé (JSON, CSS, SVG ouverts).