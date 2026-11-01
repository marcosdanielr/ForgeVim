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
| BR-AG-05 | The worktree patch and frozen bytes must still match the reviewed hash. Target HEAD must match the task base and target Git status must be clean. Git must accept the patch without conflicts. | AgentService.accept; git.apply | binary/new-file, dirty-target, changed-HEAD tests |
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

Accepting one task dirties the source checkout. After committing it, sibling tasks
have an old base and must be rerun. Automatic rebase and partial/hunk application
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
| BR-WEB-01 | Theme defaults to system. Explicit light/dark preference persists; automatic mode follows later OS changes. Storage failure must not break the page. | scripts/theme.ts; BaseLayout prepaint |
| BR-WEB-02 | Illustrative demos are labeled and do not execute real tasks or imply future features exist today. | home components; lib/docs.ts |
| BR-WEB-03 | GitHub and Buy Me a Coffee destinations come from one typed configuration source. | lib/site.ts |
| BR-WEB-04 | Presentation and docs remain accessible at narrow widths and through keyboard navigation; reduced-motion preference is respected. | global.css; scripts/site.ts |
| BR-WEB-05 | Site and repository stay private until the owner explicitly changes their audience. | hosting and repository settings |

BR-ED-09: shortcut preferences use stable command IDs, apply immediately, and
persist as data. Add/replace/reset workflows must detect existing mappings and
preserve native single-key motions and Ctrl W. Owner: features.shortcuts and
core.keymaps. Evidence: native editor smoke customization/reset checks.

BR-ED-10: Nerd Fonts are opt-in. Missing patched fonts must not prevent basic
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
