import { spawnSync } from 'node:child_process';

// Vercel convention: exit 0 skips the deployment; exit 1 continues the build.
const reference = process.env.VERCEL_GIT_COMMIT_REF;
const previous = process.env.VERCEL_GIT_PREVIOUS_SHA;
const inputs = [
  'apps/web',
  'package.json',
  'pnpm-lock.yaml',
  'pnpm-workspace.yaml',
  '.npmrc',
  '.nvmrc',
  '.node-version',
  'vercel.json',
  'scripts/deploy/ignore-build.mjs',
];

function decide() {
  if (reference && reference !== 'main') {
    console.log('Skip: automatic website deployments use main only.');
    return 0;
  }
  if (
    process.env.FORGE_WEB_FORCE_BUILD === '1' ||
    !previous ||
    !/^[a-f0-9]{40,64}$/i.test(previous)
  ) {
    console.log('Build: first deployment, explicit override, or no comparison commit.');
    return 1;
  }
  const result = spawnSync('git', ['diff', '--quiet', previous, 'HEAD', '--', ...inputs], {
    stdio: 'ignore',
    timeout: 10000,
  });
  if (result.status === 0) {
    console.log('Skip: website inputs match the last successful deployment.');
    return 0;
  }
  console.log('Build: website inputs changed or Git comparison is unavailable.');
  return 1;
}

process.exitCode = decide();
