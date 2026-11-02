import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { afterEach, beforeEach, test } from 'node:test';

const script = resolve('scripts/deploy/ignore-build.mjs');
let directory;
let initial;
function git(...args) {
  return execFileSync('git', args, { cwd: directory, encoding: 'utf8' }).trim();
}
function commit(path) {
  const file = join(directory, path);
  mkdirSync(resolve(file, '..'), { recursive: true });
  writeFileSync(file, `${path} ${Math.random()}`);
  git('add', '.');
  git('commit', '-m', 'test: update fixture');
}
function decision(previous = initial, reference = 'main', force = '') {
  return spawnSync(process.execPath, [script], {
    cwd: directory,
    env: {
      ...process.env,
      VERCEL_GIT_COMMIT_REF: reference,
      VERCEL_GIT_PREVIOUS_SHA: previous,
      FORGE_WEB_FORCE_BUILD: force,
    },
    encoding: 'utf8',
  }).status;
}
beforeEach(() => {
  directory = mkdtempSync(join(tmpdir(), 'forgevim-deploy-'));
  git('init', '-b', 'main');
  git('config', 'user.name', 'Deployment test');
  git('config', 'user.email', 'deployment@example.com');
  commit('README.md');
  initial = git('rev-parse', 'HEAD');
});
afterEach(() => rmSync(directory, { recursive: true, force: true }));

test('first deployment builds even without website changes', () => assert.equal(decision(''), 1));
test('editor-only changes skip the website', () => {
  commit('apps/nvim/init.lua');
  assert.equal(decision(), 0);
});
test('website changes build across multiple commits since the last deployment', () => {
  commit('apps/web/src/pages/index.astro');
  commit('apps/nvim/init.lua');
  assert.equal(decision(), 1);
});
test('imported language docs and workspace inputs trigger builds', () => {
  for (const path of ['apps/web/src/content/docs/en/languages.mdx', 'pnpm-lock.yaml', 'vercel.json']) {
    const previous = git('rev-parse', 'HEAD');
    commit(path);
    assert.equal(decision(previous), 1);
  }
});
test('non-main branches skip automatic builds', () => {
  commit('apps/web/src/pages/index.astro');
  assert.equal(decision(initial, 'feature/test'), 0);
});
test('missing comparison history builds instead of silently skipping', () =>
  assert.equal(decision('a'.repeat(40)), 1));
test('manual override can rebuild unchanged inputs', () =>
  assert.equal(decision(initial, 'main', '1'), 1));
