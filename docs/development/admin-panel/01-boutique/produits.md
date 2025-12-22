# 🛒 BOUTIQUE - Produits

**Priorité** : 🔴 HAUTE | **Phase** : 2 | **Semaine** : 2

---

## 📋 Description

Gestion des produits : CRUD, export, import, publication.

**Fichier actuel** : `app/controllers/admin_panel/products_controller.rb` (existe déjà)

---

## 🔧 Modifications à Apporter

### **Controller ProductsController**

**Fichier** : `app/controllers/admin_panel/products_controller.rb`

**Modifications** :
1. Ajouter actions `publish` / `unpublish`
2. Utiliser scope `Product.with_associations`
3. Vérifier export CSV fonctionne

**Code** :
```ruby
# Actions à ajouter
def publish
  @product = Product.find(params[:id])
  @product.update(is_active: true)
  redirect_to admin_panel_product_path(@product), notice: 'Produit publié'
end

def unpublish
  @product = Product.find(params[:id])
  @product.update(is_active: false)
  redirect_to admin_panel_product_path(@product), notice: 'Produit dépublié'
end
```

---

## 📝 Routes

**Fichier** : `config/routes.rb`

```ruby
resources :products do
  member do
    post :publish
    post :unpublish
  end
  # ... autres routes
end
```

---

## ✅ Checklist

- [ ] Ajouter actions `publish` / `unpublish` dans ProductsController
- [ ] Utiliser scope `Product.with_associations` dans index
- [ ] Vérifier export CSV fonctionne
- [ ] Ajouter routes `publish` / `unpublish`
- [ ] Tester publication/dépublication

---

**Retour** : [README Boutique](./README.md) | [INDEX principal](../INDEX.md)
