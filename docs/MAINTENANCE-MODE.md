# 🔧 Mode Maintenance - Grenoble Roller

Système de maintenance intégré avec design adapté aux couleurs Grenoble Roller.

## ✅ Implémentation Complète

Tous les fichiers ont été créés et configurés :

### Fichiers créés

- ✅ `app/models/maintenance_mode.rb` - Gestion du flag maintenance
- ✅ `app/middleware/maintenance_middleware.rb` - Middleware d'interception
- ✅ `public/maintenance.html` - Page HTML avec design Grenoble Roller
- ✅ `app/controllers/admin/maintenance_modes_controller.rb` - Controller pour toggle
- ✅ `app/admin/maintenance.rb` - Page ActiveAdmin
- ✅ `config/initializers/maintenance_middleware.rb` - Enregistrement middleware
- ✅ Routes configurées dans `config/routes.rb`

## 🎨 Design Adapté Grenoble Roller

La page de maintenance utilise :
- **Couleurs principales** : `#007bff` (bleu Grenoble Roller)
- **Gradient liquid** : `linear-gradient(135deg, #1e8dff 0%, #1ea0ff 100%)`
- **Background pastel** : Design liquid cohérent avec le site
- **Typography** : Police Poppins (comme le reste du site)
- **Effets glass** : Backdrop blur et transparences
- **Animations** : Pulse, shimmer, bounce (style liquid)

## 📋 Utilisation

### Activer/Désactiver via ActiveAdmin

1. Se connecter à `/admin`
2. Cliquer sur "⚙️ Maintenance Mode" dans le menu
3. Cliquer sur le bouton "Activer Maintenance 🔒" ou "Désactiver Maintenance ✓"

### Activer/Désactiver via Console Rails

```ruby
# Rails console
rails c

# Activer
MaintenanceMode.enable!

# Désactiver
MaintenanceMode.disable!

# Vérifier l'état
MaintenanceMode.enabled?  # => true/false
MaintenanceMode.status    # => "ACTIF" ou "INACTIF"
```

## 🔒 Sécurité

### Routes autorisées en maintenance

Même en mode maintenance, ces routes restent accessibles :
- `/admin` - Panel ActiveAdmin
- `/users/sign_in` - Page de connexion Devise
- `/users/sign_out` - Déconnexion
- `/maintenance` - Page maintenance elle-même
- `/assets` - Assets statiques (CSS, JS, images)
- `/packs` - Assets Webpack

### Accès utilisateurs

- ✅ **Administrateurs** : Accès complet au site
- ✅ **Utilisateurs connectés** : Accès normal au site
- ❌ **Visiteurs anonymes** : Redirigés vers la page de maintenance

## 🔗 Bouton Ancien Site

Un bouton "Ancien site" est présent sur la page de maintenance pour rediriger temporairement vers l'ancienne version.

**⚠️ À configurer** : Modifier l'URL dans `public/maintenance.html` ligne ~240 :

```html
<!-- Remplacer # par l'URL réelle de l'ancien site -->
<a href="https://ancien-site.grenoble-roller.org" class="btn-maintenance btn-old-site" target="_blank" rel="noopener noreferrer">
  <span>↩️</span>
  <span>Ancien site</span>
</a>
```

## 🧪 Tests

### Tester en local

```bash
# 1. Démarrer le serveur
rails s

# 2. Activer la maintenance (dans un autre terminal)
rails c
> MaintenanceMode.enable!

# 3. Ouvrir le navigateur en navigation privée
# => Doit afficher la page de maintenance

# 4. Se connecter via /users/sign_in
# => Doit permettre l'accès normal

# 5. Désactiver
> MaintenanceMode.disable!
```

### Vérifier les logs

```bash
# Vérifier les logs de maintenance
tail -f log/development.log | grep MAINTENANCE
```

## 📊 Persistance

L'état est stocké dans le cache Rails :
- **Redis** (recommandé) : Si configuré
- **Rails.cache** : Fallback par défaut (fichier ou mémoire)

**Durée** : 30 jours (configurable dans `app/models/maintenance_mode.rb`)

## 🚀 Déploiement

### Checklist

- [ ] Vérifier que `public/maintenance.html` est bien versionné
- [ ] Configurer l'URL de l'ancien site dans `maintenance.html`
- [ ] Tester l'activation/désactivation en staging
- [ ] Vérifier que les assets sont bien servis
- [ ] Tester le login admin en mode maintenance

### Commandes utiles

```bash
# Vérifier que le middleware est bien chargé
rails runner "puts Rails.application.config.middleware.include?(MaintenanceMiddleware)"

# Vérifier l'état actuel
rails runner "puts MaintenanceMode.status"
```

## 🔍 Dépannage

### La page de maintenance ne s'affiche pas

1. Vérifier que le middleware est enregistré :
   ```bash
   rails runner "puts Rails.application.config.middleware.to_a"
   ```
2. Vérifier que `public/maintenance.html` existe
3. Vérifier les logs : `tail -f log/development.log`

### Les utilisateurs connectés sont bloqués

Vérifier que Warden/Devise est bien configuré dans le middleware (ligne 31 de `maintenance_middleware.rb`)

### Le toggle ne fonctionne pas

1. Vérifier les permissions admin dans `app/controllers/admin/maintenance_modes_controller.rb`
2. Vérifier la route : `rails routes | grep maintenance`
3. Vérifier les logs d'erreur

## 📝 Notes

- Le mode maintenance ne nécessite **pas de redémarrage** du serveur
- Les changements sont **immédiats**
- L'état survit aux **redémarrages** du serveur (via cache)
- Le design est **responsive** (mobile-friendly)

---

**Version** : 1.0  
**Date** : 2025-01-20  
**Auteur** : Adaptation pour Grenoble Roller avec design Liquid

