# Contributor instructions

Forge.nvim is a Neovim distribution, not a replacement editor. Preserve native modes,
motions, buffers, windows, registers, command-line editing, and user configuration.

## Ownership

- `apps/nvim/lua/forge/core`: startup, configuration, commands, and keymaps.
- `apps/nvim/lua/forge/features`: focused editor workflows and UI adapters.
- `apps/nvim/lua/forge/plugins`: lazy.nvim plugin specifications only.
- `apps/nvim/lua/forge/languages`: LSP, formatter, and DAP configuration.
- `packages/agent-core/forge_agents`: transport-independent agent lifecycle.
- `packages/protocol`: versioned CLI contract for editor and future mobile gateway.

Keep functions cohesive. Put behavior in its owning module; avoid utility dumping
grounds, globals, speculative abstractions, shell command interpolation, or new
services without a concrete requirement. Use Python standard library for agent
coordination. Keep all editor-to-process calls asynchronous.

## Changes and verification

Read the relevant module and `docs/architecture.md` before structural changes.
Use `.agents/skills/forge-editor` for editor changes and
`.agents/skills/forge-agent-core` for agent lifecycle changes. Run `make test` and
`make smoke` (Neovim >= 0.11). Run `make format-check` when StyLua is available.
Do not claim live Copilot, model, LSP, or debugger verification from mocked tests.

Never apply an agent patch without an explicit user review action tied to its
snapshot hash. Never discard worktrees, kill unrelated processes, commit generated
agent changes, or bypass provider sandbox controls automatically. Worktrees are
change isolation, not a security sandbox. Keep tokens and session logs out of Git.

Use small Conventional Commits in English: `feat: ...`, `fix: ...`, `chore: ...`,
`docs: ...`, `test: ...`. Documentation uses normal, complete English prose.
