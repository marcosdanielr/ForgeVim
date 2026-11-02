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
execute performance-sensitive operations in native processes. Python coordinates I/O and process lifecycles using its standard library. Code-editing keystrokes do not invoke Python. Interactive CLI sessions use a Python-owned PTY relay; visible active-task status uses bounded-interval polling. Rust would add a build toolchain and cross-platform binaries
without demonstrated benefit for this workload. Introduce it only after measured
latency or memory evidence warrants replacing a specific boundary.

## Review invariant

Each agent starts from the current committed HEAD in a separate branch/worktree.
The source checkout must be clean, preventing silent omission of unsaved Git work.
A completed task produces a frozen binary-capable patch including new files and
agent commits relative to its original base. Review returns its SHA-256 hash.
Accept requires that exact hash, an unchanged clean target at the HEAD captured during review,
and `git apply --check`. Changes are applied without committing. Rejection keeps
the worktree and logs for recovery. Review is whole-patch in this release. Independent sibling patches can be reviewed
and applied after another result is committed, provided Git validates the unchanged
patch against the current target. Overlapping incompatible changes stay blocked.

This is not a sandbox: an agent process runs with the user's permissions subject
to its provider's sandbox. Repository instructions and installed plugins are code.
Codex, Claude Code, and Gemini are bundled CLI providers. Codex explicitly uses
`workspace-write`; Claude uses `acceptEdits` and Gemini `auto_edit`, preserving
non-edit permission checks. A trusted local command provider supports tests.
Provider login uses the official CLI in a Neovim terminal. Notifications poll only
while user-started or user-inspected tasks run; no permanent daemon is introduced.

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

Domain contracts: [business rules](business-rules.md), [requirements](requirements.md),
and [provider connections](providers.md).

Language profiles are explicit opt-in. An installed server alone never starts
without an enabled profile and matching filetype. FlutterTools is the sole owner
of Dart LSP/DAP. SDK prerequisites and per-editor PATH choices are documented in
[language setup](languages.md), with a separate owner-machine preset.

## Native workspace presentation

`features/workspace` separates action metadata, read-only asynchronous Git status,
and buffer rendering. Empty interactive launches show this buffer beside nvim-tree;
explicit input and headless operation preserve the normal startup path. The panel
starts no Python worker or model call. `features/chrome` supplies a native statusline
with mode and discoverable command/workspace hints. Review and Git operations reuse
Neogit, Diffview, and the existing agent snapshot boundary.


## Panel ownership and interactive transport

`features/panels/windows` owns tab-local native split references. It never deletes
terminal buffers or kills jobs when hiding. `features/terminal/session` owns each
Neovim job handle; the terminal controller selects/restores groups. File buffers,
explorer movement, and normal/terminal window commands remain native. `features/agents`
separates live task rendering, actions, and CLI chat. Only visible active panels
poll; closing or leaving a panel stops its status timer. No model runs on startup.

`tasks.create` is the shared worktree preparation path. Batch workers detach;
interactive tasks are claimed once by `forge_agents.chat`, which delegates terminal
I/O, resize, and owned-process cleanup to `terminal`. JSON control envelopes stay
separate from raw terminal bytes. Both modes share the same review/hash/target-HEAD
invariant. Only interactive queued tasks can cancel without a running worker.

The initial screen is inspired by a multi-pane agent workspace. It does not invent
agent roles, CPU statistics, plan progress, tests, or token counts. Status comes
from actual persisted tasks; empty states explain the next available action.

## Shared status wakeups

`agents/watch` owns one status subscription per project and fans results out to
visible panels and optional notifications. Store commits with a lifecycle event
touch a best-effort events.signal marker. Heartbeats never touch that marker.
Native file events debounce status reads; a five-second fallback runs only while
tasks are active, preserving lost-worker detection and older state compatibility.
No model logs or editor keystrokes trigger status reads. Existing status/log/event
queries reuse the store without bootstrapping Git; mutating and review operations
retain full Git validation.
