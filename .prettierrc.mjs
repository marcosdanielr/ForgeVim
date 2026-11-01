export default {
  singleQuote: true,
  printWidth: 100,
  plugins: ['prettier-plugin-astro', 'prettier-plugin-tailwindcss'],
  tailwindStylesheet: './apps/web/src/styles/global.css',
  tailwindFunctions: ['cn', 'clsx'],
  overrides: [{ files: '*.astro', options: { parser: 'astro' } }],
};
