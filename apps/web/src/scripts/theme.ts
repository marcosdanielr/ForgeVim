import { pageLocale } from '@/lib/i18n';

export type ThemePreference = 'system' | 'light' | 'dark';

function isThemePreference(value: string | null): value is ThemePreference {
  return value === 'system' || value === 'light' || value === 'dark';
}

function readPreference(): ThemePreference {
  try {
    const saved = localStorage.getItem('forge-theme');
    return isThemePreference(saved) ? saved : 'system';
  } catch {
    return 'system';
  }
}

export function initializeTheme(): void {
  const { t } = pageLocale(window.location.pathname);
  const media = window.matchMedia('(prefers-color-scheme: dark)');
  const choices = document.querySelectorAll<HTMLButtonElement>('[data-theme-choice]');
  const labels = document.querySelectorAll<HTMLElement>('[data-theme-label]');
  const names: Record<ThemePreference, string> = {
    system: t('theme.auto'),
    light: t('theme.light'),
    dark: t('theme.dark'),
  };
  let preference = readPreference();

  function apply(): void {
    document.documentElement.dataset.theme =
      preference === 'system' ? (media.matches ? 'dark' : 'light') : preference;
    choices.forEach((button) => {
      button.setAttribute('aria-pressed', String(button.dataset.themeChoice === preference));
    });
    labels.forEach((label) => {
      label.textContent = names[preference];
    });
  }

  choices.forEach((button) => {
    button.addEventListener('click', () => {
      const choice = button.dataset.themeChoice ?? null;
      if (!isThemePreference(choice)) return;
      preference = choice;
      try {
        localStorage.setItem('forge-theme', preference);
      } catch {
        /* The theme still works without storage. */
      }
      apply();
      const menu = button.closest('details');
      if (menu) menu.open = false;
      menu?.querySelector('summary')?.focus();
    });
  });
  media.addEventListener('change', () => {
    if (preference === 'system') apply();
  });
  apply();
}
