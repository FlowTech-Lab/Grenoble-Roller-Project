import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar"]
  
  connect() {
    // Restaurer l'état sauvegardé
    const saved = localStorage.getItem('admin:sidebar:collapsed')
    if (saved === 'true' && window.innerWidth >= 992) {
      this.collapse()
    }
  }
  
  toggle() {
    if (this.sidebarTarget.classList.contains('collapsed')) {
      this.expand()
    } else {
      this.collapse()
    }
  }
  
  collapse() {
    this.sidebarTarget.classList.add('collapsed')
    this.sidebarTarget.style.width = '64px'
    localStorage.setItem('admin:sidebar:collapsed', 'true')
  }
  
  expand() {
    this.sidebarTarget.classList.remove('collapsed')
    this.sidebarTarget.style.width = '280px'
    localStorage.setItem('admin:sidebar:collapsed', 'false')
  }
}
