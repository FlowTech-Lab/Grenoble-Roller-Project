import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "sizeSelect",
    "colorSelect",
    "variantInput",
    "addButton",
    "stockHint",
    "stockValue",
    "qtyField",
    "priceDisplay",
    "unitPriceValue",
    "productImage"
  ]

  static values = {
    variants: Array,
    defaultImageUrl: String
  }

  connect() {
    // Sauvegarder le src initial de l'image (généré par image_tag)
    if (this.hasProductImageTarget && this.productImageTarget.src) {
      this.initialImageSrc = this.productImageTarget.src
    }
    // Ne mettre à jour que si une option est déjà sélectionnée
    // Sinon, garder l'image initiale et les valeurs par défaut
    const hasSelection = (this.hasSizeSelectTarget && this.sizeSelectTarget.value) || 
                        (this.hasColorSelectTarget && this.colorSelectTarget.value)
    if (hasSelection) {
      this.updateVariant()
    }
  }

  sizeChanged() {
    this.updateVariant()
  }

  colorChanged() {
    this.updateVariant()
  }

  quantityChanged() {
    this.updateVariant()
  }

  incrementQty() {
    if (!this.hasQtyFieldTarget) return
    const max = parseInt(this.qtyFieldTarget.max || '0', 10)
    const current = parseInt(this.qtyFieldTarget.value || '1', 10)
    if (max > 0 && current < max) {
      this.qtyFieldTarget.value = current + 1
      this.updateVariant()
    }
  }

  decrementQty() {
    if (!this.hasQtyFieldTarget) return
    const current = parseInt(this.qtyFieldTarget.value || '1', 10)
    if (current > 1) {
      this.qtyFieldTarget.value = current - 1
      this.updateVariant()
    }
  }

  updateVariant() {
    const sizeId = this.hasSizeSelectTarget && this.sizeSelectTarget.value 
      ? parseInt(this.sizeSelectTarget.value) 
      : null
    const colorId = this.hasColorSelectTarget && this.colorSelectTarget.value 
      ? parseInt(this.colorSelectTarget.value) 
      : null

    const hasSizeSelect = this.hasSizeSelectTarget
    const hasColorSelect = this.hasColorSelectTarget
    const sizeSelected = sizeId !== null
    const colorSelected = colorId !== null

    let variant = null
    let imageVariant = null // Variante pour l'image (peut être différente si seule la couleur est sélectionnée)

    // Trouver une variante complète pour le stock/prix (nécessite toutes les options)
    if ((hasSizeSelect && !sizeSelected) || (hasColorSelect && !colorSelected)) {
      variant = null
    } else {
      // Trouver la variante correspondante
      variant = this.variantsValue.find(v => {
        const matchSize = !hasSizeSelect ? true : (v.sizeId === sizeId || v.sizeId === null)
        const matchColor = !hasColorSelect ? true : (v.colorId === colorId || v.colorId === null)
        return matchSize && matchColor
      })
    }

    // Pour l'image : si seule la couleur est sélectionnée, trouver une variante avec cette couleur
    if (colorSelected && !sizeSelected && hasColorSelect) {
      // Chercher la première variante avec cette couleur (n'importe quelle taille)
      imageVariant = this.variantsValue.find(v => v.colorId === colorId)
    } else if (variant) {
      // Si on a une variante complète, l'utiliser pour l'image aussi
      imageVariant = variant
    }

    const qty = this.hasQtyFieldTarget 
      ? Math.max(1, parseInt(this.qtyFieldTarget.value || '1', 10)) 
      : 1

    if (variant && variant.stock > 0) {
      // Variante valide avec stock
      if (this.hasVariantInputTarget) {
        this.variantInputTarget.value = variant.id
      }
      if (this.hasAddButtonTarget) {
        this.addButtonTarget.disabled = false
      }

      // Mettre à jour le stock
      if (this.hasStockValueTarget) {
        this.stockValueTarget.textContent = variant.stock
      }
      if (this.hasStockHintTarget) {
        this.stockHintTarget.style.display = 'block'
      }

      // Mettre à jour la quantité max
      if (this.hasQtyFieldTarget) {
        this.qtyFieldTarget.max = variant.stock
        let current = parseInt(this.qtyFieldTarget.value || '1', 10)
        if (current > variant.stock) {
          current = variant.stock
        }
        if (current < 1 || isNaN(current)) {
          current = 1
        }
        this.qtyFieldTarget.value = current
      }

      // Mettre à jour le prix unitaire
      if (this.hasUnitPriceValueTarget) {
        this.unitPriceValueTarget.textContent = this.formatPrice(variant.price)
      }

      // Mettre à jour le prix total
      if (this.hasPriceDisplayTarget) {
        this.priceDisplayTarget.textContent = this.formatPrice(variant.price * qty)
      }

    }

    // Mettre à jour l'image indépendamment de la variante complète
    // (peut changer même si seule la couleur est sélectionnée)
    if (this.hasProductImageTarget) {
      if (imageVariant && imageVariant.imageUrl && imageVariant.imageUrl !== this.defaultImageUrlValue) {
        this.productImageTarget.src = imageVariant.imageUrl
      } else if (this.initialImageSrc) {
        // Revenir à l'image initiale si aucune variante d'image trouvée
        this.productImageTarget.src = this.initialImageSrc
      } else {
        // Fallback sur l'image par défaut
        this.productImageTarget.src = this.defaultImageUrlValue
      }
    }

    if (!variant) {
      // Aucune variante valide pour stock/prix
      if (this.hasVariantInputTarget) {
        this.variantInputTarget.value = ''
      }
      if (this.hasAddButtonTarget) {
        this.addButtonTarget.disabled = true
      }

      // Cacher le stock
      if (this.hasStockValueTarget) {
        this.stockValueTarget.textContent = '0'
      }
      if (this.hasStockHintTarget) {
        this.stockHintTarget.style.display = 'none'
      }

      // Réinitialiser la quantité max
      if (this.hasQtyFieldTarget) {
        this.qtyFieldTarget.max = 0
      }

      // Afficher le prix minimum
      if (this.hasPriceDisplayTarget) {
        const minPrice = Math.min(...this.variantsValue.map(v => v.price))
        const hasMultiple = this.variantsValue.length > 1
        this.priceDisplayTarget.textContent = hasMultiple 
          ? 'À partir de ' + this.formatPrice(minPrice * qty) 
          : this.formatPrice(minPrice * qty)
      }

      // Ne pas toucher à l'image si aucune variante n'est sélectionnée
      // (garder l'image initiale chargée par image_tag)
    }
  }

  formatPrice(cents) {
    const amount = cents / 100.0
    const formatted = amount === Math.floor(amount) 
      ? amount.toString() 
      : amount.toFixed(2)
    return formatted.replace('.', ',') + '€'
  }
}

