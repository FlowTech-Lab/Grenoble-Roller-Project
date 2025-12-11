import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    // Initialiser le masque si une valeur existe déjà
    if (this.hasInputTarget && this.inputTarget.value) {
      this.formatPhone(this.inputTarget.value)
    }
  }

  format(event) {
    this.formatPhone(event.target.value)
  }

  formatPhone(value) {
    if (!this.hasInputTarget) return

    // Enlever tous les caractères non numériques
    const digits = value.replace(/[^0-9]/g, '').slice(0, 10)
    
    // Formater avec des espaces : XX XX XX XX XX
    let formatted = ''
    for (let i = 0; i < digits.length; i++) {
      if (i > 0 && i % 2 === 0) {
        formatted += ' '
      }
      formatted += digits[i]
    }

    // Mettre à jour la valeur du champ (seulement si différente pour éviter les boucles)
    if (this.inputTarget.value !== formatted) {
      this.inputTarget.value = formatted
    }
  }
}

