# Product requirements and acceptance

Scope: a real Neovim distribution centered on debugging, search, code assistance,
and concurrent agents under human review. Status reflects delivered behavior, not
roadmap intent. Business constraints are in [business rules](https://github.com/marcosdanielr/ForgeVim/blob/main/docs/business-rules.md).

## Functional requirements

| ID | Requirement and acceptance | Status | Verification |
| --- | --- | --- | --- |
| FR-01 | Launch an isolated Neovim app without replacing existing configuration. Native operators/registers still work. | Implemented | make smoke |
| FR-02 | Expose a searchable command palette, themes, and plugin choices without mandatory Lua editing. Choices persist. Forge Mint has a separate identity and does not alter Tokyo Night after theme switching. | Implemented | Plugin integration and state smoke |
| FR-03 | Find files/text by file or Git project; preview textual replacement; rename symbols through LSP. | Implemented | Native occurrence replacement integration; real Pyright rename smoke |
| FR-04 | Provide LSP/path/snippet/buffer autocomplete and opt-in Copilot inline suggestions. | Implemented; live Copilot auth unverified | Blink API integration; user authentication required |
| FR-05 | Preserve VIMarcos language formatter inventory and expose opt-in tool installation. | Implemented | Conform integration; real StyLua formatting smoke |
| FR-06 | Provide breakpoints, stepping, scopes, stack, watches, and DAP profiles for Python, Go, Node, PHP, and native binaries. | Implemented profiles; all runtimes not verified | DAP config integration; real debugpy smoke |
| FR-07 | Run concurrent tasks in independent worktrees and persist lifecycle/logs after closing Neovim. | Implemented | Concurrent lifecycle tests |
| FR-08 | Show agent changes and require explicit snapshot-bound acceptance. Never commit automatically. | Implemented | Core tests and async Lua review smoke |
| FR-09 | Reject/cancel tasks without deleting recoverable worktrees. | Implemented | Rejection/cancellation tests |
| FR-10 | Present project and docs with responsive light/dark/system themes, English/Portuguese browser adaptation with English default, source and donation links. | Implemented | Astro checks/build and browser QA |
| FR-11 | Document contributor instructions and reusable editor/core/web skills. | Implemented | AGENTS.md, CLAUDE.md, skill validation |
| FR-12 | Expose a transport-independent versioned boundary for future mobile control. | JSON CLI implemented; mobile gateway/app planned | CLI envelope/event-cursor tests |
| FR-14 | Optional persistent editor notifications for task outcomes, without startup polling. | Implemented | Native notification smoke |
| FR-15 | Select Codex, Claude Code, or Gemini and authenticate through their official CLIs. | Implemented adapters; live account verification deferred | Provider contract tests |
| FR-16 | Offer on-demand file tree, stage/hunk/commit UI and three-way conflict resolution while preserving Git hooks and explicit user decisions. | Implemented plugin integration | Neogit/Diffview/nvim-tree smoke |
| FR-17 | Configurable definition, references, hover, signature, type and diagnostic actions, backed by the active LSP. | Implemented | Action registry and real Pyright smoke |
| FR-18 | Add, replace, inspect and reset shortcuts from a searchable menu, persisting changes without Lua edits. Protect native single-key/window commands and detect mapping conflicts. | Implemented | Native shortcut customization/reset smoke |
| FR-19 | Default language profiles are disabled; guided enable/install/disable/requirements/SDK-path actions make language setup explicit. Flutter/Dart includes LSP, formatting, SDK DAP, devices and hot reload. | Implemented | Profile smoke and language guide |
| FR-13 | Interactive agent follow-ups, approval prompts, dependencies, and hunk-level acceptance. | Planned | Not included in acceptance for initial release |

## Non-functional requirements

| ID | Requirement and measurable acceptance | Verification |
| --- | --- | --- |
| NFR-01 Performance | No Python work on code-editing keystrokes; no provider starts at startup; an open Agents panel may read existing task status; plugin loading is deferred by command/event; no permanent daemon. Report measured startup with environment, never claim universal latency. | Startup modules, plugin specs, validation report |
| NFR-02 Responsiveness | Editor-to-core calls use vim.system callbacks; a long model task must not block typing. | Async editor smoke |
| NFR-03 Integrity | Never apply a changed snapshot, dirty target, changed base, or reserved state. No automatic commit/push. | Agent regression suite |
| NFR-04 Process safety | Use argument arrays without shell interpolation. Only the owning worker terminates its provider group. Never recover by killing an unverified PID. | Providers/Git/worker ownership and cancellation tests |
| NFR-05 Maintainability | Cohesive modules own UI, application policy, persistence, Git, providers, and language config. Rules have IDs and test references. | AGENTS.md; architecture; business-rules |
| NFR-06 Type/code quality | Website uses Astro strictest TypeScript, no explicit any, ESLint import sorting, Prettier Tailwind sorting, and cn class merging. | pnpm check/lint/format:check |
| NFR-07 Reproducibility | Commit plugin and pnpm lockfiles. CI runs focused core/editor/web checks. | lazy-lock.json; pnpm-lock.yaml; CI |
| NFR-08 Accessibility | Semantic navigation, focus-visible, skip link, keyboard-operable demo tabs, copy feedback, readable narrow layout, reduced-motion support. | Browser QA and component review |
| NFR-09 Privacy | New repo/site private; no embedded credentials, telemetry, remote fonts, or model auto-start. .forge logs remain local and excluded from Git. | Hosting/repo state and source review |
| NFR-10 Portability | Initial support is macOS/Linux, Neovim 0.11+, Python 3.9+. Windows/mobile are not claimed. | CI matrix plus macOS local checks |
| NFR-11 Recovery | Preserve task branches/worktrees/logs on rejection, cancellation, failure, and interruption. Surface actionable errors. | Lifecycle tests and protocol |

## Change policy

For a new capability, add or update its requirement, rule, owner, and focused
acceptance proof in the same change. Mark unverified runtime integration as such.
Avoid claiming a future mobile client or normalized custom chat interface exists
because the underlying protocol could eventually support it.

## Workspace acceptance

- **FR-20**: An interactive launch with no file or directory presents a full-screen Tokyo Night welcome dashboard with visible action keys and command hints. Explicit directory/file input opens the project workspace directly; native editing remains intact.
- **FR-21**: Users can open a commit graph, inspect a selected commit, review working-tree changes, open a staged commit popup, and resolve conflicts from the workspace.
- **FR-22**: Ctrl H/J/K/L changes visible-window focus in normal mode while native cursor and Ctrl W navigation remain intact.


## Persistent workspace acceptance

- **FR-23**: Users can toggle files, Agents, CLI chat, logs, review, diagnostics, debug, and terminal panels through named configurable actions. F1 lists current keys.
- **FR-24**: Multiple integrated terminals retain output and jobs across hide/show and restore split groups. Buffer/terminal cycling has VS Code-inspired and leader alternatives.
- **FR-25**: Codex, Claude, and Gemini can run their official interactive CLIs in an isolated terminal worktree with normal permissions and explicit final review.
- **FR-26**: Search/replacement exposes file/project scope, case matching, whole words, and regex; preview is non-mutating.
- **FR-27**: Settings expose theme, keymaps, providers, languages, plugins, notifications, and persisted startup-panel choices without requiring Lua edits.
- **NFR-12 Interactive transport**: PTY ownership, input/output draining, resize forwarding, cancellation, heartbeat, and source isolation have fixture coverage. Real provider account interoperability is verified separately.

## Workbench presentation acceptance

- **FR-28**: At 150 or more columns, startup can show a navigation rail, separate
  Explorer, central editor, Agents, and right-side chat. At 40 or more rows, the
  wide layout can include an output dock. At 120–149 columns, chat and Agents share
  one right column; below 120 columns, these panes remain available on demand.
- **FR-29**: Source buffers appear as clickable tabs. Native line numbers, signs,
  modes, keyboard window navigation, and mouse support remain available.
- **FR-30**: Chat presents provider connection and new-conversation actions. Output
  presents terminal actions. Empty startup panes create no shell or model process.
- **NFR-13 Presentation cost**: Project context and buffer lists are cached outside
  redraw functions. Tests verify source preservation, native pane geometry,
  mouse activation, visibility toggles, and Explorer reopening order.

- **FR-31**: Explorer shows distinct open/closed folder glyphs and language file
  icons; buffer tabs and the global bottom statusbar show language glyphs. A saved
  Settings option disables Nerd Font glyphs without changing editing behavior.
- **FR-32**: One global bottom bar remains visible across panel focus changes and
  reports real mode, branch, errors/warnings, filetype, encoding, line endings, and
  cursor position. Diagnostic changes update the displayed counts.

- **FR-33**: Actual analyzer errors are visible inline by default. Users can open
  complete line diagnostics with gl, navigate with ]d/[d, and choose inline,
  expanded current-line, or quiet display in Settings.
- **FR-34**: Each Forge pane header shows its current hide shortcut, even when the
  navigation rail is hidden. Changing a named shortcut updates header hints.
- **FR-35**: Ctrl Shift arrows move a visible divider in the arrow direction. Leader w h/l
  moves the divider left/right, Leader w k/j moves it up/down, and Leader w = invokes
  native balancing. Terminal jobs and source buffers survive resizing.
- **FR-36**: Leader is configurable through Settings or user.lua; Space remains the
  default. Restart applies new and restored values without losing custom symbolic
  mappings or unknown preferences. The command palette uses Leader Leader.
- **FR-37**: Leader ] / Leader [ cycles buffers and terminal sessions. Terminal
  completion and insert-mode indentation remain intact.

- **FR-38**: An installer validates requirements, prepares selected pinned plugins,
  preserves personal config, and creates a command available through PATH. A local
  mode launches directly from the external-SSD checkout without copying it.
- **FR-39**: Doctor, clean managed updates, uninstall, repeat installation, and
  recoverable partial failures are supported. Existing commands and unrelated
  runtime paths are never overwritten. Private-repository installation documents
  authenticated access rather than promising anonymous curl downloads.
- **FR-40**: New/split/list terminal controls are visible through Leader o T/o s/o o.
  After Escape Escape, Leader o t toggles terminal panels without intercepting shell text.
- **FR-41**: Search exposes visible Replace one and Replace all controls. One replaces one byte-range match; all requires confirmation and complete results. Tests cover repeated occurrences on one line, UTF-8, file scope, stale results, and unsaved edits.

- **FR-42**: CLI chats and terminals receive spaces and printable text unchanged. Leader shortcuts require terminal-normal mode; modified window/terminal keys remain available while typing.

- **FR-43**: Personal lazy.nvim plugin specifications are supported without editing distribution files. FlutterTools requires an explicit personal declaration; selecting the Dart profile alone never installs it.

- **FR-43**: File Find/Replace supports keyboard-accessible options, next/previous
  navigation, skip, and repeated individual replacement without closing.
- **FR-44**: Leader b toggles Explorer immediately; terminal sessions are selectable
  from a keyboard-driven list beside the shell panel.
