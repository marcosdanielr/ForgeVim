import { pageLocale } from '@/lib/i18n';
import { initializeTheme } from '@/scripts/theme';

const { t } = pageLocale(window.location.pathname);

/** Small progressive enhancements. The content remains readable without JavaScript. */
function bindCopyButtons(): void {
  document.querySelectorAll<HTMLButtonElement>('[data-copy]').forEach((button) => {
    button.addEventListener('click', () => {
      const command = button.dataset.copy;
      const label = button.querySelector<HTMLElement>('[data-copy-label]');
      const status = button
        .closest('[data-copy-block]')
        ?.querySelector<HTMLElement>('[data-copy-status]');
      if (!command || !label) return;
      void navigator.clipboard
        .writeText(command)
        .then(() => {
          label.textContent = t('copy.done');
          if (status) status.textContent = t('copy.success');
          window.setTimeout(() => {
            label.textContent = t('copy.action');
          }, 2000);
        })
        .catch(() => {
          label.textContent = t('copy.select');
          if (status) status.textContent = t('copy.failed');
        });
    });
  });
}

function bindDemoTabs(): void {
  const tabs = Array.from(document.querySelectorAll<HTMLButtonElement>('[data-demo-tab]'));
  const panels = document.querySelectorAll<HTMLElement>('[data-demo-panel]');
  function selectTab(selected: HTMLButtonElement): void {
    tabs.forEach((tab) => {
      const active = tab === selected;
      tab.setAttribute('aria-selected', String(active));
      tab.tabIndex = active ? 0 : -1;
    });
    panels.forEach((panel) => {
      panel.hidden = panel.dataset.demoPanel !== selected.dataset.demoTab;
    });
  }
  tabs.forEach((tab, index) => {
    tab.addEventListener('click', () => {
      selectTab(tab);
    });
    tab.addEventListener('keydown', (event) => {
      let next: HTMLButtonElement | undefined;
      if (event.key === 'ArrowRight') next = tabs[(index + 1) % tabs.length];
      if (event.key === 'ArrowLeft') next = tabs[(index - 1 + tabs.length) % tabs.length];
      if (event.key === 'Home') next = tabs[0];
      if (event.key === 'End') next = tabs[tabs.length - 1];
      if (next) {
        event.preventDefault();
        selectTab(next);
        next.focus();
      }
    });
  });
}

function bindDocsSearch(): void {
  const search = document.querySelector<HTMLInputElement>('[data-doc-search]');
  const links = document.querySelectorAll<HTMLAnchorElement>('[data-doc-link]');
  const status = document.querySelector<HTMLElement>('[data-doc-search-status]');
  search?.addEventListener('input', () => {
    const query = search.value.trim().toLocaleLowerCase('pt-BR');
    let count = 0;
    links.forEach((link) => {
      const matches = (link.textContent ?? '').toLocaleLowerCase('pt-BR').includes(query);
      link.hidden = !matches;
      if (matches) count += 1;
    });
    if (status) status.textContent = count === 0 ? t('docs.none') : '';
  });
}

bindCopyButtons();
bindDemoTabs();
bindDocsSearch();

initializeTheme();

document.querySelectorAll<HTMLAnchorElement>('[data-locale-choice]').forEach((link) => {
  link.addEventListener('click', () => {
    const locale = link.dataset.localeChoice;
    if (locale !== 'en' && locale !== 'pt') return;
    try {
      localStorage.setItem('forge-locale', locale);
    } catch {
      /* The URL still selects the language. */
    }
  });
});
