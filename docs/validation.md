# Validation record

Observed locally on November 1, 2026, on macOS arm64 with the checkout on DEV_SSD.
This is a reproducible engineering check record, not a universal performance or
security certification.

## Agent core

19 standard-library unittest cases pass: isolated concurrent tasks, new/deleted and
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
contains both locale trees, including translated domain rules and requirements.
Rule/requirement identifier sets match between English and Portuguese.

Browser QA uses the Codex internal browser. Light/dark/system controls, manual
locale navigation, demo tabs, docs navigation, and copy controls are checked in the
visible layout. The first narrow layout was inspected before bilingual additions;
final responsive QA and any remaining limitation are recorded at handoff.

All three scoped skills pass the skill-creator validator. GitHub CI configuration
runs Python 3.9/3.13 core checks, Neovim 0.11.5 smoke, StyLua, and website gates.
A workflow file alone is not evidence that hosted CI has passed.

Production dependency audit after the Astro update reports zero known
vulnerabilities. This does not establish absence of unknown issues or replace
reviewing dependency updates.
