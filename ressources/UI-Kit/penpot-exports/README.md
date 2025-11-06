# Penpot - Import "copied-shapes" validé (notes clés)

- Format attendu (structure racine): `~:type=~:copied-shapes`, `~:features.~#set`, `~:version`, `~:file-id`, `~:selected`, `~:objects`, `~:images`.
- Frame racine: `~:type=~:frame`, `~:component-root=true`, `~:shapes=[ids enfants]`.
- Enfants: chaque shape possède `~:id`, `~:parent-id` (id du frame), `~:frame-id` (id du frame), `~:points` (avec `~#point`), et types (`~:rect`, `~:text`, ...).
- Textes: utiliser `~:grow-type=~:fixed`, `~:content` → `root` → `paragraph-set` → `paragraph` → runs, et fournir `~:position-data` (rect avec `~:text`, `~:font-*`, `~:fills`, etc.).
- Booléens cohérents: `false`/`true` (éviter `null` lorsqu’un booléen est attendu), `flip-x/flip-y=false`.
- Cohérence géométrie: `~:selrect` et `~:points` concordants; `~:fills`/`~:strokes` définis; arrondis `~:r1..r4` si nécessaire.
- Encodage strict: JSON valide sans fragments/placeholder; ids d’objets référencés dans `~:shapes`.

Bonnes pratiques constatées:
- Partir d’un JSON de référence valide (ex: `Navbar.json`) puis ajouter les formes incrémentalement.
- Ajouter d’abord des rects, puis du texte (avec `position-data`) pour éviter l’erreur “Données dans le presse-papier non valides”.
- Garder des ids stables et mettre à jour la liste `~:shapes` du frame quand on ajoute un objet.

---

# Penpot integration (MCP + CLI)

## 1) MCP Penpot pour Cursor

Prérequis: Python 3.12+ (ou uv/uvx), compte Penpot (cloud ou self-hosted)

Variables (copier `penpot.env.example` → `.env` côté système ou renseigner dans Cursor Settings):
- PENPOT_API_URL (ex: https://design.penpot.app/api)
- PENPOT_USERNAME
- PENPOT_PASSWORD

Configuration Cursor (Settings → MCP Servers):
```json
{
  "mcpServers": {
    "penpot": {
      "command": "uvx",
      "args": ["penpot-mcp"],
      "env": {
        "PENPOT_API_URL": "https://design.penpot.app/api",
        "PENPOT_USERNAME": "<username>",
        "PENPOT_PASSWORD": "<password>"
      }
    }
  }
}
```

Démarrage en local (optionnel):
```bash
penpot-mcp
```

## 2) Exports programmatiques (@penpot-export/cli)

Prérequis: un token personnel Penpot (Settings → Personal access tokens)
- Copier `penpot.env.example` → `penpot.env` et remplir `PENPOT_TOKEN` et `PENPOT_INSTANCE`
- Mettre l’ID du fichier Penpot dans `penpot-export.config.json` (clé `penpot_file_id`)

Installation CLI (via npx recommandé):
```bash
npx @penpot-export/cli --help
```

Exports prêts:
```bash
# Export tokens au format DTCG
npx @penpot-export/cli \
  --config ./penpot-export.config.json \
  export tokens

# Export CSS depuis la page Components
npx @penpot-export/cli \
  --config ./penpot-export.config.json \
  export css
```

Sorties:
- `tokens.json`
- `styles/components.css`

## 3) Pipeline recommandé
- Commit des exports (tokens + CSS)
- Consommer tokens (variables CSS/Tailwind) et CSS de composants
- Synchroniser à chaque itération de design
