import { pageLocale } from '@/i18n';

const { t } = pageLocale(window.location.pathname);

export function bindCopyButtons(): void {
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
