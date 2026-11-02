import { glob } from 'astro/loaders';
import { z } from 'astro/zod';
import { defineCollection } from 'astro:content';

const docs = defineCollection({
  loader: glob({ pattern: '**/*.mdx', base: './src/content/docs' }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    navigationTitle: z.string(),
    locale: z.enum(['en', 'pt']),
    route: z.string(),
    order: z.number().int(),
  }),
});

export const collections = { docs };
