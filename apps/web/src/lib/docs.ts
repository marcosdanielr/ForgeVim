import { docsEn } from '@/lib/docs/en';
import { docsPt } from '@/lib/docs/pt';
import type { DocPage } from '@/lib/docs-types';
import type { Locale } from '@/lib/i18n';

export type { DocPage, DocSection, DocTable } from '@/lib/docs-types';
export const docs = docsEn;
export function getDocs(locale: Locale): readonly DocPage[] {
  return locale === 'pt' ? docsPt : docsEn;
}
