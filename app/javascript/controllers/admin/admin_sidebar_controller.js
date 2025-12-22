import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar"]
  
  // Constantes (Solution #2: Pas de magic strings)
  static values = {
    collapsedWidth: { type: String, default: "64px" },
    expandedWidth: { type: String, default: "280px" },
    breakpoint: { type: Number, default: 992 },
    debounceMs: { type: Number, default: 250 }
  }
  
  // Cache des références DOM (Solution #4: Pas de requêtes répétées)
  static classes = ["collapsed", "d-none"]
  
  connect() {
    // Guard clause (Solution #6: Early return)
    if (!this.sidebarTarget) return
    
    // Cache des références DOM
    this.cacheRefs()
    
    // Restaurer l'état sauvegardé
    this.restoreState()
    
    // Observer responsive (Solution #3: Media query observer)
    this.setupMediaQueryObserver()
    
    // Debounce resize (Solution #1: Pas de CPU spike)
    this.setupResizeHandler()
  }
  
  disconnect() {
    // Cleanup listeners (Solution #7: Pas de memory leak)
    if (this.resizeHandler) {
      window.removeEventListener('resize', this.resizeHandler)
      this.resizeHandler = null
    }
    
    if (this.mediaQuery && this.mediaQueryHandler) {
      if (this.mediaQuery.removeEventListener) {
        this.mediaQuery.removeEventListener('change', this.mediaQueryHandler)
      } else {
        // Fallback pour anciens navigateurs
        this.mediaQuery.removeListener(this.mediaQueryHandler)
      }
      this.mediaQuery = null
      this.mediaQueryHandler = null
    }
    
    // Nettoyer les références
    this.mainContent = null
    this.labels = null
    this.chevrons = null
  }
  
  // Cache des références DOM (Solution #4)
  cacheRefs() {
    this.mainContent = document.querySelector('.admin-main-content')
    this.labels = this.sidebarTarget.querySelectorAll('.sidebar-label')
    this.chevrons = this.sidebarTarget.querySelectorAll('.bi-chevron-right, .bi-chevron-down')
  }
  
  // Restaurer l'état sauvegardé
  restoreState() {
    const saved = localStorage.getItem('admin:sidebar:collapsed')
    const isDesktop = window.innerWidth >= this.breakpointValue
    
    if (saved === 'true' && isDesktop) {
      this.collapse(false) // false = pas de sauvegarde (déjà sauvegardé)
    } else {
      this.expand(false) // false = pas de sauvegarde
    }
  }
  
  // Media query observer (Solution #3: Responsive breakpoint sync)
  setupMediaQueryObserver() {
    const mediaQuery = window.matchMedia(`(min-width: ${this.breakpointValue}px)`)
    
    // Bind pour pouvoir le supprimer plus tard
    this.mediaQueryHandler = (e) => {
      if (e.matches) {
        // Desktop: restaurer l'état sauvegardé
        this.restoreState()
      } else {
        // Mobile: toujours expanded (offcanvas gère ça)
        this.expand(false)
      }
    }
    
    // Utiliser addEventListener pour pouvoir le supprimer
    if (mediaQuery.addEventListener) {
      mediaQuery.addEventListener('change', this.mediaQueryHandler)
    } else {
      // Fallback pour anciens navigateurs
      mediaQuery.addListener(this.mediaQueryHandler)
    }
    
    // Appeler une fois pour l'état initial
    this.mediaQueryHandler(mediaQuery)
    
    // Stocker la mediaQuery pour cleanup
    this.mediaQuery = mediaQuery
  }
  
  // Debounce resize (Solution #1: Pas de CPU spike)
  setupResizeHandler() {
    this.debouncedResize = this.debounce(() => {
      // Guard clause (Solution #6)
      if (!this.sidebarTarget) return
      
      const isDesktop = window.innerWidth >= this.breakpointValue
      if (!isDesktop) return
      
      // Réajuster la marge si nécessaire
      this.updateMainContentMargin()
    }, this.debounceMsValue)
    
    this.resizeHandler = () => this.debouncedResize()
    window.addEventListener('resize', this.resizeHandler)
  }
  
  // Helper debounce
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
  
  toggle(event) {
    event?.preventDefault()
    
    // Guard clause (Solution #6)
    if (!this.sidebarTarget) return
    
    if (this.sidebarTarget.classList.contains('collapsed')) {
      this.expand()
    } else {
      this.collapse()
    }
  }
  
  collapse(save = true) {
    // Guard clause (Solution #6)
    if (!this.sidebarTarget) return
    
    const sidebar = this.sidebarTarget
    
    // Utiliser Bootstrap classes (Solution #5: Pas de style inline)
    sidebar.classList.add('collapsed')
    sidebar.style.width = this.collapsedWidthValue
    
    // Ajuster le contenu principal
    this.updateMainContentMargin()
    
    // Masquer les labels et chevrons avec Bootstrap (Solution #5)
    this.labels?.forEach(label => label.classList.add('d-none'))
    this.chevrons?.forEach(chevron => chevron.classList.add('d-none'))
    
    if (save) {
      localStorage.setItem('admin:sidebar:collapsed', 'true')
    }
  }
  
  expand(save = true) {
    // Guard clause (Solution #6)
    if (!this.sidebarTarget) return
    
    const sidebar = this.sidebarTarget
    
    // Utiliser Bootstrap classes (Solution #5: Pas de style inline)
    sidebar.classList.remove('collapsed')
    sidebar.style.width = this.expandedWidthValue
    
    // Ajuster le contenu principal
    this.updateMainContentMargin()
    
    // Afficher les labels et chevrons avec Bootstrap (Solution #5)
    this.labels?.forEach(label => label.classList.remove('d-none'))
    this.chevrons?.forEach(chevron => chevron.classList.remove('d-none'))
    
    if (save) {
      localStorage.setItem('admin:sidebar:collapsed', 'false')
    }
  }
  
  updateMainContentMargin() {
    // Guard clause (Solution #6)
    if (!this.mainContent || !this.sidebarTarget) return
    
    const isCollapsed = this.sidebarTarget.classList.contains('collapsed')
    this.mainContent.style.marginLeft = isCollapsed ? this.collapsedWidthValue : this.expandedWidthValue
  }
}
