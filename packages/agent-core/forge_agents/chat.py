"""Interactive CLI entry point. Raw terminal I/O is separate from JSON protocol v1."""
import argparse
import sys
import time
from pathlib import Path

from . import policy
from .errors import ForgeError
from .store import Store
from .terminal import relay


def run(root, task_id):
    store = Store(Path(root) / ".forge")
    with store.locked():
        task = store.get(task_id)
        policy.require_interactive_start(task.get("mode"), task["status"])
        task.update(status="running", heartbeat=time.time())
        store.save(task, "started")
    directory = Path(task["directory"])
    last_heartbeat = 0.0

    def tick():
        nonlocal last_heartbeat
        if (directory / "cancel").exists():
            return True
        if time.monotonic() - last_heartbeat >= 1:
            with store.locked():
                current = store.get(task_id)
                current.update(heartbeat=time.time())
                store.save(current)
            last_heartbeat = time.monotonic()
        return False

    try:
        with (directory / "agent.log").open("ab") as log:
            code, stopped = relay(task["command"], task["worktree"], log, tick)
        status = "cancelled" if stopped else ("ready" if code == 0 else "failed")
        with store.locked():
            current = store.get(task_id)
            current.update(status=status, exit_code=code, heartbeat=time.time(), finished_at=time.time())
            store.save(current, status)
        return code if code >= 0 else 1
    except Exception as error:
        with store.locked():
            current = store.get(task_id)
            current.update(status="failed", error=str(error), finished_at=time.time())
            store.save(current, "failed")
        raise


def main():
    parser = argparse.ArgumentParser(prog="forge-chat")
    parser.add_argument("--root", required=True)
    parser.add_argument("id")
    arguments = parser.parse_args()
    try:
        raise SystemExit(run(arguments.root, arguments.id))
    except (ForgeError, OSError) as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1) from error


if __name__ == "__main__":
    main()
