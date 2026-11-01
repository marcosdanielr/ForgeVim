import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://forge-nvim-marcos.upbeat-corgi-3005.chatgpt.site',
  output: 'static',
  compressHTML: false,
  vite: { plugins: [tailwindcss()] },
});
