import { bindCopyButtons } from '@/features/clipboard/copy';
import { bindDocsSearch } from '@/features/docs/navigation';
import { bindLocaleLinks } from '@/features/preferences/locale';
import { initializeTheme } from '@/features/preferences/theme';

bindCopyButtons();
bindDocsSearch();
bindLocaleLinks();
initializeTheme();
