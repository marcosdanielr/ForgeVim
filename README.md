# ForgeVim

A modular Neovim distribution for debugging, fast search, and concurrent agents
whose changes stay in isolated worktrees until you review and accept them.

Native Neovim modes, motions, registers, buffers, splits, and commands remain at
the center. VS Code-inspired shortcuts have leader-key alternatives. Panels use native Neovim buffers and splits. There is no permanent background service.

## Start

Requirements: macOS/Linux, Neovim 0.11+, Git, ripgrep, and Python 3.9+.
Node.js 22+ is needed for Copilot and JavaScript tooling. Language runtimes are
installed separately. The repository is private during initial development.

```sh
git clone https://github.com/marcosdanielr/ForgeVim.git
cd ForgeVim
bash install.sh
forge .
```

The installer creates `~/.local/bin/forge` and prepares selected plugins. Add
`~/.local/bin` to PATH if needed. Use `bash install.sh --local` to point directly
at a development checkout on an external SSD. See [installation](docs/installation.md)
for authenticated bootstrap, custom paths, updates, and uninstall.

The launcher uses `NVIM_APPNAME=forge.nvim`, keeping your existing Neovim config
separate. First launch installs lazy.nvim and the selected plugins. It does not
install every LSP or debug runtime. Use `:ForgeLanguages`, wait for Mason to finish,
and restart. Use `:ForgeHealth` to check dependencies.

To work on a different project, run `/path/to/ForgeVim/bin/forge` from that
project. The launcher does not change your working directory. On this machine,
the checkout is `/Volumes/DEV_SSD/Projects/forge.nvim`.

## Ready-to-use workspace

Running `forge` with no file or directory opens a full-screen Tokyo Night welcome
dashboard with visible actions and keyboard hints. Press `f` to find a file, `g` for
source control, `v` to review changes, or `a` for agents. Press the displayed letter
or move with `j`/`k` and press Enter. `forge .`, explicit files, and piped input open
the project workspace directly and never show the welcome dashboard. Return to the
project workspace with `:ForgeWorkspace` (Leader u w). Set `workspace = false` to
disable the welcome screen. Themes and saved user preferences remain customizable.

Use Ctrl H/J/K/L in normal mode or Forge terminals to focus adjacent windows, including the file tree. Native h/j/k/l cursor movement and Ctrl W window commands remain intact.
Insert-mode editing preserves its native controls. Forge terminal window shortcuts leave terminal mode before focusing a pane.

## Editor workflows

| Action | Shortcut | Terminal fallback |
| --- | --- | --- |
| Command palette | Leader Leader | `:Forge` |
| Find files | Leader f f | `:ForgeFiles` |
| Search project | Leader f g | `:ForgeSearch` |
| Search buffer | Leader f b | `:ForgeBufferSearch` |
| Replace project text | Leader f r | `:ForgeReplace` |
| Replace current file text | Leader f R | `:ForgeBufferReplace` |
| Rename symbol with LSP | F2 | Leader c r |
| Format | Leader c f | `:ForgeFormat` |
| Commit graph | Leader g h | `:ForgeGitHistory` |
| Commit staged changes | Leader g c | `:ForgeCommit` |
| Review any changes | Leader g d | `:ForgeDiff` |
| Save | Ctrl S | `:write` |
| Debug start/continue | F5 | Leader d c |
| Breakpoint | F9 | Leader d b |
| Step over/into/out | F10 / F11 / Shift F11 | Leader d o / d i / d O |
| Start agent | — | Leader a n |
| List/review agents | — | Leader a a |
| Themes / plugins / tools | — | Leader u t / u p / u l |

Leader defaults to Space; change it through `:ForgeLeader` (restart required).
Forge actions use Leader consistently. Ctrl W remains native window control. Ctrl S
also works in insert/visual mode. Ctrl Space opens completion.

`y` and `p` use the system clipboard. In visual mode Ctrl C, Ctrl Shift C, and Cmd C
copy; Ctrl V, Ctrl Shift V, and Cmd V paste. Terminal emulators can intercept Cmd
shortcuts before Neovim receives them, so Ctrl C/V is the reliable terminal path.

`:ForgePlugins` offers optional plugin toggles and GitHub owner/repository input.
Restart to install or unload choices; `:Lazy` manages installed dependencies.
`:ForgeKeymaps` lets you add/replace shortcuts for named actions, inspect current
keys, detect conflicts, and restore defaults. Changes apply immediately and
persist without editing Lua. Native single-key motions and Ctrl W are protected.
`:ForgeThemes` applies and persists a theme. The default is Tokyo Night (night). Choose `forge-mint` for nearly black surfaces, green accents, and dedicated syntax colors, including explorer folders. Switching back restores Tokyo Night. An empty interactive launch opens the full-screen welcome dashboard; a project path opens the project workspace and file tree.

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
and commit or stash project changes first. `:ForgeAgentStart` opens an interactive
conversation with the selected provider in its own worktree. The provider shown in
Agents is the CLI receiving your messages. Use **Run background task** from Agents
when you want an independent one-shot task. Closing the editor does not stop workers.

Use `:ForgeAgents` to toggle the live task sidebar. `n` starts an agent conversation,
`b` runs a background task, Enter opens the selected agent, `v` reviews, and L shows logs.
Completed background tasks can continue in their provider's interactive conversation.
Review opens a native diff buffer: `a` accepts with a final
confirmation, `r` rejects, and `q` closes without deciding. Acceptance applies the
entire reviewed patch and never commits it. Rejection preserves worktree/logs.

A SHA-256 hash binds acceptance to the reviewed snapshot. The core rejects stale
patches, modified targets, target HEAD changes after review, and Git conflicts. It includes new and
binary files and agent commits relative to the original base. After accepting
and committing one task, review each sibling result against the current target.
Independent patches can apply unchanged; conflicting patches remain blocked. There is no automatic rebase, hunk acceptance, or task DAG yet. Interactive conversations use the official CLI in a separate terminal worktree.

Use `:ForgeNotifications` (Leader u n) to enable/disable completion notifications.
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
  nerd_fonts = true,
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
review acceptance. `scripts/verify/plugins.py` checks installed plugin integration;
it requires dependencies installed in the current XDG environment. These checks
do not prove every debugger/LSP runtime or live Copilot authentication.

For offline native startup, set `FORGE_OFFLINE=1`; plugin features are unavailable.
`FORGE_NVIM=/path/to/nvim` selects a test binary. See [design](docs/design.md) for
brand assets and [validation](docs/validation.md) for observed checks.

Support: [Buy Me a Coffee](https://buymeacoffee.com/marcosdanielr).
Source: [GitHub](https://github.com/marcosdanielr/ForgeVim).

Nerd Font folder and language icons are enabled by default in Explorer and buffer
tabs. Select a Nerd Font in your terminal (for example, MesloLGM Nerd Font Mono).
The terminal owns its font; Forge cannot select it through Neovim. If you prefer
plain text, use `:ForgeIcons` (Leader u i), or set `nerd_fonts = false` in user.lua,
and restart. The preference also appears in Settings.

A global bottom statusbar shows the current mode, cached Git branch, actual buffer
errors and warnings, language icon/type, encoding, line endings, and cursor position.
It stays visible when you focus the tree, chat, or terminal.

## Git and file tree

`:ForgeTree` (Leader b) opens nvim-tree. `:ForgeGit` (Leader g g) opens
Neogit for staging hunks and committing. `:ForgeDiff` reviews current changes;
`:ForgeConflicts` opens a three-way Diffview merge only when conflicts exist.
See [Git workflow](docs/git-workflow.md) for keys and explicit decision rules.

## Code navigation and diagnostics

Use `gd`/F12 for definition (including another file), `grr`/Shift F12 for references,
`gi` for implementation, `gy` for type definition, `K` for hover documentation,
Leader c s for signature help, and `gl` or Leader e for line diagnostics. The details window
focuses automatically: `y` or Ctrl C copies its complete message; `q` closes it.
`]d`/`[d` navigate diagnostics. Leader f s searches document symbols. All are named actions in
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
shows common actions. `:ForgeSettings` (Leader u s) groups theme, keys, languages,
plugins, provider login, notifications, and startup layout. The default wide
layout shows a navigation rail, separate Explorer, editor buffer tabs, Agents,
chat welcome, and an output dock. These empty panes start no shell or model.
Use Startup layout in Settings to choose which panes appear. Narrow terminals keep side panels
available by shortcut. Mouse focus, split resizing, and panel double-clicks work.

| Action | Default keys |
| --- | --- |
| Toggle navigation / files | Leader p n / Leader b |
| Toggle Agents | Leader p a |
| Toggle CLI chat / create conversation | Leader p c / Leader a C |
| Toggle terminal / new terminal | Leader o t / Leader o T |
| Split terminal / choose terminal | Leader o s / Leader o o |
| Next / previous buffer | Leader ] / Leader [ |
| Choose open buffer | Leader f B |
| Split current buffer | Leader s v / Leader s h |
| Toggle review / debug / logs | Leader p r / Leader p d / Leader p l |
| Move focused window | Leader w m, then 1 left / 2 right / 3 below / 4 above |
| Problems / restore panels | Leader p p / Leader p w |

Ctrl H/J/K/L works in normal mode and Forge-owned terminals. Insert-mode editing
retains native controls. The explorer uses j/k, h to collapse, and l/Enter to open
in the editor. Hiding terminal panels retains their jobs, scrollback, and split
group. Cycling buffers from a terminal cycles integrated terminal sessions;
cycling from source code selects source buffers. Legacy terminals cannot encode
every VS Code key combination; leader alternatives remain available.

Inside an agent conversation, Ctrl H/J/K/L immediately leaves terminal input and
focuses the adjacent pane. Forge consumes these keys locally; it never forwards
them to the provider or stops the agent process.

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

Leader f b opens file Find/Replace; Leader f r searches the project.
Type in Find and Replace with. Tab follows visual order and visits every option
and button; Shift Tab goes backward. Space or Enter toggles the focused option.
Enter/F3 goes to the next occurrence; Shift Enter/Shift F3 goes to the previous.
Previous and Next / skip never edit files. Replace one (or Ctrl R) changes the
selected occurrence and advances without closing. Repeat to confirm changes one
at a time; skip anything you want to keep. Replace all asks for confirmation.
Ctrl Enter opens the selected result and leaves the dialog. F8/Alt C toggles case,
F4 whole words, F5 regex search, and F6 file/project scope. Replacement is literal.
File search reads current buffer text, including unsaved edits. Save pending edits
before replacement; project search reads disk. More than 2000 occurrences blocks
Replace all. Escape leaves typing; another Escape closes.

Leader b immediately toggles the tree. Buffer cycling uses Leader ] / Leader [;
Leader f B lists buffers.

The terminal list opens beside running shells when space permits. Leader o o
focuses it; j/k selects a row and Enter opens that terminal. n creates, s splits,
and q hides only the list. Leader o t hides/restores the whole terminal group
without stopping jobs. Leader o T creates and Leader o s splits from any pane.

Leader s v splits the current source buffer vertically; Leader s h splits it
horizontally. If a panel comes back in an unwanted location, focus it and use
Leader w m. Four outlined, numbered zones appear over the screen; click a zone or
press 1 left, 2 right, 3 below, or 4 above. This moves the focused buffer, terminal,
or Forge panel. Forge panels keep that position when hidden and shown again.

## Performance checks

`python3 scripts/benchmarks/startup.py --nvim nvim` measures warm headless process
startup after dependencies are installed. It does not measure interactive panel
rendering, typing latency, LSPs, debuggers, model inference, or compare Rust and
Python. Panels and notifications share one event-driven status stream per project, with a five-second fallback while tasks run. Editor
keystrokes do not trigger Python work. Interactive CLI PTY relay uses Python I/O.

## Window sizing and diagnostic messages

Focus a split with Ctrl H/J/K/L, then use Ctrl Shift Left/Right to decrease/increase
its width or Ctrl Shift Up/Down to increase/decrease its height. Leader w h/l/k/j
provides the same controls. Leader w = balances resizable windows. Mouse dragging
and native Ctrl W commands remain available. Pane headers display their configured
hide shortcut, including when the navigation rail is hidden.

K (Shift K) shows LSP symbol information. gl or Leader e opens actual line errors
and warnings. ]d/[d moves between diagnostics. Inline messages are enabled by
default; :ForgeDiagnosticDisplay selects inline, current-line expanded, or quiet
presentation. This changes presentation only, not Dart analyzer policy or messages.

Tab/Shift Tab cycles source buffers in normal mode, matching VIMarcos. Terminal
Tab completion and insert-mode indentation remain available. Searches use Leader
f f for files, Leader f g for project text, and Leader f b for the current buffer.
Use :ForgeLeader or Settings to save a different Leader key, then restart Forge.
The default is Space. `leader` and `localleader` can also be set in user.lua;
localleader defaults to comma for plugin-local actions such as replacement.

## Terminal controls

Leader o t toggles the terminal; it does not create a new shell each time. Leader o T
creates another shell. Leader o s splits the focused terminal and
Leader o o lists sessions. The terminal header shows a session count and clickable
New, Split, and List controls. Hiding preserves every owned job and output buffer.

Inside a terminal, press Esc twice before using Leader o t. This keeps spaces and
text owned by the shell while typing. Ctrl Space continues to open completion.
A real-PTY test verifies Leader terminal input, multiple live shells, and Agents
hide/show.

The replacement dialog exposes visible one/all buttons with a preview. Direct grug-far commands remain available as an advanced alternative.

ForgeVim retains the `forge` command and the `forge.nvim` XDG profile name for compatibility. Existing personal plugins, logins, settings, installer metadata, and SSD checkout paths remain valid after the repository rename.

Website deployment through Vercel is documented in [deployment](docs/deployment.md). Automatic production builds watch only website inputs on main.
