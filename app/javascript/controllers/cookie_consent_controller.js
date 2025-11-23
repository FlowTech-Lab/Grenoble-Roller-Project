import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="cookie-consent"
// Gère le banner de consentement aux cookies conforme RGPD 2025
export default class extends Controller {
  static targets = ["banner", "acceptButton", "rejectButton"]
  static values = {
    acceptUrl: String,
    rejectUrl: String
  }

  connect() {
    // Utiliser requestAnimationFrame pour s'assurer que le DOM est prêt
    // Cela résout les problèmes de timing avec Turbo
    requestAnimationFrame(() => {
      this.checkConsent()
    })
  }

  // Vérifier si le consentement existe et afficher/masquer le banner
  checkConsent() {
    if (!this.hasConsent()) {
      this.showBanner()
    } else {
      this.hideBanner()
    }
  }

  // Vérifier si un consentement existe dans les cookies
  hasConsent() {
    const consentCookie = this.getCookie('cookie_consent')
    return consentCookie !== null && consentCookie !== ''
  }

  // Obtenir un cookie
  getCookie(name) {
    const value = `; ${document.cookie}`
    const parts = value.split(`; ${name}=`)
    if (parts.length === 2) {
      try {
        return JSON.parse(decodeURIComponent(parts.pop().split(';').shift()))
      } catch (e) {
        return parts.pop().split(';').shift()
      }
    }
    return null
  }

  // Afficher le banner
  showBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.style.display = 'block'
      this.bannerTarget.setAttribute('aria-hidden', 'false')
      // Ajouter une classe pour l'animation
      setTimeout(() => {
        this.bannerTarget.classList.add('cookie-banner-visible')
      }, 10)
    }
  }

  // Masquer le banner
  hideBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.style.display = 'none'
      this.bannerTarget.setAttribute('aria-hidden', 'true')
    }
  }

  // Accepter tous les cookies
  accept(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
      event.stopImmediatePropagation()
    }
    const url = this.acceptUrlValue || this.element.dataset.cookieConsentAcceptUrlValue
    if (!url) {
      console.error('Accept URL not found')
      return
    }
    this.sendConsent(url, 'accept')
  }

  // Rejeter les cookies non essentiels
  reject(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
      event.stopImmediatePropagation()
    }
    const url = this.rejectUrlValue || this.element.dataset.cookieConsentRejectUrlValue
    if (!url) {
      console.error('Reject URL not found')
      return
    }
    this.sendConsent(url, 'reject')
  }

  // Envoyer le consentement au serveur
  async sendConsent(url, action) {
    // Désactiver les boutons pendant la requête
    this.setButtonsDisabled(true)

    try {
      const csrfToken = this.getCsrfToken()
      if (!csrfToken) {
        throw new Error('CSRF token not found')
      }

      // S'assurer que l'URL est absolue si nécessaire
      const fullUrl = url.startsWith('http') ? url : `${window.location.origin}${url}`

      const response = await fetch(fullUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        },
        credentials: 'same-origin',
        redirect: 'manual' // Ne pas suivre les redirections automatiquement
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      
      // Masquer le banner
      this.hideBanner()
      
      // Recharger la page pour appliquer les changements
      // Utiliser Turbo si disponible, sinon window.location
      if (typeof Turbo !== 'undefined') {
        Turbo.visit(window.location.href, { action: 'replace' })
      } else {
        window.location.reload()
      }
    } catch (error) {
      console.error('Error saving cookie consent:', error)
      // En cas d'erreur, masquer quand même le banner pour éviter de bloquer l'utilisateur
      this.hideBanner()
      this.setButtonsDisabled(false)
    }
  }

  // Obtenir le token CSRF
  getCsrfToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]')
    return metaTag ? metaTag.content : null
  }

  // Activer/désactiver les boutons
  setButtonsDisabled(disabled) {
    if (this.hasAcceptButtonTarget) {
      this.acceptButtonTarget.disabled = disabled
    }
    if (this.hasRejectButtonTarget) {
      this.rejectButtonTarget.disabled = disabled
    }
  }

  // Exposer la méthode pour ouvrir le banner depuis d'autres pages
  show() {
    this.showBanner()
  }
}

// Exposer globalement pour compatibilité avec les liens depuis d'autres pages
window.showCookieConsent = function() {
  const element = document.querySelector('[data-controller*="cookie-consent"]')
  if (element && window.Stimulus) {
    const controller = window.Stimulus.getControllerForElementAndIdentifier(element, 'cookie-consent')
    if (controller) {
      controller.show()
    }
  }
}

