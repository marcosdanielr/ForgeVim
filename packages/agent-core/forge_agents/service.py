"""Application boundary for independent tasks and explicit snapshot-bound review."""
import hashlib
import os
import subprocess
import sys
import threading
import time
from pathlib import Path

from . import git, policy, providers, tasks
from .errors import ForgeError
from .store import Store


class AgentService:
    def __init__(self, root, initialize=True):
        existing = Path(root).resolve()
        if not initialize and (existing / ".forge/state.sqlite3").is_file():
            self.root = existing
            self.store = Store(existing / ".forge", initialize=False)
            return
        self.root = git.repository(root)
        git.prepare_state(self.root)
        self.store = Store(self.root / ".forge")

    def start(self, prompt, provider="codex", custom=None):
        policy.require_prompt(prompt)
        arguments = providers.command(provider, custom)
        with self.store.locked():
            task = tasks.create(self.store, self.root, prompt, provider, arguments)
            directory = Path(task["directory"])
            task_id = task["id"]
            environment = dict(os.environ)
            package = str(Path(__file__).resolve().parent.parent)
            environment["PYTHONPATH"] = package + os.pathsep + environment.get("PYTHONPATH", "")
            try:
                with (directory / "worker.log").open("ab") as log:
                    worker = subprocess.Popen(
                        [sys.executable, "-m", "forge_agents.worker", str(self.root), task_id],
                        cwd=self.root, env=environment, stdin=subprocess.DEVNULL,
                        stdout=log, stderr=log, start_new_session=True,
                    )
                    threading.Thread(target=worker.wait, daemon=True).start()
            except OSError as error:
                task.update(status="failed", error=str(error))
                self.store.save(task, "failed")
                raise ForgeError(str(error)) from error
            return task

    def create_chat(self, prompt, provider="codex", custom=None):
        arguments = providers.interactive_command(provider, custom)
        with self.store.locked():
            return tasks.create(self.store, self.root, prompt, provider, arguments, "interactive")

    def tasks(self):
        with self.store.locked():
            tasks = self.store.tasks()
            for task in tasks:
                if task["status"] in policy.ACTIVE_STATUSES and time.time() - task["heartbeat"] > policy.HEARTBEAT_TIMEOUT_SECONDS:
                    task.update(status="interrupted", error="Worker heartbeat expired; inspect logs and worktree before manual recovery.")
                    self.store.save(task, "worker_lost")
            return tasks

    def review(self, task_id):
        with self.store.locked():
            task = self.store.get(task_id)
            policy.require_finished(task["status"])
            patch = git.snapshot(task)
            digest = hashlib.sha256(patch).hexdigest()
            (Path(task["directory"]) / "review.patch").write_bytes(patch)
            task.update(status="reviewing", review_hash=digest, review_head=git.head(self.root))
            self.store.save(task, "reviewed")
            return {"task": task, "hash": digest, "patch": patch.decode("utf-8", "replace")}

    def accept(self, task_id, digest):
        with self.store.locked():
            task = self.store.get(task_id)
            policy.require_review(task["status"], task["review_hash"], digest)
            patch = (Path(task["directory"]) / "review.patch").read_bytes()
            if hashlib.sha256(patch).hexdigest() != digest or hashlib.sha256(git.snapshot(task)).hexdigest() != digest:
                raise ForgeError("Agent changes changed after review. Review again.")
            git.ensure_clean(self.root)
            if git.head(self.root) != task.get("review_head", task["base"]):
                raise ForgeError("Target HEAD changed since review. Review the patch again.")
            if patch:
                git.apply(self.root, patch)
            task.update(status="accepted")
            return self.store.save(task, "accepted")

    def reject(self, task_id):
        with self.store.locked():
            task = self.store.get(task_id)
            policy.require_rejectable(task["status"])
            task.update(status="rejected")
            return self.store.save(task, "rejected")

    def cancel(self, task_id):
        with self.store.locked():
            task = self.store.get(task_id)
            policy.require_cancellable(task["status"])
            if task.get("mode") == "interactive" and task["status"] == "queued":
                task.update(status="cancelled", finished_at=time.time())
                return self.store.save(task, "cancelled")
            (Path(task["directory"]) / "cancel").touch()
            task.update(status="cancelling")
            return self.store.save(task, "cancel_requested")

    def logs(self, task_id):
        task = self.store.get(task_id)
        path = Path(task["directory"]) / "agent.log"
        if not path.exists():
            return ""
        with path.open("rb") as stream:
            stream.seek(max(0, path.stat().st_size - 256 * 1024))
            return stream.read().decode("utf-8", "replace")
