import { Controller } from "@hotwired/stimulus"

// Validation SKU en temps réel
export default class extends Controller {
  static values = {
    checkUrl: String,
    variantId: Number
  }

  connect() {
    this.input = this.element.querySelector('input[type="text"]')
    this.statusElement = document.getElementById('sku-status')
    
    if (this.input) {
      this.input.addEventListener('blur', this.checkSku.bind(this))
      this.input.addEventListener('input', this.debounce(this.checkSku.bind(this), 500))
    }
  }

  checkSku() {
    const sku = this.input.value.trim()
    
    if (!sku) {
      this.updateStatus('', 'text-muted')
      return
    }

    const params = new URLSearchParams({ sku: sku })
    if (this.variantIdValue) {
      params.append('variant_id', this.variantIdValue)
    }

    fetch(`${this.checkUrlValue}?${params.toString()}`, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      },
      credentials: 'same-origin'
    })
    .then(response => response.json())
    .then(data => {
      if (data.available) {
        this.updateStatus('✓ Disponible', 'text-success')
        this.input.classList.remove('is-invalid')
        this.input.classList.add('is-valid')
      } else {
        this.updateStatus('✗ ' + data.message, 'text-danger')
        this.input.classList.remove('is-valid')
        this.input.classList.add('is-invalid')
      }
    })
    .catch(error => {
      console.error('Erreur validation SKU:', error)
      this.updateStatus('Erreur de vérification', 'text-warning')
    })
  }

  updateStatus(message, className) {
    if (this.statusElement) {
      this.statusElement.textContent = message
      this.statusElement.className = className
    }
  }

  debounce(func, wait) {
    let timeout
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout)
        func(...args)
      }
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
    }
  }
}
