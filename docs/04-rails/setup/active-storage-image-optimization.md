# Optimisation des Images Active Storage

Ce document décrit la stratégie d'optimisation des images pour les événements.

## Stratégie d'Optimisation

Les images sont redimensionnées automatiquement selon leur contexte d'affichage pour :
- Réduire la taille des fichiers
- Améliorer les performances de chargement
- Économiser la bande passante
- Optimiser l'expérience utilisateur

## Variants Configurés

### 1. Hero Image (`cover_image_hero`)
- **Usage** : Page détail événement (`events/show`)
- **Dimensions** : 1200x500px max (ratio 2.4:1)
- **Affichage** : 
  - Desktop: 500px height
  - Tablet: 400px height
  - Mobile: 300px height
- **Format** : WebP (qualité 85%)
- **Taille estimée** : ~150-300 KB

### 2. Card Image (`cover_image_card`)
- **Usage** : Cartes d'événements dans les listes (`events/index`, `_event_card`)
- **Dimensions** : 800x200px max (ratio 4:1)
- **Affichage** : 200px height fixe
- **Format** : WebP (qualité 80%)
- **Taille estimée** : ~30-60 KB

### 3. Card Featured (`cover_image_card_featured`)
- **Usage** : Événement mis en avant (`pages/index`)
- **Dimensions** : 1200x350px max (ratio ~3.4:1)
- **Affichage** : 
  - Desktop: 350px height
  - Mobile: 250px height
- **Format** : WebP (qualité 85%)
- **Taille estimée** : ~100-200 KB

### 4. Thumbnail (`cover_image_thumb`)
- **Usage** : Formulaires et ActiveAdmin
- **Dimensions** : 400x200px max (ratio 2:1)
- **Affichage** : 200px height max
- **Format** : WebP (qualité 75%)
- **Taille estimée** : ~15-30 KB

## Configuration Technique

### Processeur d'Images
- **libvips** : Utilisé pour le traitement (plus rapide que ImageMagick)
- Configuration : `config/initializers/active_storage.rb`

### Format WebP
- **Avantages** : 
  - Taille réduite de 25-35% par rapport au JPEG
  - Qualité visuelle équivalente
  - Support moderne des navigateurs
- **Fallback** : Les navigateurs non compatibles reçoivent le format original

### Génération des Variants
- **Lazy loading** : Les variants sont générés à la première demande
- **Cache** : Les variants générés sont mis en cache dans MinIO
- **Performance** : Génération asynchrone possible avec Active Job

## Utilisation dans le Code

### Modèle Event
```ruby
event.cover_image_hero        # Variant pour page détail
event.cover_image_card       # Variant pour cartes liste
event.cover_image_card_featured  # Variant pour événement mis en avant
event.cover_image_thumb      # Variant pour thumbnails
```

### Vues
```erb
<% if @event.cover_image.attached? %>
  <%= image_tag(@event.cover_image_hero, alt: @event.title) %>
<% end %>
```

## Optimisations Futures

1. **Génération asynchrone** : Utiliser Active Job pour générer les variants en arrière-plan
2. **CDN** : Servir les images depuis un CDN pour améliorer les performances
3. **Lazy loading** : Charger les images uniquement quand elles sont visibles
4. **Responsive images** : Utiliser `srcset` pour différentes résolutions d'écran
5. **Compression avancée** : Ajuster la qualité selon le type d'image

## Monitoring

Pour vérifier l'efficacité de l'optimisation :

```bash
# Vérifier la taille des variants générés
docker compose -f ops/dev/docker-compose.yml exec web bin/rails runner "
  event = Event.where.not(id: nil).first
  if event&.cover_image&.attached?
    puts 'Original: ' + event.cover_image.byte_size.to_s + ' bytes'
    puts 'Hero variant: ' + event.cover_image_hero.blob.byte_size.to_s + ' bytes'
    puts 'Card variant: ' + event.cover_image_card.blob.byte_size.to_s + ' bytes'
  end
"
```

## Références

- [Active Storage Variants](https://guides.rubyonrails.org/active_storage_overview.html#transforming-images)
- [Image Processing Gem](https://github.com/janko/image_processing)
- [libvips Documentation](https://www.libvips.org/)

