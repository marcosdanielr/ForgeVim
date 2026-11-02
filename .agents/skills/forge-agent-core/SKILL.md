---
name: forge-agent-core
description: Change ForgeVim agent lifecycle, providers, worktrees, persistence, or review protocol with regression proof for patch acceptance.
---

Read `AGENTS.md`, `docs/architecture.md`, and `packages/protocol/README.md`.
Keep lifecycle invariants in the application service, Git behavior in the Git
adapter, persistence in the store, and provider command construction in providers.
The core must remain independent from Neovim and any future mobile transport.

Never interpolate shell commands or weaken snapshot hashes, target cleanliness,
base HEAD checks, or conflict checks to make a test pass. Preserve rejected
worktrees and logs. Keep state changes transactional, and cancellation limited to
the task's process group. Do not use PID-only recovery after a worker restart.

Exercise behavior in temporary Git repositories with a local fake provider. Cover
new files, committed agent changes, conflicts, stale review hashes, rejection,
cancellation, and concurrent tasks. Do not run paid models to validate plumbing.
