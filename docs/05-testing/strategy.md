# Stratégie de tests (Minitest)

Le projet utilise Minitest (par défaut Rails) avec le dossier `test/`.

## Types de tests
- Modèles: validations, relations, calculs (stocks, totaux)
- Contrôleurs: panier (ajout/màj/suppression), commandes (création/annulation)
- Système (optionnel): parcours d’achat de bout en bout

## Exécution

En local (Docker):

```bash
docker exec grenoble-roller-dev bin/rails test
```

Spécifique à un fichier:

```bash
docker exec grenoble-roller-dev bin/rails test test/models/order_test.rb
```

## Cibles prioritaires
- `Order`:
  - création avec items, total calculé
  - annulation (restauration des stocks)
- `Cart` (contrôleur):
  - `add_item` borne quantités, variantes inactives/stock 0
  - `update_item`, `remove_item`, `clear`
- `Product/ProductVariant`:
  - slugs uniques, contraintes SKU
- `Role/User`:
  - présence rôle, e-mail unique

## Données de test
- Préférer des fixtures/factories légères à `db:seed`
- Minimiser les dépendances entre tests

## Bonnes pratiques
- 1 cas = 1 assertion principale
- Noms explicites, données réalistes
- Tests rapides, isolés, déterministes
