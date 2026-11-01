"""Agent business rules. Rule IDs are defined in docs/business-rules.md.

These functions decide whether a lifecycle operation is allowed. They perform no
Git, SQLite, process, filesystem, or UI work. Adapters enforce external facts.
"""
from .errors import ForgeError

ACTIVE_STATUSES = frozenset({"queued", "running", "cancelling"})
REVIEWABLE_STATUSES = frozenset({"ready", "failed", "reviewing"})
TERMINAL_STATUSES = frozenset({"accepted", "rejected", "cancelled"})
HEARTBEAT_TIMEOUT_SECONDS = 30


def require_prompt(prompt: str) -> None:
    """BR-AG-01: every task has a nonempty human instruction."""
    if not prompt.strip():
        raise ForgeError("Task prompt cannot be empty.")


def require_finished(status: str) -> None:
    """BR-AG-03: running or interrupted output is never reviewable."""
    if status not in REVIEWABLE_STATUSES:
        raise ForgeError("Task must finish before review.")


def require_review(status: str, expected_hash: str, supplied_hash: str) -> None:
    """BR-AG-04: only the current reviewed snapshot can be accepted once."""
    if status != "reviewing" or not supplied_hash or supplied_hash != expected_hash:
        raise ForgeError("Review this task and pass its current snapshot hash before accepting.")


def require_rejectable(status: str) -> None:
    """BR-AG-07: rejection is a finished-task decision, never cancellation."""
    if status not in REVIEWABLE_STATUSES:
        raise ForgeError("Only a finished task can be rejected.")


def require_cancellable(status: str) -> None:
    """BR-AG-08: only the task's active worker receives a cancellation request."""
    if status not in ACTIVE_STATUSES:
        raise ForgeError("Task is not running.")
