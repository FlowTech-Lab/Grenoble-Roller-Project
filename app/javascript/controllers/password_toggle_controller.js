import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="password-toggle"
// WCAG 2.2 - Remplacer confirmation par toggle show/hide (critère 3.3.7)
export default class extends Controller {
  static targets = ["input", "toggle", "icon", "label"]

  connect() {
    this.updateToggleText()
  }

  toggle(event) {
    event.preventDefault()
    
    const isPassword = this.inputTarget.type === "password"
    const newType = isPassword ? "text" : "password"
    
    // Change input type
    this.inputTarget.type = newType
    
    // Update icon
    if (this.hasIconTarget) {
      this.iconTarget.classList.toggle("bi-eye")
      this.iconTarget.classList.toggle("bi-eye-slash")
    }
    
    // Update ARIA attributes
    const newLabel = isPassword ? "Masquer le mot de passe" : "Afficher le mot de passe"
    const newText = isPassword ? "Masquer" : "Afficher"
    
    this.toggleTarget.setAttribute("aria-label", newLabel)
    this.toggleTarget.setAttribute("aria-pressed", isPassword ? "true" : "false")
    this.toggleTarget.setAttribute("title", newLabel)
    
    if (this.hasLabelTarget) {
      this.labelTarget.textContent = newText
    }
    
    // Focus sur le champ après toggle pour accessibilité
    this.inputTarget.focus()
  }

  updateToggleText() {
    if (!this.hasToggleTarget) return
    
    const isPassword = this.inputTarget.type === "password"
    const icon = isPassword ? "bi-eye" : "bi-eye-slash"
    const text = isPassword ? "Afficher" : "Masquer"
    
    // Mettre à jour l'icône et le texte (fallback si pas de targets)
    if (!this.hasIconTarget) {
      const iconElement = this.toggleTarget.querySelector("i")
      if (iconElement) {
        iconElement.className = `bi ${icon}`
      }
    }
    
    if (!this.hasLabelTarget) {
      const textElement = this.toggleTarget.querySelector("span.visually-hidden")
      if (textElement) {
        textElement.textContent = text
      }
    }
    
    // Mettre à jour aria-label et title pour accessibilité
    const label = isPassword ? "Afficher le mot de passe" : "Masquer le mot de passe"
    this.toggleTarget.setAttribute("aria-label", label)
    this.toggleTarget.setAttribute("aria-pressed", isPassword ? "false" : "true")
    this.toggleTarget.setAttribute("title", label)
  }
}

