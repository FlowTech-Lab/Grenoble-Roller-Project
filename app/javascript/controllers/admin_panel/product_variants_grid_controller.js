import { Controller } from "@hotwired/stimulus"

// GRID éditeur pour les variantes de produits
// Permet l'édition inline et la sélection multiple
export default class extends Controller {
  static values = {
    productId: Number
  }

  static targets = ["selectAll", "checkbox", "row", "priceInput"]

  connect() {
    this.updateBulkEditButton()
  }

  // Mettre à jour le bouton "Édition en masse" selon les cases cochées
  updateBulkEditButton() {
    const checkedBoxes = this.checkboxTargets.filter(cb => cb.checked)
    const bulkEditBtn = document.getElementById('bulk-edit-btn')
    
    if (bulkEditBtn) {
      if (checkedBoxes.length > 0) {
        bulkEditBtn.disabled = false
        const variantIds = checkedBoxes.map(cb => cb.value).join(',')
        bulkEditBtn.href = bulkEditBtn.href.split('?')[0] + `?variant_ids[]=${variantIds}`
      } else {
        bulkEditBtn.disabled = true
      }
    }
  }

  // Cocher/décocher toutes les cases
  selectAllChanged() {
    const checked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = checked
    })
    this.updateBulkEditButton()
  }

  // Sauvegarder le prix modifié (édition inline)
  savePrice(event) {
    const input = event.target
    const variantId = input.dataset.variantId
    const priceCents = Math.round(parseFloat(input.value) * 100)
    
    // TODO: Implémenter la sauvegarde AJAX
    // Pour l'instant, on peut simplement marquer le champ comme modifié
    input.classList.add('is-modified')
    
    console.log(`Sauvegarde prix variant ${variantId}: ${priceCents} cents`)
  }
}

