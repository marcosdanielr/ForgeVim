import { env } from 'node:process';

import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from 'astro/config';

export default defineConfig({
  site:
    env.FORGE_WEB_SITE_URL ||
    (env.VERCEL_PROJECT_PRODUCTION_URL && `https://${env.VERCEL_PROJECT_PRODUCTION_URL}`) ||
    'https://forge-nvim-marcos.upbeat-corgi-3005.chatgpt.site',
  output: 'static',
  compressHTML: false,
  vite: { plugins: [tailwindcss()] },
});
