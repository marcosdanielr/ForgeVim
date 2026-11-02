# Website deployment

Connect `marcosdanielr/ForgeVim` through Vercel's GitHub integration. Use repository
root `.` as Root Directory, `main` as Production Branch, Astro as Framework
Preset, and Node.js 22.x. Add `ENABLE_EXPERIMENTAL_COREPACK=1` in Vercel to use the
pnpm version pinned in package.json. The committed vercel.json owns install,
build, output, and ignored-build commands. No GitHub deployment token is required.

The build runs `pnpm build` and publishes `apps/web/dist`. Automatic Git deployments
are enabled for main only. The ignore script compares website inputs against
`VERCEL_GIT_PREVIOUS_SHA`, the last successful deployment for this project and
branch. It includes the website, imported English language documentation, pnpm
workspace/dependency files, and deployment configuration. Lua/Python-only changes
do not deploy the site. Several commits between successful deployments are
compared together, so an editor-only final commit cannot hide earlier site edits.

The first deployment builds. Missing Git history or comparison errors also build,
rather than silently dropping updates. Vercel reports skipped deployments as
canceled/ignored; this is expected. Set `FORGE_WEB_FORCE_BUILD=1` temporarily to
force a rebuild with unchanged source. Remove that variable to restore filtering.

Astro uses `FORGE_WEB_SITE_URL` when explicitly set, otherwise Vercel's production
hostname, with the existing hosted URL as a local fallback. Set the explicit URL
when using a preferred custom domain. The source repository remains private;
Vercel deployment protection and domain access are managed separately in Vercel.

After connecting, push a website change to main and confirm a Ready production
deployment in Vercel. A local successful build proves the artifact, not that the
external account connection or domain is configured.

References: [Vercel Git configuration](https://vercel.com/docs/project-configuration/git-configuration),
[ignored build command](https://vercel.com/docs/project-configuration/vercel-json#ignorecommand),
and [Corepack](https://vercel.com/docs/builds/configure-a-build#corepack).
