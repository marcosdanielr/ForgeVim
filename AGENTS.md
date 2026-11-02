# Contributor instructions

ForgeVim is a Neovim distribution, not a replacement editor. Preserve native modes,
motions, buffers, windows, registers, command-line editing, and user configuration.

## Ownership

- `apps/nvim/lua/forge/core`: startup, configuration, commands, and keymaps.
- `apps/nvim/lua/forge/features`: focused editor workflows and UI adapters.
- `apps/nvim/lua/forge/plugins`: lazy.nvim plugin specifications only.
- `apps/nvim/lua/forge/languages`: LSP, formatter, and DAP configuration.
- `packages/agent-core/forge_agents`: transport-independent agent lifecycle.
- `apps/web`: Astro presentation and docs with strict TypeScript, Tailwind, and accessible UI.
- `packages/protocol`: versioned CLI contract for editor and future mobile gateway.
- `scripts/installer`: per-user bootstrap, source ownership, dependency checks, and recovery.

Keep functions cohesive. Put behavior in its owning module; avoid utility dumping
grounds, globals, speculative abstractions, shell command interpolation, or new
services without a concrete requirement. Use Python standard library for agent
coordination. Keep all editor-to-process calls asynchronous.

## Changes and verification

Read the relevant module and `docs/architecture.md` before structural changes.
Use `.agents/skills/forge-editor` for editor changes and
`.agents/skills/forge-agent-core` for agent lifecycle changes. Run `make test` and
`make smoke` (Neovim >= 0.11). Run `make format-check` when StyLua is available.
For site changes run `pnpm check`, `pnpm lint`, `pnpm format:check`, and
`pnpm build`. Never use TypeScript any. Keep `utils/cn.ts` for class merging;
ESLint sorts imports and Prettier sorts Tailwind classes. Use the forge-web skill.
Do not claim live Copilot, model, LSP, or debugger verification from mocked tests.

Never apply an agent patch without an explicit user review action tied to its
snapshot hash. Never discard worktrees, kill unrelated processes, commit generated
agent changes, or bypass provider sandbox controls automatically. Worktrees are
change isolation, not a security sandbox. Keep tokens and session logs out of Git.

Use small Conventional Commits in English: `feat: ...`, `fix: ...`, `chore: ...`,
`docs: ...`, `test: ...`. Documentation uses normal, complete English prose.

Domain contract: [business rules](docs/business-rules.md).
Acceptance criteria: [requirements](docs/requirements.md).
Update rules, owning code, and focused tests together when behavior changes.

Use English for code, comments, skills, and contributor instructions. Repository documentation is English only. Website reader content supports English and Portuguese; translations belong under `apps/web/src/content`, never under `docs`. English is the static default; browser
language may select Portuguese and explicit user selection persists. Keep both
locale routes synchronized. Website docs teach installation and daily use; internal
domain rules, acceptance criteria, architecture, and contributor checks stay in `docs/`.

## Skill discovery

`.agents/skills` owns every skill. `.claude/skills` and `.gemini/skills` are relative
symlinks to that directory, not copies. Edit only the canonical directory.
Claude discovers skills through `.claude/skills`; mentioning a path in CLAUDE.md
does not replace native skill discovery. Gemini also supports `.agents/skills`
directly; its link is retained for CLI compatibility.
