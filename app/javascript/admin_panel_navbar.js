// ============================================
// ADMIN PANEL - Calcul dynamique hauteur navbar
// ============================================

document.addEventListener('DOMContentLoaded', function() {
  const navbar = document.querySelector('.navbar');
  if (navbar) {
    const navbarHeight = navbar.offsetHeight;
    document.documentElement.style.setProperty('--navbar-height', navbarHeight + 'px');
    
    // Mettre à jour la sidebar
    const sidebar = document.getElementById('sidebar');
    if (sidebar) {
      sidebar.style.top = navbarHeight + 'px';
      sidebar.style.height = `calc(100vh - ${navbarHeight}px)`;
    }
  }
});
