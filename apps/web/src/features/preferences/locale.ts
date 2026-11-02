export function bindLocaleLinks(): void {
  document.querySelectorAll<HTMLAnchorElement>('[data-locale-choice]').forEach((link) => {
    link.addEventListener('click', () => {
      const locale = link.dataset.localeChoice;
      if (locale !== 'en' && locale !== 'pt') return;
      try {
        localStorage.setItem('forge-locale', locale);
      } catch {
        // The language-specific URL still works without persistent storage.
      }
    });
  });
}
