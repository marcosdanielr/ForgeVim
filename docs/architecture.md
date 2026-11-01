# Architecture

Forge.nvim keeps Neovim as the editor and adds focused Lua modules. Plugin specs
are dependency declarations; feature modules own workflows. Language modules own
LSP, formatting, and debug configuration. No custom renderer, TUI, permanent
Python service, or alternate editing model is introduced.

The editor calls a short-lived Python CLI with argument arrays using `vim.system`.
A detached worker is created only for a running agent. SQLite stores lifecycle
state and events; Git worktrees isolate concurrent changes. The core has no
Neovim dependency. Protocol v1 is a JSON CLI boundary, not a mobile HTTP API.

```text
Neovim UI / future mobile gateway
           | JSON protocol v1
           v
Agent application service
    | SQLite store | Git adapter | provider process
```

## Why Lua and Python

Lua owns startup and editing. Git, ripgrep, LSP servers, and debug adapters already
execute performance-sensitive operations in native processes. Python coordinates
I/O and process lifecycles on demand using its standard library. It does not run
on each keystroke. Rust would add a build toolchain and cross-platform binaries
without demonstrated benefit for this workload. Introduce it only after measured
latency or memory evidence warrants replacing a specific boundary.

## Review invariant

Each agent starts from the current committed HEAD in a separate branch/worktree.
The source checkout must be clean, preventing silent omission of unsaved Git work.
A completed task produces a frozen binary-capable patch including new files and
agent commits relative to its original base. Review returns its SHA-256 hash.
Accept requires that exact hash, an unchanged clean target at the original HEAD,
and `git apply --check`. Changes are applied without committing. Rejection keeps
the worktree and logs for recovery. Review is whole-patch in this release.

This is not a sandbox: an agent process runs with the user's permissions subject
to its provider's sandbox. Repository instructions and installed plugins are code.
Only Codex is bundled as an agent provider initially; its sandbox is explicitly
`workspace-write`. A trusted local command provider exists for integrations/tests.

## Mobile boundary

The future gateway can wrap the core's commands and event cursor. Authentication,
TLS, pairing, authorization, streaming, and remote runtime are future work. Do not
expose the local CLI over a network or infer mobile readiness from JSON support.

## References and provenance

- [VIMarcos.lua](https://github.com/marcosdanielr/VIMarcos.lua): personal language,
  formatter, and debugger inventory. Configuration rewritten for current APIs.
- [LazyVim](https://github.com/LazyVim/LazyVim/tree/main/lua/lazyvim): modular config
  and lazy loading patterns; no distribution source copied.
- [AstroNvim](https://github.com/AstroNvim/AstroNvim/tree/main/lua/astronvim): small
  setup boundary and composable configuration; no distribution source copied.
- [Orca](https://github.com/stablyai/orca): concurrent agent/worktree and human
  review workflow inspiration; no Orca code or branding reused.
- [Codex non-interactive mode](https://developers.openai.com/codex/noninteractive/):
  provider process and JSONL event output.
- [Neovim Lua](https://neovim.io/doc/user/lua.html): asynchronous process API.
- [nvim-dap](https://github.com/mfussenegger/nvim-dap): debug adapter frontend.
- [Conform](https://github.com/stevearc/conform.nvim): formatter lifecycle.
- [blink.cmp](https://github.com/Saghen/blink.cmp): completion and LSP capabilities.

Upstream dependencies retain their own licenses. No third-party source is vendored.
