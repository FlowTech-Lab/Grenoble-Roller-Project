import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="password-strength"
export default class extends Controller {
  static targets = ["input", "meter", "feedback", "strengthText"]

  connect() {
    // Initialiser le compteur si présent
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener("input", this.checkStrength.bind(this))
      this.inputTarget.addEventListener("focus", this.showMeter.bind(this))
      this.inputTarget.addEventListener("blur", this.hideMeterIfEmpty.bind(this))
      
      // Vérifier la force au chargement si le champ a déjà une valeur
      if (this.inputTarget.value) {
        this.checkStrength()
      }
    }
  }

  disconnect() {
    if (this.hasInputTarget) {
      this.inputTarget.removeEventListener("input", this.checkStrength.bind(this))
      this.inputTarget.removeEventListener("focus", this.showMeter.bind(this))
      this.inputTarget.removeEventListener("blur", this.hideMeterIfEmpty.bind(this))
    }
  }

  checkStrength() {
    const password = this.inputTarget.value
    const strength = this.calculateStrength(password)
    
    this.updateMeter(strength)
    this.updateFeedback(strength, password)
  }

  calculateStrength(password) {
    if (!password) return 0

    let strength = 0
    const checks = {
      length: password.length >= 8,
      lowercase: /[a-z]/.test(password),
      uppercase: /[A-Z]/.test(password),
      numbers: /\d/.test(password),
      special: /[!@#$%^&*(),.?":{}|<>]/.test(password)
    }

    // Score basé sur les critères
    if (checks.length) strength += 1
    if (checks.lowercase) strength += 1
    if (checks.uppercase) strength += 1
    if (checks.numbers) strength += 1
    if (checks.special) strength += 1

    // Bonus pour longueur
    if (password.length >= 12) strength += 1

    return Math.min(strength, 6) // Max 6 (très fort)
  }

  updateMeter(strength) {
    if (!this.hasMeterTarget) return

    const percentage = (strength / 6) * 100
    this.meterTarget.style.width = `${percentage}%`

    // Classes de couleur selon la force
    this.meterTarget.className = "password-strength-meter"
    
    if (strength <= 2) {
      this.meterTarget.classList.add("password-strength-weak")
    } else if (strength <= 4) {
      this.meterTarget.classList.add("password-strength-medium")
    } else {
      this.meterTarget.classList.add("password-strength-strong")
    }
  }

  updateFeedback(strength, password) {
    if (!this.hasFeedbackTarget) return

    const feedback = this.getFeedbackText(strength, password)
    
    if (feedback.text) {
      if (this.hasStrengthTextTarget) {
        this.strengthTextTarget.textContent = feedback.text
        this.strengthTextTarget.className = `password-strength-text ${feedback.class}`
      } else {
        // Fallback : mettre le texte directement dans feedback
        this.feedbackTarget.innerHTML = `<span class="${feedback.class}">${feedback.text}</span>`
      }
      this.feedbackTarget.style.display = "block"
    } else {
      this.feedbackTarget.style.display = "none"
    }
  }

  getFeedbackText(strength, password) {
    if (!password) {
      return { text: "", class: "" }
    }

    if (strength <= 2) {
      return { 
        text: "Faible - Ajoutez des majuscules, chiffres ou caractères spéciaux", 
        class: "text-danger" 
      }
    } else if (strength <= 4) {
      return { 
        text: "Moyen - Ajoutez des caractères spéciaux pour renforcer", 
        class: "text-warning" 
      }
    } else {
      return { 
        text: "Fort - Excellent mot de passe !", 
        class: "text-success" 
      }
    }
  }

  showMeter() {
    const container = this.meterTarget?.closest(".password-strength-container")
    if (container) {
      container.classList.remove("d-none")
    }
  }

  hideMeterIfEmpty() {
    if (!this.inputTarget.value) {
      const container = this.meterTarget?.closest(".password-strength-container")
      if (container) {
        container.classList.add("d-none")
      }
      if (this.hasFeedbackTarget) {
        this.feedbackTarget.style.display = "none"
      }
    }
  }
}

