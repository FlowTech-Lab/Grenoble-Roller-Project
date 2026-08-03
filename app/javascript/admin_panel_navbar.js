// ============================================
// ADMIN PANEL - Calcul dynamique hauteur navbar
// ============================================

function syncAdminNavbarHeight() {
  const navbar = document.querySelector('body.admin-panel .navbar-grenoble-roller, .navbar');
  if (!navbar) return;

  // Visible bar height only (collapsed menu must not inflate --navbar-height)
  const navbarHeight = Math.round(navbar.getBoundingClientRect().height);
  document.documentElement.style.setProperty('--navbar-height', `${navbarHeight}px`);

  const sidebar = document.getElementById('sidebar');
  if (sidebar) {
    sidebar.style.top = `${navbarHeight}px`;
    sidebar.style.height = `calc(100vh - ${navbarHeight}px)`;
  }
}

document.addEventListener('DOMContentLoaded', syncAdminNavbarHeight);
document.addEventListener('turbo:load', syncAdminNavbarHeight);
window.addEventListener('resize', syncAdminNavbarHeight);
