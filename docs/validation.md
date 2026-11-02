# Validation record

Observed locally on November 1, 2026, on macOS arm64 with the checkout on DEV_SSD.
This is a reproducible engineering check record, not a universal performance or
security certification.

## Agent core

30 standard-library unittest cases pass: isolated concurrent tasks, new/deleted and
binary files, agent commits, dirty source/target, changed HEAD, wrong/tampered/stale
snapshot hashes, reserved paths, rejection preservation, cancellation, expired
heartbeats, JSON envelopes/event cursors, official provider command contracts, independent sibling acceptance, and conflicting
sibling rejection.
Tests run local fake providers without paid models or account authentication.

## Neovim

Neovim 0.12.6 headless: native operators/registers, preferences, shortcut replacement
and reset, reserved motion/window shortcuts, notification persistence and silence
when disabled, async CLI review, and explicit snapshot acceptance pass.

Installed plugin integration passes for Blink, LSP setup, Conform, DAP profiles,
all bundled themes, Telescope selection, grug-far, nvim-tree, Neogit, and Diffview.
A real temporary conflict is resolved through Diffview by choosing the current
side. The result is saved and remains unmerged in the index until the user stages
it; no source project is changed.

An additional real-runtime check passes Pyright diagnostics and symbol rename,
StyLua formatting, and a debugpy stopped session. Provider model calls, Copilot
login, Gemini installation, and every language debugger remain unverified locally.
Codex and Claude CLI flags were checked against installed help; Gemini flags were
checked against official documentation. No provider permission bypass is used.

Warm empty headless process startup (including shell launcher and Neovim exit,
installed plugins, no file/LSP/model startup): median 199.8 ms over five
samples. Values: 233.6, 199.8, 193.0, 225.6, 158.0 ms. This measurement is affected by the
external SSD, host load, cache state, and subprocess overhead; it is not an input
latency benchmark or a startup SLA.

## Website and contributor workflow

Astro 7.4.4 (updated after dependency audit), strict TypeScript check, ESLint 10 with explicit-any prohibition and import
sorting, Prettier with Tailwind class sorting, and the static build pass. The build
contains both locale trees with reader guides for installation and daily use.
Internal rules, requirements, and architecture stay in English under docs/. The website contains bilingual reader guidance for installation and daily use.

Browser QA uses the Codex internal browser. Light/dark/system controls, manual
locale navigation, docs navigation, and copy controls are checked in the
visible layout. The redesigned landing page and MDX agent guide were inspected
in a wide viewport; the landing page was also inspected in a narrow viewport.

All three scoped skills pass the skill-creator validator. GitHub CI configuration
runs Python 3.9/3.13 core checks, Neovim 0.11.5 smoke, StyLua, and website gates.
A workflow file alone is not evidence that hosted CI has passed.

Production dependency audit after the Astro update reports zero known
vulnerabilities. This does not establish absence of unknown issues or replace
reviewing dependency updates.

## Workspace and pnpm follow-up

The offline native smoke additionally verifies workspace Git status, preservation
of h/j/k/l, restoration of window options after leaving the welcome buffer, and
Ctrl H/J/K/L focus across horizontal and vertical splits. Installed plugin
integration passes after the workspace change. pnpm 12.4.1 imports the npm lock
and installs the workspace with a frozen lockfile. These checks do not establish
feature parity with Orca or verify continuous provider conversations.

An interactive TUI with a fresh test profile also reports one attached UI, the
forge-workspace buffer, a visible nvim-tree, and tokyonight-night. Installed plugin
smoke covers tree/workspace focus and opening a commit diff from the commit graph.
The pnpm website type check, lint, format check, and 15-page bilingual build pass
after removing internal architecture, domain rule, and requirements pages.

## Persistent panels and interactive PTY checks

Local headless Neovim checks pass terminal creation, switching, split-group
hide/restore without killing jobs, source buffer navigation, terminal-aware custom
keys, visible search options, real ripgrep matching semantics, and CLI chat output
through a native terminal. The fixture chat remains isolated until its patch is
reviewed and explicitly accepted. Installed-plugin smoke passes explorer and Git
flows after the new panel integration. These are local fixture providers, not
authenticated Codex, Claude, or Gemini inference tests.

A fresh warm headless sample on macOS arm64 / Neovim 0.12.6 measured median
98.74 ms across 98.74, 97.19, 104.87, 95.53, 101.8, 88.75, and 99.95 ms. This
includes launcher and exit, excludes interactive panels/LSPs/debuggers/models, and
is not directly comparable to the earlier host-load sample or a typing-latency
claim. Reproduce with scripts/benchmarks/startup.py after installing plugins.

The November 2 interactive TUI checks additionally cover empty launch, explicit
file, directory argument, and welcome disabled. All preserve the intended editor
content while showing Tokyo Night, files, and Agents in a wide terminal. PTY core
tests include actual resize propagation, output draining, duplicate-ownership
rejection, queued/running cancellation, and failed-session partial review.

Resource accounting methodology, fixture boundaries, CPU units, RSS, and macOS
footprint results are recorded in [performance.md](performance.md). The final
resource probe validates Mach CPU conversion against both own and child POSIX
clocks. Shared event-driven status updates retain the active-task polling fallback.

## Reader experience and replacement workflow

The reader site uses Astro MDX collections and genuine Neovim UI captures. Screenshots show an example workspace and a local command-provider task, not authenticated model inference. Browser verification uses the internal browser. The editor checks cover separate theme identity and syntax colors, responsive dashboard wordmarks, individual byte-range replacement, repeated matches on one line, UTF-8, paths with spaces, stale results, unsaved buffers, and the native replacement dialog. Copilot configuration is present but provider authentication and live completion are not verified by these checks.

## Replacement focus regression and deployment recovery

The original separate replacement popup triggered Telescope's BufLeave cleanup,
closing the search picker during editing. The multi-field native dialog removes
that lifecycle conflict. The TUI regression exercises real terminal keyboard and
SGR mouse input: field switching, text entry, repeated individual replacements,
all-action cancellation and confirmation, UTF-8, and resize preservation.
Installed-plugin integration also covers repeated matches on one line.

The Vercel project previously used apps/web as its root while the checked-in
configuration expects the repository root. Project settings were aligned with
vercel.json and the rebuilt production deployment reached Ready.

## Directional divider controls and saved chat output

Native-window checks cover divider movement from left/right and upper/lower
panes. A real PTY injects the xterm Ctrl Shift arrow sequences and verifies actual
divider positions. This validates Neovim decoding; Terminal.app still needs to
transmit those sequences. A fresh chat module reads persisted output from the
local service without launching another provider. This is output recovery, not
provider session resumption or PTY reattachment.

## Sequential search and terminal list

The real PTY regression opens Ctrl F, visits every option by Tab, toggles with
Space, navigates Next/Previous, and repeats Replace one without closing. Source
location is revealed without taking focus. Installed integration verifies search
reads unsaved text while replacement protects it. Native panel fixtures cover
terminal-list selection and group hide/restore without stopping shells.
