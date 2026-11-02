# Provider connections and notifications

Forge connects to the official local CLIs, using each provider's own login and
account access. It does not store OAuth tokens, proxy subscriptions, or embed API
keys. The available plan, quota, and model remain the provider's responsibility.
This follows Orca's bring-your-own-agent workflow without depending on Orca's app.

| Provider | CLI | Login | Task mode |
| --- | --- | --- | --- |
| ChatGPT / Codex | codex | codex login | exec, JSONL, workspace-write, noninteractive approvals |
| Claude Code | claude | claude auth login | print, stream-json, acceptEdits |
| Gemini | gemini | interactive gemini authentication flow | headless stdin, stream-json, auto_edit |

Use `:ForgeAgentConnect` to open the official login flow in a Neovim terminal.
Complete authentication yourself. Gemini opens its CLI; select the account login
flow and exit when done. `:ForgeAgentStart` asks which provider to use, then starts
an isolated task. A missing CLI is reported without silently installing anything.

Claude acceptEdits and Gemini auto_edit permit file edits while preserving other
provider permission checks. They do not grant blanket shell approval. Operations
requiring interaction may be denied in headless mode; inspect task logs. No YOLO,
bypass-permissions, or danger-full-access flag is used. Provider project/user
settings still apply. Only use trusted repositories and CLI configuration.

All providers use the same worktree, persistence, cancellation, and review rules.
Batch tasks use one-shot execution and raw JSONL logs. Interactive chat uses a native CLI PTY in its own worktree, with normal provider permission prompts. A normalized cross-provider message/approval interface is not implemented. CLI adapters are tested using local
fixtures and command contracts. Real model authentication/inference must be
verified by the account owner; tests do not spend model tokens.

## Notifications

`:ForgeNotifications` toggles editor notifications and persists the choice.
`notifications = true` is the default in user.lua. The menu preference overrides
that default. Start a task or open `:ForgeAgents` to watch active work. Panels and notifications share native event wakeups and a five-second active-task
fallback; polling stops after tasks finish. It never
starts providers on startup or sends unchanged-status notifications. An open Agents panel can separately read existing task status. Disabling
notifications stops watchers immediately; reopen the agent menu after re-enabling.

Notify once on ready, failed, cancelled, or interrupted states. Messages contain
provider, task ID, and outcome, without including prompt content. No notification
is sent to external services. These notifications require an open editor; OS push
notifications while it is closed and mobile push are future gateway capabilities.

## Official references

- [Codex non-interactive](https://developers.openai.com/codex/noninteractive/)
- [Claude CLI](https://code.claude.com/docs/en/cli-reference)
- [Claude authentication](https://code.claude.com/docs/en/authentication)
- [Gemini headless](https://geminicli.com/docs/cli/headless/)
- [Gemini authentication](https://geminicli.com/docs/get-started/authentication/)


## Interactive terminal lifecycle

`:ForgeChatNew` prepares a queued interactive task without executing a provider.
The attached terminal runner claims that task once, owns the provider PTY, relays
input/output and resize events, and updates heartbeat state. Normal exit makes the
result reviewable; provider errors retain partial changes as failed output.
Cancellation signals only the PTY process group created by that runner. A queued
chat can be cancelled before a terminal exists. No recovered PID is signalled.

Codex uses `-a on-request --sandbox workspace-write`; Claude and Gemini keep their
normal interactive controls. No bypass-permissions or YOLO option is introduced.
Hiding a split preserves the terminal. Closing the editor closes its attached PTY;
batch workers retain their independent lifecycle. Provider-native resume features
are not a Forge PTY reattachment guarantee. Tests exercise real local PTYs with
fixture executables, not authenticated model calls.
