//= require active_admin/base

document.addEventListener('DOMContentLoaded', () => {
  const root = document.documentElement;
  const storageKey = 'grenoble-roller-admin-theme';

  const setTheme = (theme) => {
    root.setAttribute('data-theme', theme);
    localStorage.setItem(storageKey, theme);
    if (toggleButton) {
      toggleButton.dataset.theme = theme;
      toggleButton.innerHTML = theme === 'dark' ? '🌙 Mode nuit' : '🌞 Mode jour';
      toggleButton.setAttribute('aria-label', theme === 'dark' ? 'Basculer en mode jour' : 'Basculer en mode nuit');
    }
  };

  const currentTheme =
    localStorage.getItem(storageKey) ||
    (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');

  let toggleButton;

  const createToggle = () => {
    toggleButton = document.createElement('button');
    toggleButton.type = 'button';
    toggleButton.className = 'theme-toggle';
    toggleButton.dataset.theme = currentTheme;
    toggleButton.innerHTML = currentTheme === 'dark' ? '🌙 Mode nuit' : '🌞 Mode jour';
    toggleButton.setAttribute('aria-label', currentTheme === 'dark' ? 'Basculer en mode jour' : 'Basculer en mode nuit');

    toggleButton.addEventListener('click', () => {
      const nextTheme = (toggleButton.dataset.theme === 'dark') ? 'light' : 'dark';
      setTheme(nextTheme);
    });

    const utilityNav = document.querySelector('#utility_nav');
    if (utilityNav) {
      const li = document.createElement('li');
      li.appendChild(toggleButton);
      utilityNav.appendChild(li);
    } else {
      document.body.appendChild(toggleButton);
    }
  };

  createToggle();
  setTheme(currentTheme);
});
