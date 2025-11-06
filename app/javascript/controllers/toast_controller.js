import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toast"
export default class extends Controller {
  connect() {
    // Utiliser requestAnimationFrame pour s'assurer que le DOM est prêt
    // Cela résout les problèmes de timing avec Turbo
    requestAnimationFrame(() => {
      this.initializeToast()
    })
  }

  initializeToast() {
    // Accéder à Bootstrap via window car il est chargé via importmap
    // Bootstrap.bundle.min.js expose Bootstrap globalement
    const bootstrap = window.bootstrap
    
    // Vérifier que Bootstrap est disponible
    if (!bootstrap || !bootstrap.Toast) {
      console.error('Bootstrap Toast is not available', bootstrap)
      return
    }

    // Créer et afficher le toast
    const toastElement = this.element
    const toast = new bootstrap.Toast(toastElement, {
      autohide: toastElement.dataset.bsAutohide !== 'false',
      delay: parseInt(toastElement.dataset.bsDelay) || 5000
    })
    
    toast.show()

    // Nettoyer après que le toast soit caché
    toastElement.addEventListener('hidden.bs.toast', () => {
      toast.dispose()
    })
  }
}

