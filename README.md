# Forge.nvim

A modular Neovim distribution for debugging, fast search, and concurrent agents
whose changes stay in isolated worktrees until you review and accept them.

Native Neovim modes, motions, registers, buffers, splits, and commands remain at
the center. VS Code-inspired shortcuts have leader-key alternatives. Panels use native Neovim buffers and splits. There is no permanent background service.

## Start

Requirements: macOS/Linux, Neovim 0.11+, Git, ripgrep, and Python 3.9+.
Node.js 22+ is needed for Copilot and JavaScript tooling. Language runtimes are
installed separately. The repository is private during initial development.

```sh
git clone https://github.com/marcosdanielr/forge.nvim.git
cd forge.nvim
./bin/forge
```

The launcher uses `NVIM_APPNAME=forge.nvim`, keeping your existing Neovim config
separate. First launch installs lazy.nvim and the selected plugins. It does not
install every LSP or debug runtime. Use `:ForgeLanguages`, wait for Mason to finish,
and restart. Use `:ForgeHealth` to check dependencies.

To work on a different project, run `/path/to/forge.nvim/bin/forge` from that
project. The launcher does not change your working directory. On this machine,
the checkout is `/Volumes/DEV_SSD/Projects/forge.nvim`.

## Ready-to-use workspace

An empty interactive launch opens a Tokyo Night workspace with the project tree,
Git status, visible actions, and keyboard hints. Press `f` to find a file, `g` for
source control, `v` to review changes, or `a` for agents. Press the displayed letter
or move with `j`/`k` and press Enter. Existing files and piped input open normally.
Return with `:ForgeWorkspace` (Space u w). Set `workspace = false` to disable the
welcome screen. Themes and saved user preferences remain customizable.

Use Ctrl H/J/K/L in normal mode or Forge terminals to focus adjacent windows, including the file tree. Native h/j/k/l cursor movement and Ctrl W window commands remain intact.
Insert-mode editing preserves its native controls. Forge terminal window shortcuts leave terminal mode before focusing a pane.

## Editor workflows

| Action | Shortcut | Terminal fallback |
| --- | --- | --- |
| Command palette | Ctrl Shift P | Space Space / `:Forge` |
| Find files | Ctrl P | Space f f |
| Search project | Ctrl Shift F | Space f g |
| Search buffer | Ctrl F | Space f b |
| Replace project text | Ctrl Shift H | Space f r |
| Replace current file text | — | Space f R |
| Rename symbol with LSP | F2 | Space c r |
| Format | Alt Shift F | Space c f |
| Commit graph | Space g h | `:ForgeGitHistory` |
| Commit staged changes | Space g c | `:ForgeCommit` |
| Review any changes | Space g d | `:ForgeDiff` |
| Save | Ctrl S | `:write` |
| Debug start/continue | F5 | Space d c |
| Breakpoint | F9 | Space d b |
| Step over/into/out | F10 / F11 / Shift F11 | Space d o / d i / d O |
| Start agent | — | Space a n |
| List/review agents | — | Space a a |
| Themes / plugins / tools | — | Space u t / u p / u l |

Leader is Space. Ctrl/Shift combinations depend on the terminal's keyboard
protocol; use leader alternatives when keys collide. Ctrl W remains native window
control. Ctrl S also works in insert/visual mode. Ctrl Space opens completion.

`:ForgePlugins` offers optional plugin toggles and GitHub owner/repository input.
Restart to install or unload choices; `:Lazy` manages installed dependencies.
`:ForgeKeymaps` lets you add/replace shortcuts for named actions, inspect current
keys, detect conflicts, and restore defaults. Changes apply immediately and
persist without editing Lua. Native single-key motions and Ctrl W are protected.
`:ForgeThemes` applies and persists a theme. The default is Tokyo Night (night). Empty interactive launches open the project workspace and file tree.

blink.cmp provides LSP, path, snippet, and buffer completion. Copilot is opt-in:
enable it in `:ForgePlugins`, restart, then run `:Copilot auth`. Alt L accepts an
inline suggestion. Enter accepts a completion-menu item; Tab handles snippets or
indentation. Copilot requires its own account access and compatible Node runtime.

## Languages and debugging

LSP and formatter inventory comes from
[VIMarcos.lua](https://github.com/marcosdanielr/VIMarcos.lua). Old global variables,
legacy LSP setup, and absolute debugger paths are replaced with focused modules,
native Neovim LSP APIs, and Mason executables.

Main LSPs: lua_ls, gopls, rust_analyzer, pyright, ts_ls, astro, html, phpactor,
and optional FlutterTools-managed dartls (Flutter SDK). Conform includes the original language formatter
inventory. Web formatters use prettierd **or** prettier; Python keeps the isort
then Black pipeline. Missing formatter tools remain visible in `:ConformInfo`.

DAP profiles cover Python/debugpy, Go/Delve, JS/TS/vscode-js-debug,
PHP/Xdebug, and Rust/C/C++/codelldb. Compile native programs before selecting their
binary. TypeScript may need project compilation and source maps or a custom
runtime. PHP requires Xdebug configured to port 9003. Python respects VIRTUAL_ENV.
Flutter/Dart uses FlutterTools for LSP and SDK DAP; C/C++ has an optional clangd profile.

`:ForgeDebugLoadLaunch` explicitly loads a trusted `.vscode/launch.json`.
Project launch files can execute programs; they are not automatically loaded.
DAP virtual text is disabled by default to avoid putting variable values inline.

## Agent workflow

Install and authenticate Codex, Claude Code, or Gemini CLI separately.
`:ForgeAgentConnect` opens the official login flow in a Neovim terminal.
See [provider connections](docs/providers.md). Save all buffers
and commit or stash project changes first. `:ForgeAgentStart` starts a one-shot
task with the selected provider in its own worktree. Multiple independent tasks can run concurrently.
Closing the editor does not stop workers.

Use `:ForgeAgents` to toggle the live task sidebar. Enter opens task actions; n starts a task, c opens chat, v reviews, and L shows logs. Review opens a native diff buffer: `a` accepts with a final
confirmation, `r` rejects, and `q` closes without deciding. Acceptance applies the
entire reviewed patch and never commits it. Rejection preserves worktree/logs.

A SHA-256 hash binds acceptance to the reviewed snapshot. The core rejects stale
patches, modified targets, target HEAD changes after review, and Git conflicts. It includes new and
binary files and agent commits relative to the original base. After accepting
and committing one task, review each sibling result against the current target.
Independent patches can apply unchanged; conflicting patches remain blocked. There is no automatic rebase, hunk acceptance, or task DAG yet. Interactive conversations use the official CLI in a separate terminal worktree.

Use `:ForgeNotifications` (Space u n) to enable/disable completion notifications.
They run only while watched tasks are active and the editor is open.

Worktrees isolate changes, not permissions. Codex runs with `workspace-write` and
no approval bypass. Local custom command providers are trusted executable code.
State and logs live in the target project's `.forge`, excluded locally from Git.
No model call is made at startup. A visible Agents panel may read existing task status asynchronously. Tests use a fake provider and consume no paid
model tokens. Workers with expired heartbeats are marked interrupted, never killed
by a recovered PID. Interrupted tasks retain recoverable worktrees.

The standalone CLI is available through `./bin/forge-agents`; see the
[protocol contract](packages/protocol/README.md).

## Personal configuration

Create `~/.config/forge.nvim/lua/user.lua` (or its XDG equivalent):

```lua
return {
  theme = "tokyonight",
  workspace = true,
  format_on_save = true,
  copilot = false,
  notifications = true,
  nerd_fonts = false,
}
```

Menu preferences take priority and live under `stdpath("state")/forge`.
The bundled plugin lock is seeded once into user state; `:Lazy` updates that local
copy. Maintainers use `FORGE_UPDATE_LOCK=1 ./bin/forge` when deliberately updating
the distribution lock and then review/test the changes. Extra plugins needing
custom options can be configured in `apps/nvim/lua/forge/plugins`.

## Monorepo and contribution

- `apps/nvim`: Lua editor, features, plugin specs, and language profiles.
- `packages/agent-core`: Python standard-library process orchestration.
- `packages/protocol`: JSON v1 contract for current and future clients.
- `apps/web`: Astro, strict TypeScript, Tailwind, presentation, and Portuguese docs.
- `.agents/skills`: scoped editor, core, and web contribution workflows.

Read [AGENTS.md](AGENTS.md), [CLAUDE.md](CLAUDE.md),
[architecture](docs/architecture.md), and [roadmap](docs/roadmap.md).
Use short English Conventional Commits.

```sh
make test
make smoke
make format-check # requires StyLua
# pnpm 12.4.1 (see packageManager in package.json)
pnpm install --frozen-lockfile
pnpm format
pnpm lint
pnpm check
pnpm build
pnpm dev
```

`make smoke` uses temporary XDG directories and a fake agent to prove editor/core
review acceptance. `scripts/plugin-smoke.py` checks installed plugin integration;
it requires dependencies installed in the current XDG environment. These checks
do not prove every debugger/LSP runtime or live Copilot authentication.

For offline native startup, set `FORGE_OFFLINE=1`; plugin features are unavailable.
`FORGE_NVIM=/path/to/nvim` selects a test binary. See [design](docs/design.md) for
brand assets and [validation](docs/validation.md) for observed checks.

Support: [Buy Me a Coffee](https://buymeacoffee.com/marcosdanielr).
Source: [GitHub](https://github.com/marcosdanielr/forge.nvim).

Nerd Fonts are optional. Set `nerd_fonts = true` after configuring a Nerd Font in
your terminal to enable file icons and richer which-key icons. Text-first defaults
remain usable without installing a font.

## Git and file tree

`:ForgeTree` (Ctrl B / Space f e) opens nvim-tree. `:ForgeGit` (Space g g) opens
Neogit for staging hunks and committing. `:ForgeDiff` reviews current changes;
`:ForgeConflicts` opens a three-way Diffview merge only when conflicts exist.
See [Git workflow](docs/git-workflow.md) for keys and explicit decision rules.

## Code navigation and diagnostics

Use `gd`/F12 for definition (including another file), `grr`/Shift F12 for references,
`gi` for implementation, `gy` for type definition, `K` for hover documentation,
Space c s for signature help, and `gl` for line diagnostics. `]d`/`[d` navigate
diagnostics. Space f s searches document symbols. All are named actions in
`:ForgeKeymaps`, so their normal-mode shortcuts can be replaced without Lua edits.
These actions require an active server supporting the relevant LSP capability.

Language profiles are off by default for new users. Use `:ForgeLanguages` to enable,
install, disable, inspect SDK requirements, or add SDK bin paths. The complete
[language setup guide](docs/languages.md) explains every profile and debugger.
The owner machine preset is separate from distribution defaults.

Contributor and technical documentation in `docs/` is English only. Portuguese
reader translations live under `apps/web/src/content/docs/pt` and are rendered
only by the website. Skills live once in `.agents/skills`; the provider-specific
skill directories are symlinks for discovery, not duplicate files.


## Panels, buffers, and terminals

Use F1 for a beginner guide with your actual configured shortcuts. The top bar
shows common actions. `:ForgeSettings` (Space u s) groups theme, keys, languages,
plugins, provider login, notifications, and startup layout. The default wide
layout shows a navigation rail, separate Explorer, editor buffer tabs, Agents,
chat welcome, and an output dock. These empty panes start no shell or model.
Use Startup layout in Settings to choose which panes appear. Narrow terminals keep side panels
available by shortcut. Mouse focus, split resizing, and panel double-clicks work.

| Action | Default keys |
| --- | --- |
| Toggle navigation / files | Space p n / Ctrl B; Space p e |
| Toggle Agents | Space p a |
| Toggle CLI chat / create conversation | Space p c / Space a C |
| Toggle terminal / new terminal | Ctrl backtick / Ctrl Shift backtick; Space o t / Space o T |
| Split terminal / choose terminal | Ctrl Shift 5 / Space o s; Space o o |
| Next / previous buffer | Ctrl Tab / Ctrl Shift Tab; Space b n / Space b p |
| Choose open buffer | Space b b |
| Toggle review / debug / logs | Space p r / Space p d / Space p l |
| Problems / restore panels | Ctrl Shift M / Space p p; Space p w |

Ctrl H/J/K/L works in normal mode and Forge-owned terminals. Insert-mode editing
retains native controls. The explorer uses j/k, h to collapse, and l/Enter to open
in the editor. Hiding terminal panels retains their jobs, scrollback, and split
group. Cycling buffers from a terminal cycles integrated terminal sessions;
cycling from source code selects source buffers. Legacy terminals cannot encode
every VS Code key combination; leader alternatives remain available.

## Interactive chat

Connect with `:ForgeAgentConnect`, then `:ForgeChatNew`. Choose Codex, Claude, or
Gemini and name the conversation. The official CLI runs in a right-hand terminal
with its normal login, model choices, follow-ups, and permission prompts. Save
buffers and commit or stash first: chat gets a separate Git worktree. No prompt
or paid model call is sent automatically. Exit the CLI to finish, then select the
task in Agents and review its changes. The existing snapshot acceptance gate
applies; source files remain untouched until explicit acceptance.

Hidden chat remains live while Forge is open. These interactive terminals belong
to their original editor session; reopening Forge does not reattach an old PTY.
Logs/worktrees remain recoverable. This is a real CLI conversation, not a custom
message UI or an autonomous multi-agent plan/DAG.

## Search and replace

Ctrl Shift H / Space f r opens a form for project replacement; Space f R targets
the current file. Edit Search and Replace, select File/Project, and toggle Match
case, Whole word, and Regex. Enter or double-click edits an option. Preview opens
grug-far without changing files. Its header and g? explain application, history,
and undo. With the default local leader, comma then r applies replacement.

## Performance checks

`python3 scripts/benchmark-startup.py --nvim nvim` measures warm headless process
startup after dependencies are installed. It does not measure interactive panel
rendering, typing latency, LSPs, debuggers, model inference, or compare Rust and
Python. Panels and notifications share one event-driven status stream per project, with a five-second fallback while tasks run. Editor
keystrokes do not trigger Python work. Interactive CLI PTY relay uses Python I/O.
