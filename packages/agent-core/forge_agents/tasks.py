"""Create an isolated task. Callers hold the store mutation lock."""
import time
import uuid

from . import git, policy


def create(store, root, prompt, provider, arguments, mode="batch"):
    policy.require_prompt(prompt)
    git.ensure_clean(root)
    task_id = uuid.uuid4().hex[:12]
    directory = store.directory / "tasks" / task_id
    directory.mkdir(parents=True)
    task = {
        "id": task_id, "prompt": prompt, "provider": provider, "mode": mode,
        "command": arguments, "root": str(root), "base": git.head(root),
        "branch": "forge/" + task_id,
        "worktree": str(store.directory / "worktrees" / task_id),
        "directory": str(directory), "status": "queued", "created_at": time.time(),
        "heartbeat": time.time(), "review_hash": None,
    }
    git.create_worktree(root, task["worktree"], task["branch"], task["base"])
    return store.save(task, "created")
