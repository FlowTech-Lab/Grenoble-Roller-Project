import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="event-form"
export default class extends Controller {
  static targets = ["levelSelect", "distanceInput", "routeSelect"]

  connect() {
    // Si un parcours est déjà sélectionné au chargement, pré-remplir les champs
    if (this.hasRouteSelectTarget && this.routeSelectTarget.value) {
      this.loadRouteInfo(this.routeSelectTarget.value)
    }

    // Sauvegarde automatique conforme RGPD
    this.storageKey = 'event_draft'
    this.storageExpiryDays = 7 // Durée maximale RGPD pour données temporaires
    
    // Restaurer les données sauvegardées au chargement
    this.restoreDraft()
    
    // Sauvegarder automatiquement lors des modifications
    this.setupAutoSave()
    
    // Nettoyer après soumission réussie
    this.setupCleanup()
  }

  loadRouteInfo(routeId) {
    if (!routeId || routeId === '') {
      // Si aucun parcours sélectionné, vider les champs
      if (this.hasLevelSelectTarget) {
        this.levelSelectTarget.value = ''
      }
      if (this.hasDistanceInputTarget) {
        this.distanceInputTarget.value = ''
      }
      return
    }

    // Récupérer les infos du parcours
    fetch(`/routes/${routeId}/info`)
      .then(response => {
        if (!response.ok) {
          throw new Error('Erreur lors du chargement du parcours')
        }
        return response.json()
      })
      .then(data => {
        // Pré-remplir les champs
        if (this.hasLevelSelectTarget && data.level) {
          this.levelSelectTarget.value = data.level
        }
        if (this.hasDistanceInputTarget && data.distance_km) {
          this.distanceInputTarget.value = data.distance_km
        }
      })
      .catch(error => {
        console.error('Erreur:', error)
      })
  }

  routeChanged(event) {
    const routeId = event.target.value
    this.loadRouteInfo(routeId)
    // Sauvegarder après changement de parcours
    this.saveDraft()
  }

  // ========================================
  // SAUVEGARDE AUTOMATIQUE (RGPD COMPLIANT)
  // ========================================

  // Vérifier si l'utilisateur a accepté les cookies de préférences
  hasCookieConsent() {
    try {
      const consentCookie = this.getCookie('cookie_consent')
      if (!consentCookie) return false
      
      const consentData = JSON.parse(consentCookie)
      return consentData.preferences === true
    } catch (e) {
      return false
    }
  }

  // Obtenir un cookie par nom
  getCookie(name) {
    const value = `; ${document.cookie}`
    const parts = value.split(`; ${name}=`)
    if (parts.length === 2) return parts.pop().split(';').shift()
    return null
  }

  // Sauvegarder les données du formulaire
  saveDraft() {
    const formData = this.collectFormData()
    if (Object.keys(formData).length === 0) return

    const draftData = {
      data: formData,
      timestamp: new Date().toISOString(),
      expiresAt: new Date(Date.now() + this.storageExpiryDays * 24 * 60 * 60 * 1000).toISOString()
    }

    try {
      if (this.hasCookieConsent()) {
        // Utiliser les cookies si consentement donné
        this.setCookie(this.storageKey, JSON.stringify(draftData), this.storageExpiryDays)
      } else {
        // Sinon utiliser localStorage (stockage local uniquement)
        localStorage.setItem(this.storageKey, JSON.stringify(draftData))
      }
      
      // Afficher un indicateur discret de sauvegarde
      this.showSaveIndicator()
    } catch (e) {
      console.warn('Impossible de sauvegarder le brouillon:', e)
    }
  }

  // Collecter toutes les données du formulaire
  collectFormData() {
    const form = this.element.querySelector('form')
    if (!form) return {}

    const formData = {}
    const inputs = form.querySelectorAll('input, select, textarea')
    
    inputs.forEach(input => {
      // Ignorer les champs cachés système (CSRF, etc.)
      if (input.type === 'hidden' && (input.name === 'authenticity_token' || input.name === 'utf8')) {
        return
      }
      
      // Ignorer les fichiers (ne peuvent pas être sauvegardés)
      if (input.type === 'file') {
        return
      }

      const name = input.name
      if (name) {
        if (input.type === 'checkbox') {
          formData[name] = input.checked
        } else {
          formData[name] = input.value
        }
      }
    })

    return formData
  }

  // Restaurer les données sauvegardées
  restoreDraft() {
    let draftData = null

    try {
      if (this.hasCookieConsent()) {
        // Récupérer depuis les cookies
        const cookieData = this.getCookie(this.storageKey)
        if (cookieData) {
          draftData = JSON.parse(cookieData)
        }
      } else {
        // Récupérer depuis localStorage
        const localData = localStorage.getItem(this.storageKey)
        if (localData) {
          draftData = JSON.parse(localData)
        }
      }

      if (!draftData) return

      // Vérifier l'expiration
      const expiresAt = new Date(draftData.expiresAt)
      if (expiresAt < new Date()) {
        this.clearDraft()
        return
      }

      // Restaurer les champs (uniquement si le formulaire est vide)
      if (this.isFormEmpty()) {
        this.fillFormData(draftData.data)
        this.showRestoreMessage()
      }
    } catch (e) {
      console.warn('Impossible de restaurer le brouillon:', e)
      this.clearDraft()
    }
  }

  // Vérifier si le formulaire est vide
  isFormEmpty() {
    const form = this.element.querySelector('form')
    if (!form) return true

    const inputs = form.querySelectorAll('input[type="text"], input[type="number"], input[type="datetime-local"], textarea, select')
    for (const input of inputs) {
      if (input.name && input.value && input.name !== 'authenticity_token' && input.name !== 'utf8') {
        return false
      }
    }
    return true
  }

  // Remplir le formulaire avec les données sauvegardées
  fillFormData(data) {
    const form = this.element.querySelector('form')
    if (!form) return

    Object.keys(data).forEach(name => {
      const input = form.querySelector(`[name="${name}"]`)
      if (input) {
        if (input.type === 'checkbox') {
          input.checked = data[name] === true || data[name] === 'true'
        } else {
          input.value = data[name]
          // Déclencher les événements pour les champs avec listeners
          input.dispatchEvent(new Event('change', { bubbles: true }))
        }
      }
    })
  }

  // Configurer la sauvegarde automatique
  setupAutoSave() {
    const form = this.element.querySelector('form')
    if (!form) return

    // Sauvegarder lors des modifications (debounce pour éviter trop de sauvegardes)
    let saveTimeout
    form.addEventListener('input', () => {
      clearTimeout(saveTimeout)
      saveTimeout = setTimeout(() => {
        this.saveDraft()
      }, 1000) // Sauvegarder 1 seconde après la dernière modification
    })

    form.addEventListener('change', () => {
      clearTimeout(saveTimeout)
      saveTimeout = setTimeout(() => {
        this.saveDraft()
      }, 500)
    })
  }

  // Configurer le nettoyage après soumission
  setupCleanup() {
    const form = this.element.querySelector('form')
    if (!form) return

    form.addEventListener('submit', () => {
      // Nettoyer immédiatement après soumission
      setTimeout(() => {
        this.clearDraft()
      }, 100)
    })
  }

  // Nettoyer les données sauvegardées
  clearDraft() {
    try {
      if (this.hasCookieConsent()) {
        this.deleteCookie(this.storageKey)
      } else {
        localStorage.removeItem(this.storageKey)
      }
    } catch (e) {
      console.warn('Impossible de nettoyer le brouillon:', e)
    }
  }

  // Définir un cookie
  setCookie(name, value, days) {
    const expires = new Date()
    expires.setTime(expires.getTime() + days * 24 * 60 * 60 * 1000)
    document.cookie = `${name}=${value};expires=${expires.toUTCString()};path=/;SameSite=Lax`
  }

  // Supprimer un cookie
  deleteCookie(name) {
    document.cookie = `${name}=;expires=Thu, 01 Jan 1970 00:00:00 UTC;path=/;`
  }

  // Afficher un indicateur discret de sauvegarde
  showSaveIndicator() {
    // Créer ou mettre à jour un indicateur discret
    let indicator = document.getElementById('draft-save-indicator')
    if (!indicator) {
      indicator = document.createElement('div')
      indicator.id = 'draft-save-indicator'
      indicator.className = 'position-fixed bottom-0 end-0 m-3'
      indicator.style.cssText = 'z-index: 1040; font-size: 0.75rem; color: var(--bs-success);'
      document.body.appendChild(indicator)
    }
    
    indicator.innerHTML = '<i class="bi bi-check-circle me-1"></i>Brouillon sauvegardé'
    indicator.style.opacity = '1'
    
    // Faire disparaître après 2 secondes
    setTimeout(() => {
      indicator.style.transition = 'opacity 0.5s'
      indicator.style.opacity = '0'
    }, 2000)
  }

  // Afficher un message de restauration
  showRestoreMessage() {
    const form = this.element.querySelector('form')
    if (!form) return

    // Créer un message informatif en haut du formulaire
    const alertDiv = document.createElement('div')
    alertDiv.className = 'alert alert-info alert-dismissible fade show mb-3'
    alertDiv.innerHTML = `
      <i class="bi bi-info-circle me-2"></i>
      <strong>Brouillon restauré</strong> : Vos données précédemment saisies ont été restaurées.
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Fermer"></button>
    `
    
    const firstChild = form.firstElementChild
    if (firstChild) {
      form.insertBefore(alertDiv, firstChild)
    } else {
      form.appendChild(alertDiv)
    }

    // Auto-fermer après 5 secondes
    setTimeout(() => {
      if (alertDiv.parentNode) {
        alertDiv.classList.remove('show')
        setTimeout(() => alertDiv.remove(), 300)
      }
    }, 5000)
  }
}
