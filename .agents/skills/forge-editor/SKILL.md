---
name: forge-editor
description: Extend Forge.nvim editor features, language profiles, plugins, themes, or keymaps while preserving native Neovim behavior.
---

Read `AGENTS.md` and `docs/architecture.md`. Find the feature owner before editing.
Keep plugin specs declarative and feature behavior in focused Lua modules. Put LSP,
formatters, and DAP adapters under `languages`; expose intuitive commands through
the command registry with a leader fallback for terminal-incompatible shortcuts.

Use `vim.system` argument arrays for external processes. Preserve native motions,
registers, and `<C-w>` window commands. Avoid new work on every keystroke. Never
silently enable Copilot or install all language runtimes at startup.

Run headless smoke tests with isolated XDG directories. Verify changed plugin APIs
against installed versions and update `lazy-lock.json` when dependencies change.
Record whether testing used real adapters, local fixtures, or offline startup.
