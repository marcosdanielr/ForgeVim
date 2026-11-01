import { english, portuguese, type TranslationKey } from '@/lib/messages';

export type Locale = 'en' | 'pt';
export function localeFromPath(pathname: string): Locale {
  return pathname === '/pt' || pathname.startsWith('/pt/') ? 'pt' : 'en';
}
export function localePath(pathname: string, locale: Locale): string {
  const plain = pathname.replace(/^\/pt(?=\/|$)/, '') || '/';
  return locale === 'pt' ? '/pt' + plain : plain;
}
export function pageLocale(pathname: string): {
  locale: Locale;
  t: (key: TranslationKey) => string;
  path: (href: string) => string;
} {
  const locale = localeFromPath(pathname);
  const dictionary = locale === 'pt' ? portuguese : english;
  return { locale, t: (key) => dictionary[key], path: (href) => localePath(href, locale) };
}
