---
name: forge-web
description: Maintain Forge.nvim landing page, brand assets, and documentation in Astro with strict TypeScript and accessible interactions.
---

Read `AGENTS.md` and `docs/design.md`. Keep the site under `apps/web`; keep shared
presentation components, typed content in `lib`, and `cn` in `utils`. Use Tailwind
utilities and existing CSS tokens. Preserve the site's visual hierarchy and native
editor identity; do not add generic feature grids, fabricated metrics, or claims
for roadmap-only capabilities.

TypeScript must remain strict with no explicit any. Run `pnpm format`,
`pnpm lint`, `pnpm check`, and `pnpm build`. Import sorting is enforced
by ESLint and Tailwind sorting by Prettier. Verify desktop and narrow-screen
layouts, keyboard tabs, copy feedback, documentation navigation, and focus states.
Keep donation and repository URLs in `src/lib/site.ts`. Treat the repository as
private until the owner explicitly changes its audience.

Code and contributor documentation use English. Preserve both English and
Portuguese reader routes. English is the static default; a browser preference
may select Portuguese unless the user saved a manual choice. Teach installation and daily use in both languages. Keep internal domain rules,
requirements, architecture, and contributor checks in the English repository docs.
