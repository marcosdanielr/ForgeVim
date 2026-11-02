# Business rules

This document is the domain contract. Update it with the owning code and tests
when behavior changes. Repositories, workers, and UI adapters enforce these rules;
transport and presentation do not redefine them.

## Agent lifecycle

| ID | Rule | Owner | Evidence |
| --- | --- | --- | --- |
| BR-AG-01 | A task has a nonempty prompt and an explicitly selected trusted provider. | policy.require_prompt; providers.command | CLI validation and lifecycle fixtures |
| BR-AG-02 | A task starts from committed HEAD only when the source is clean. It gets its own branch/worktree. | AgentService.start; git.ensure_clean | dirty-source and concurrent-task tests |
| BR-AG-03 | Only ready, failed, or reviewing tasks can be reviewed. Failed output is partial output. Running, cancelling, queued, cancelled, interrupted, accepted, and rejected tasks cannot. | policy.require_finished | live-task and lost-worker tests |
| BR-AG-04 | Acceptance requires the currently reviewed SHA-256 snapshot hash. It is a one-time whole-patch operation. | policy.require_review; AgentService.accept | wrong-hash, changed-patch, tampered-patch, duplicate-accept tests |
| BR-AG-05 | The worktree patch and frozen bytes must still match the reviewed hash. Target HEAD must match the HEAD captured during review and target Git status must be clean. Git must accept the patch without conflicts. | AgentService.accept; git.apply | binary/new-file, dirty-target, changed-HEAD tests |
| BR-AG-06 | Apply the reviewed changes without committing or pushing. Include new files, binary files, deletions, and agent commits relative to the original base. | git.snapshot; git.apply | committed/binary and untracked/deletion tests |
| BR-AG-07 | Rejection is a completed-task decision and preserves branch, worktree, and logs. It does not undo source changes. | policy.require_rejectable; AgentService.reject | rejection preservation test |
| BR-AG-08 | Cancellation requests go through a task-local marker. Only the worker owning the provider process group signals it. No recovered PID is killed. | policy.require_cancellable; worker.terminate | cancellation test |
| BR-AG-09 | A heartbeat older than 30 seconds makes an active task interrupted, never finished. Interrupted output cannot be reviewed until a live worker completes it or an operator recovers it outside this workflow. | policy.HEARTBEAT_TIMEOUT_SECONDS; AgentService.tasks | lost-worker regression |
| BR-AG-10 | Reserved .forge and .git state cannot be applied as agent output. | git.snapshot | reserved-state test |
| BR-AG-11 | Unsaved editor buffers block starting/accepting a task, because Git cannot see their changes. | Lua features.agents and features.agents.review | native editor smoke plus manual UI review |

State progression: queued -> running -> ready/failed -> reviewing -> accepted or
rejected. queued/running -> cancelling -> cancelled. Expired active work becomes
interrupted. A still-live worker may refresh its heartbeat and report its final
state later; a stale heartbeat alone never proves provider termination.

Accepting one task dirties the source checkout. After committing it, review sibling tasks again against the current target.
Independent patches can apply unchanged; incompatible patches stay blocked. Automatic rebase and partial/hunk application
are deliberately absent. Rejected output remains recoverable.

Worktree isolation is not a security sandbox. The Codex adapter requests
workspace-write with no approval bypass. A custom local command is trusted code.
No remote caller may supply arbitrary commands without a future authorization
boundary. No agent starts from opening the editor or visiting the site.

BR-AG-12: notifications are optional and persistent. Watch only user-started or
user-inspected active tasks. Notify once on ready, failed, cancelled, or interrupted
status; do not include prompt contents. Stop polling when disabled or all watched
tasks finish. Editor closure stops notifications without stopping backend workers.
Owner: Lua `features.agents.notifications`.

BR-AG-13: supported provider identities are codex, claude, and gemini. Authentication
belongs to the official CLI. Do not store tokens or enable blanket permission
bypass. Owner: Python `providers`, Lua `features.agents.providers`.

## Editor rules

| ID | Rule | Owner |
| --- | --- | --- |
| BR-ED-01 | Preserve native modes, motions, registers, windows, buffers, and command editing. Ctrl W remains native. | core.options; core.keymaps |
| BR-ED-02 | Leader mappings accompany terminal-sensitive VS Code shortcuts. | core.actions |
| BR-ED-03 | Language tool installation is explicit opt-in. Enable only LSP executables present on PATH. | languages.tools; languages.lsp |
| BR-ED-04 | Python formatting runs isort then Black; web/PHP alternatives stop after the first available formatter. | languages.formatting |
| BR-ED-05 | Theme selection applies and persists. Menu preferences override user defaults. Plugin install/unload requires restart. | core.state; features.themes; features.plugins |
| BR-ED-06 | Copilot starts disabled unless the user enables it. Copilot authentication is separate from Codex task authentication. | plugins.completion |
| BR-ED-07 | Load launch.json only through an explicit command in a trusted project. | languages.debug.launch_json |
| BR-ED-08 | Agent process calls are asynchronous; Python is never called for keystroke handling. | features.agents.client |

## Website rules

| ID | Rule | Owner |
| --- | --- | --- |
| BR-WEB-01 | Theme defaults to system. Explicit light/dark preference persists; automatic mode follows later OS changes. Storage failure must not break the page. | features/preferences/theme.ts; BaseLayout prepaint |
| BR-WEB-02 | Illustrative demos are labeled and do not execute real tasks or imply future features exist today. | home components; MDX content |
| BR-WEB-03 | GitHub and Buy Me a Coffee destinations come from one typed configuration source. | config/site.ts |
| BR-WEB-04 | Presentation and docs remain accessible at narrow widths and through keyboard navigation; reduced-motion preference is respected. | global.css; client.ts |
| BR-WEB-05 | Site and repository stay private until the owner explicitly changes their audience. | hosting and repository settings |

BR-ED-09: shortcut preferences use stable command IDs, apply immediately, and
persist as data. Add/replace/reset workflows must detect existing mappings and
preserve native single-key motions and Ctrl W. Owner: features.shortcuts and
core.keymaps. Evidence: native editor smoke customization/reset checks.

BR-ED-10: Nerd Font icons default to enabled. Users can persist a plain-text fallback through Settings or user.lua. Missing patched fonts must not prevent basic
editing or navigation. Owner: core.config and plugin appearance options.

## Git workflow rules

BR-GIT-01: stage, commit, push, and conflict-side selection require user actions.
Do not modify Git hooks, signing, identity, or global configuration.
BR-GIT-02: conflict resolution preserves an editable result buffer. Choosing ours,
theirs, or base affects the user's selected conflict only; never auto-resolve all.
BR-GIT-03: accepted agent output remains uncommitted until the user reviews and
stages it through their chosen Git interface.
BR-GIT-04: the file tree is optional and opened on demand. Destructive file actions
use the upstream confirmation flow. Owners: features.git and plugins.git.

## Optional language rules

BR-LANG-01: every profile is disabled by default for a new user. An installed
executable alone never enables its LSP. Owner: languages.selection.
BR-LANG-02: installing tools requires an explicit profile action. SDK/runtime
installation is separate, visible, and never applied to every distribution user.
BR-LANG-03: disabling preserves downloaded tools and project files. Restart
refreshes active language/plugin state.
BR-LANG-04: FlutterTools is declared only in personal plugin configuration; the distribution contains no bundled FlutterTools plugin spec. When explicitly configured, FlutterTools alone owns Dart LSP and DAP integration; never start a
second dartls for the same profile. DevTools and widget guides stay opt-in.
BR-LANG-05: personal SDK paths affect Forge and its children only. Never rewrite
global shell profiles from language selection. Evidence: native profile smoke,
plugin integration, machine setup record, and docs/languages.md.

## Workspace defaults

- **BR-ED-11**: An empty interactive launch opens the native workspace and file tree. Explicit files, stdin, modified buffers, and headless runs are never replaced. Users can disable the welcome screen.
- **BR-ED-12**: Tokyo Night is the fresh-install default; saved theme preferences and user.lua remain authoritative. Missing themes fall back to habamax.
- **BR-ED-13**: Native h/j/k/l and Ctrl W navigation remain available. Ctrl H/J/K/L focus adjacent windows in normal mode only and remain configurable.
- **BR-GIT-05**: General review includes changes from any author. Opening a graph, diff, commit popup, or conflict view never commits or pushes automatically.


## Native panels and interactive conversations

- **BR-AG-14**: A terminal may claim only a queued interactive task. Duplicate or completed-session ownership is rejected under the store mutation lock.
- **BR-AG-15**: Interactive chat uses a clean committed source and isolated worktree. Running chat cannot be reviewed. Finished chat uses the existing snapshot gate and never applies or commits automatically.
- **BR-AG-16**: Hiding chat keeps its owned process live while the editor is open. CLI output and logs remain separate from control JSON; ending an editor session does not imply reattachment later.
- **BR-ED-14**: Hiding a terminal panel preserves its jobs, buffers, scrollback, and split group. Only explicit job termination or the editor terminal lifecycle can stop it.
- **BR-ED-15**: Explorer h/l collapses/opens; j/k remains native. Ctrl H/J/K/L stays configurable across normal and Forge terminal modes. Plain source-buffer motions and insert controls remain intact.
- **BR-ED-16**: Search/replacement scope, match-case, whole-word, and regex are visible options. Opening preview never modifies files; replacement requires an explicit one/all action in the replacement dialog.
- **BR-ED-17**: Existing modified buffers remain available while panels and buffers switch. Startup may add panels around explicit files but must not replace file contents or stdin.
- **BR-ED-18**: Visible task status comes from persisted real tasks. The UI must not fabricate agent roles, progress, test results, model activity, or system metrics.

- **BR-AG-17**: Existing task/status/log/event reads do not bootstrap Git or recreate the schema. Task creation, review, and application retain repository validation.
- **BR-AG-18**: UI wakeups follow committed lifecycle events, never heartbeats or token output. The marker is a hint, not authoritative state. A shared active-task fallback preserves visibility if file events are unavailable.

## Workbench presentation

- **BR-ED-19**: Wide startup layouts add native navigation, Explorer, editor,
  Agents, chat, and output panes. Chat and output start as actionable empty states;
  they must never launch a shell, model, or provider authentication automatically.
- **BR-ED-20**: Startup layout choices persist independently of the welcome screen.
  Width and height thresholds preserve editing space; hidden panes remain available
  through named actions. Decorations must preserve native window navigation,
  source buffers, signs, line numbers, and user-selected themes.
- **BR-ED-21**: Window decoration reads cached buffer/project metadata. It must not
  launch Git or Python from statusline, winbar, or tabline redraw functions.

Owners: `features/workbench`, `features/chrome`, `features/layout`,
`features/panels/windows`. Verification: native workbench and plugin integration tests.

- **BR-ED-22**: The bottom statusbar is global across native splits. It displays
  actual mode, cached Git branch, buffer diagnostics, filetype, encoding, line
  endings, and cursor position. Rendering starts no process and reads no settings
  file. Language glyphs use the existing pinned nvim-web-devicons dependency.
  Disabling Nerd Fonts preserves textual status and navigation after restart.

## Diagnostics and keyboard controls

- **BR-ED-23**: Diagnostics default to inline messages with signs and underlines.
  Users may select expanded current-line messages or quiet presentation. K remains
  LSP hover; gl opens actual line diagnostics. Presentation does not rewrite,
  suppress, or fabricate Dart analyzer findings.
- **BR-ED-24**: Pane headers display their configured hide key from a cache. Header
  redraw never reads preferences. Resizing moves the right/bottom divider when available, otherwise the left/top divider. Direction is screen-relative, independent of the focused side. It
  preserves source buffers, terminal jobs, window navigation, and mouse resizing.
- **BR-ED-25**: Shortcut notation uses Leader. Its default is Space; persisted
  Leader preferences override user.lua. A change takes effect only after restart,
  so existing session mappings remain intact. Custom action keys stay symbolic
  (`<leader>...`), and saving preserves all other preference fields. Restoring Space
  follows the same path. Localleader defaults to comma and remains configurable.
- **BR-ED-26**: Tab and Shift Tab cycle buffers only in normal mode. Forge must not
  intercept terminal Tab completion or insert-mode indentation for these aliases.

Owners: `features/diagnostics`, `features/leader`, `features/panels/resize`,
`features/workbench/hints`, and the named action registry. Verification includes
native split/diagnostic tests, fresh-process Leader transitions, and the optional
real Dart language-server test.

## Installation and terminal usability

- **BR-IN-01**: Installation is per-user, preserves existing config and commands,
  and never edits shell profiles or installs system dependencies automatically.
  Managed runtime checkout is sparse; the web app is excluded. SSD development
  mode points to the existing checkout and never updates it automatically.
- **BR-IN-02**: Ownership metadata and launcher hashes gate reinstall/removal.
  Partial plugin preparation uses owned staging. A changed launcher or unrelated
  runtime is never overwritten. Uninstall removes the launcher while retaining
  source, settings, logs, worktrees, and metadata for recovery.
- **BR-IN-03**: Managed updates require clean, fast-forward history. Plugin setup
  failure restores previous distribution source. Setup is bounded and only its
  owned process group may be terminated. Runtime editor startup gains no Python
  process from installer support.
- **BR-ED-27**: Pane toggles with modified keys work in normal and Forge terminal modes. Leader and other printable-prefix mappings remain normal-mode only so spaces and text reach CLI chats and shells unchanged. New terminals
  are distinct from hide/show. Ctrl Space/Ctrl @ provides a legacy NUL fallback
  outside insert mode; insert completion remains unchanged. Terminal headers expose
  New/Split/List with real session counts. Shell jobs survive hiding and switching.
- **BR-ED-28**: Find, replacement, options, and actions remain visible in one dialog. Changing fields must preserve the search session. Mouse and keyboard share the same actions. Replace-all confirmation initially selects Cancel. Search preview never changes files. Replace one applies exactly one occurrence, including repeated matches on one line. Replace all requires confirmation and complete search results. Unsaved buffers, changed source lines, and non-writable files block application. Regex applies to search; replacement text is literal.

Owners: `scripts/installer`, `install.sh`, `features/terminal`,
`features/search/preview`, and the named action registry.

- **BR-ED-29**: Forge Mint is an explicit `forge-mint` theme selection. Its graphite surfaces and mint folder colors must not change Tokyo Night configuration or survive switching to another theme. Tokyo Night remains the default.

- **BR-IN-04**: ForgeVim branding and repository URLs do not rename the `forge` command, `forge.nvim` profile, installer ownership marker, manifest product ID, or existing source directories. Previous canonical repository URLs remain compatible with installer reuse.

- **BR-WEB-07**: Automatic website deployment is limited to main and changes to website inputs since the last successful deployment. Missing comparison history builds. Deployment does not change repository visibility or existing editor configuration.

- **BR-ED-30**: The welcome dashboard renders a native ForgeVim wordmark and actionable shortcuts. Narrow windows use a compact wordmark. It starts no model or terminal process, and explicit files and stdin retain their normal startup path.

- **BR-ED-29**: Find/Replace Tab order follows visual order and visits every option
  and button. Space toggles options without triggering Leader commands. Next and
  Previous never modify files. Replace one advances without closing. Opening a
  result is a separate explicit action. File search may read unsaved buffer text;
  replacement still requires saved targets.
- **BR-ED-30**: Leader b toggles the file tree without a longer default b-prefix
  mapping. Buffer aliases must not delay that toggle.
- **BR-ED-31**: The terminal list reflects actual tab-local sessions. Selecting a
  visible session preserves its split. Hiding the list or terminal group never
  kills a job. The list starts no provider, shell, or polling timer.
