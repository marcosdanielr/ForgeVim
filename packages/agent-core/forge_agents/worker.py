"""Detached worker. Only its owner signals the provider's process group."""
import os
import signal
import subprocess
import sys
import time
from pathlib import Path

from .providers import instruction
from .store import Store


def terminate(process):
    if process.poll() is not None:
        return
    try:
        os.killpg(process.pid, signal.SIGTERM)
        process.wait(timeout=3)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        process.wait()
    except ProcessLookupError:
        process.wait()


def run(root, task_id):
    store = Store(Path(root) / ".forge")
    process = None
    try:
        with store.locked():
            task = store.get(task_id)
            if task["status"] == "cancelling":
                task.update(status="cancelled")
                store.save(task, "cancelled")
                return
            if task["status"] != "queued":
                return
            task.update(status="running", heartbeat=time.time())
            store.save(task, "started")
        directory = Path(task["directory"])
        with (directory / "agent.log").open("ab") as output:
            # File-backed stdin avoids pipe deadlocks for large prompts.
            prompt = directory / "prompt.txt"
            prompt.write_text(instruction(task["prompt"]))
            with prompt.open("rb") as input_stream:
                process = subprocess.Popen(
                    task["command"], cwd=task["worktree"], stdin=input_stream,
                    stdout=output, stderr=output, start_new_session=True,
                )
            while process.poll() is None:
                if (directory / "cancel").exists():
                    terminate(process)
                    break
                with store.locked():
                    current = store.get(task_id)
                    current.update(heartbeat=time.time())
                    store.save(current)
                time.sleep(0.2)
        with store.locked():
            current = store.get(task_id)
            cancelled = (directory / "cancel").exists()
            current.update(
                status="cancelled" if cancelled else ("ready" if process.returncode == 0 else "failed"),
                exit_code=process.returncode, heartbeat=time.time(), finished_at=time.time(),
            )
            store.save(current, current["status"])
    except Exception as error:
        if process is not None:
            terminate(process)
        with store.locked():
            task = store.get(task_id)
            task.update(status="failed", error=str(error))
            store.save(task, "failed")


if __name__ == "__main__":
    run(sys.argv[1], sys.argv[2])
