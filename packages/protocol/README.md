# Agent CLI protocol v1

Invoke `bin/forge-agents --root <git-checkout> <command>`. Arguments are arrays,
never shell strings. Stdout contains one JSON envelope; exit code 0 means success,
1 means an application failure. Invalid CLI syntax uses argparse exit code 2.

```json
{"version":1,"ok":true,"data":[]}
```

```json
{"version":1,"ok":false,"error":"Unknown task: example"}
```

## Commands

| Command | Arguments | Result |
| --- | --- | --- |
| start | `--prompt text [--provider codex|claude|gemini]` | Task |
| start | `--prompt text --provider command --command-json '["executable"]'` | Task |
| chat | `--prompt title [--provider codex|claude|gemini]` | Queued interactive Task; no provider executes yet |
| list | none | Task[] |
| review | id | `{task, hash, patch}` |
| accept | id `--hash sha256` | Task |
| reject | id | Task |
| cancel | id | Task with cancellation requested |
| logs | id | Tail of combined stdout/stderr, at most 256 KiB |
| events | `--after sequence` | Up to 500 ordered events |

A custom provider receives the task prompt on stdin and EOF. The command is
trusted local configuration, not a remotely supplied executable or a shell.
Each bundled provider uses its own CLI authentication and model settings. Forge explicitly
requests workspace-write sandbox and non-interactive approval behavior.

Tasks contain id, prompt, provider, root, worktree, branch, base, directory, optional mode (`batch` or `interactive`),
status, created_at, heartbeat, and optional review_hash, review_head, exit_code, finished_at,
and error. Internal executable arguments are local-only metadata. Future remote
transports must project a safe public task view and must not expose local paths,
commands, prompts, or logs without explicit authorization.

States: queued, running, cancelling, cancelled, interrupted, ready, failed, reviewing,
accepted, rejected. Only ready/failed/reviewing tasks can produce a review.
Failed-task review explicitly includes partial output. Accepted and rejected tasks
are terminal. Review patches are whole snapshots; binary changes use Git's binary
patch encoding. `patch` is display text; application uses the frozen bytes.

An event has sequence, task_id, kind, timestamp (Unix seconds), and data. Use the
last sequence as the next cursor. Raw provider JSONL is retained in logs, not
normalized into these lifecycle events. No network transport is implemented.

`review_head` binds acceptance to the target HEAD observed during review. A new
review may target a later clean commit without rebasing the agent worktree, but
the unchanged patch must still pass Git conflict checks.


## Raw interactive attachment

After `chat` returns a task, the local editor starts
`python3 -m forge_agents.chat --root <checkout> <id>` with the agent package on
PYTHONPATH and a real terminal. This command relays raw terminal I/O; it is not a
JSON protocol command. It rejects duplicate ownership and any non-queued task.
Input, resize, normal provider prompts, and final lifecycle state share the same
worktree and review invariants as batch tasks. A queued interactive cancellation
may immediately return cancelled; running cancellation remains worker-owned.
