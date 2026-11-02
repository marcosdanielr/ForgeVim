import { pageLocale } from '@/i18n';

const { t } = pageLocale(window.location.pathname);

export function bindDocsSearch(): void {
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
