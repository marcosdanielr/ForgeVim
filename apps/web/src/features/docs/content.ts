import { type CollectionEntry, getCollection } from 'astro:content';

import type { Locale } from '@/i18n';

export type DocPage = CollectionEntry<'docs'>['data'] & {
  slug: string;
  entry: CollectionEntry<'docs'>;
};

export async function getDocs(locale: Locale): Promise<readonly DocPage[]> {
  const entries = await getCollection('docs', ({ data }) => data.locale === locale);
  return entries
    .sort((left, right) => left.data.order - right.data.order)
    .map((entry) => ({ ...entry.data, slug: entry.data.route, entry }));
}
