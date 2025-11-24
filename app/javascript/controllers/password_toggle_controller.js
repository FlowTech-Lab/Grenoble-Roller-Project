import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="password-toggle"
// WCAG 2.2 - Remplacer confirmation par toggle show/hide (critère 3.3.7)
export default class extends Controller {
  static targets = ["input", "toggle"]

  connect() {
    this.updateToggleText()
  }

  toggle() {
    const type = this.inputTarget.type === "password" ? "text" : "password"
    this.inputTarget.type = type
    this.updateToggleText()
    
    // Focus sur le champ après toggle pour accessibilité
    this.inputTarget.focus()
  }

  updateToggleText() {
    if (!this.hasToggleTarget) return
    
    const isPassword = this.inputTarget.type === "password"
    const icon = isPassword ? "bi-eye" : "bi-eye-slash"
    const text = isPassword ? "Afficher" : "Masquer"
    
    // Mettre à jour l'icône et le texte
    const iconElement = this.toggleTarget.querySelector("i")
    const textElement = this.toggleTarget.querySelector("span.visually-hidden")
    
    if (iconElement) {
      iconElement.className = `bi ${icon}`
    }
    if (textElement) {
      textElement.textContent = text
    }
    
    // Mettre à jour aria-label et title pour accessibilité
    this.toggleTarget.setAttribute("aria-label", `${text} le mot de passe`)
    this.toggleTarget.setAttribute("title", `${text} le mot de passe`)
  }
}

