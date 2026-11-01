"""Application boundary for independent tasks and explicit snapshot-bound review."""
import hashlib
import os
import subprocess
import sys
import threading
import time
import uuid
from pathlib import Path

from . import git, providers
from .errors import ForgeError
from .store import Store


class AgentService:
    def __init__(self, root):
        self.root = git.repository(root)
        git.prepare_state(self.root)
        self.store = Store(self.root / ".forge")

    def start(self, prompt, provider="codex", custom=None):
        if not prompt.strip():
            raise ForgeError("Task prompt cannot be empty.")
        arguments = providers.command(provider, custom)
        with self.store.locked():
            git.ensure_clean(self.root)
            task_id = uuid.uuid4().hex[:12]
            directory = self.store.directory / "tasks" / task_id
            directory.mkdir(parents=True)
            task = {
                "id": task_id, "prompt": prompt, "provider": provider,
                "command": arguments, "root": str(self.root), "base": git.head(self.root),
                "branch": "forge/" + task_id,
                "worktree": str(self.store.directory / "worktrees" / task_id),
                "directory": str(directory), "status": "queued", "created_at": time.time(),
                "heartbeat": time.time(), "review_hash": None,
            }
            git.create_worktree(self.root, task["worktree"], task["branch"], task["base"])
            self.store.save(task, "created")
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

    def tasks(self):
        with self.store.locked():
            tasks = self.store.tasks()
            for task in tasks:
                if task["status"] in ("queued", "running", "cancelling") and time.time() - task["heartbeat"] > 30:
                    task.update(status="interrupted", error="Worker heartbeat expired; inspect logs and worktree before manual recovery.")
                    self.store.save(task, "worker_lost")
            return tasks

    def review(self, task_id):
        with self.store.locked():
            task = self.store.get(task_id)
            if task["status"] not in ("ready", "failed", "reviewing"):
                raise ForgeError("Task must finish before review.")
            patch = git.snapshot(task)
            digest = hashlib.sha256(patch).hexdigest()
            (Path(task["directory"]) / "review.patch").write_bytes(patch)
            task.update(status="reviewing", review_hash=digest)
            self.store.save(task, "reviewed")
            return {"task": task, "hash": digest, "patch": patch.decode("utf-8", "replace")}

    def accept(self, task_id, digest):
        with self.store.locked():
            task = self.store.get(task_id)
            if task["status"] != "reviewing" or not digest or digest != task["review_hash"]:
                raise ForgeError("Review this task and pass its current snapshot hash before accepting.")
            patch = (Path(task["directory"]) / "review.patch").read_bytes()
            if hashlib.sha256(patch).hexdigest() != digest or hashlib.sha256(git.snapshot(task)).hexdigest() != digest:
                raise ForgeError("Agent changes changed after review. Review again.")
            git.ensure_clean(self.root)
            if git.head(self.root) != task["base"]:
                raise ForgeError("Target HEAD changed. Re-run the task from the current checkout.")
            if patch:
                git.apply(self.root, patch)
            task.update(status="accepted")
            return self.store.save(task, "accepted")

    def reject(self, task_id):
        with self.store.locked():
            task = self.store.get(task_id)
            if task["status"] not in ("ready", "failed", "reviewing"):
                raise ForgeError("Only a finished task can be rejected.")
            task.update(status="rejected")
            return self.store.save(task, "rejected")

    def cancel(self, task_id):
        with self.store.locked():
            task = self.store.get(task_id)
            if task["status"] not in ("queued", "running", "cancelling"):
                raise ForgeError("Task is not running.")
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
