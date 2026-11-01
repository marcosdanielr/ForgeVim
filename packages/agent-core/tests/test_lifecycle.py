"""End-to-end lifecycle tests with local processes; no model calls or credentials."""
import concurrent.futures
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from forge_agents import git
from forge_agents.errors import ForgeError
from forge_agents.service import AgentService


class LifecycleTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="forge test ")
        self.root = Path(self.temporary.name)
        git.run(self.root, "init", "-b", "main")
        git.run(self.root, "config", "user.email", "test@example.com")
        git.run(self.root, "config", "user.name", "Forge Tests")
        (self.root / "sample.txt").write_text("before\n")
        git.run(self.root, "add", ".")
        git.run(self.root, "commit", "-m", "chore: add fixture")
        self.service = AgentService(self.root)

    def tearDown(self):
        for task in self.service.tasks():
            if task["status"] in ("queued", "running", "cancelling"):
                self.service.cancel(task["id"])
                self.wait(task)
        self.temporary.cleanup()

    def start(self, script):
        return self.service.start("Task with $() and `literal` input", "command", [sys.executable, "-c", script])

    def wait(self, task):
        deadline = time.monotonic() + 12
        while time.monotonic() < deadline:
            current = self.service.store.get(task["id"])
            if current["status"] not in ("queued", "running", "cancelling"):
                return current
            time.sleep(0.05)
        self.fail("Task did not finish: " + str(current))

    def ready(self, script="from pathlib import Path; Path('sample.txt').write_text('after\\n')"):
        task = self.start(script)
        self.assertEqual(self.wait(task)["status"], "ready")
        return task

    def test_review_accept_new_binary_and_committed_changes(self):
        task = self.ready("from pathlib import Path; import subprocess; "
                          "Path('new.bin').write_bytes(bytes(range(256))); "
                          "Path('sample.txt').write_text('after\\n'); "
                          "subprocess.run(['git','add','.'],check=True); "
                          "subprocess.run(['git','commit','-m','feat: change fixture'],check=True)")
        self.assertEqual((self.root / "sample.txt").read_text(), "before\n")
        review = self.service.review(task["id"])
        accepted = self.service.accept(task["id"], review["hash"])
        self.assertEqual(accepted["status"], "accepted")
        self.assertEqual((self.root / "sample.txt").read_text(), "after\n")
        self.assertEqual((self.root / "new.bin").read_bytes(), bytes(range(256)))
        self.assertEqual(git.head(self.root), task["base"])
        with self.assertRaises(ForgeError):
            self.service.accept(task["id"], review["hash"])

    def test_untracked_and_deleted_files_are_reviewed(self):
        task = self.ready("from pathlib import Path; Path('sample.txt').unlink(); Path('new.txt').write_text('new')")
        review = self.service.review(task["id"])
        self.assertIn("new.txt", review["patch"])
        self.service.accept(task["id"], review["hash"])
        self.assertFalse((self.root / "sample.txt").exists())
        self.assertEqual((self.root / "new.txt").read_text(), "new")

    def test_wrong_hash_and_changed_agent_patch_are_rejected(self):
        task = self.ready()
        review = self.service.review(task["id"])
        with self.assertRaises(ForgeError):
            self.service.accept(task["id"], "wrong")
        (Path(task["worktree"]) / "sample.txt").write_text("changed again")
        with self.assertRaisesRegex(ForgeError, "changed after review"):
            self.service.accept(task["id"], review["hash"])
        self.assertEqual((self.root / "sample.txt").read_text(), "before\n")

    def test_tampered_frozen_patch_is_rejected(self):
        task = self.ready()
        review = self.service.review(task["id"])
        (Path(task["directory"]) / "review.patch").write_text("tampered")
        with self.assertRaises(ForgeError):
            self.service.accept(task["id"], review["hash"])

    def test_dirty_target_and_changed_head_are_rejected(self):
        task = self.ready()
        review = self.service.review(task["id"])
        (self.root / "sample.txt").write_text("user changes")
        with self.assertRaisesRegex(ForgeError, "Commit or stash"):
            self.service.accept(task["id"], review["hash"])
        git.run(self.root, "add", ".")
        git.run(self.root, "commit", "-m", "feat: user change")
        with self.assertRaisesRegex(ForgeError, "HEAD changed"):
            self.service.accept(task["id"], review["hash"])

    def test_reject_preserves_worktree(self):
        task = self.ready()
        self.service.reject(task["id"])
        self.assertTrue(Path(task["worktree"]).exists())
        self.assertEqual((self.root / "sample.txt").read_text(), "before\n")
        with self.assertRaises(ForgeError):
            self.service.review(task["id"])

    def test_cancel_running_process(self):
        task = self.start("import time; print('started', flush=True); time.sleep(20)")
        deadline = time.monotonic() + 5
        while not self.service.logs(task["id"]) and time.monotonic() < deadline:
            time.sleep(0.05)
        self.service.cancel(task["id"])
        self.assertEqual(self.wait(task)["status"], "cancelled")
        self.assertTrue(Path(task["worktree"]).exists())

    def test_failed_provider_can_be_reviewed(self):
        task = self.start("from pathlib import Path; Path('partial.txt').write_text('partial'); raise SystemExit(2)")
        self.assertEqual(self.wait(task)["status"], "failed")
        self.assertIn("partial.txt", self.service.review(task["id"])["patch"])

    def test_concurrent_tasks_and_event_cursor(self):
        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
            tasks = list(pool.map(lambda number: self.start(
                "from pathlib import Path; Path('task" + str(number) + ".txt').write_text('done')"), range(3)))
        for task in tasks:
            self.assertEqual(self.wait(task)["status"], "ready")
        self.assertEqual(len({task["worktree"] for task in tasks}), 3)
        self.assertFalse(any(self.root.glob("task*.txt")))
        events = self.service.store.events(0)
        self.assertGreaterEqual(len(events), 9)
        self.assertEqual(self.service.store.events(events[-1]["sequence"]), [])

    def test_dirty_source_and_unknown_task_are_actionable(self):
        (self.root / "sample.txt").write_text("dirty")
        with self.assertRaisesRegex(ForgeError, "Commit or stash"):
            self.start("print('no')")
        with self.assertRaisesRegex(ForgeError, "Unknown task"):
            self.service.review("../../outside")

    def test_reserved_state_is_never_applied(self):
        task = self.ready("from pathlib import Path; import subprocess; "
                          "Path('.forge').mkdir(); Path('.forge/owned').write_text('no'); "
                          "subprocess.run(['git','add','-f','.forge/owned'],check=True)")
        with self.assertRaisesRegex(ForgeError, "reserved"):
            self.service.review(task["id"])

    def test_live_task_cannot_be_accepted_or_rejected(self):
        task = self.start("import time; time.sleep(10)")
        with self.assertRaises(ForgeError):
            self.service.review(task["id"])
        with self.assertRaises(ForgeError):
            self.service.reject(task["id"])
        with self.assertRaises(ForgeError):
            self.service.accept(task["id"], hashlib.sha256(b"").hexdigest())

    def test_cli_envelope_and_error_exit(self):
        environment = dict(os.environ, PYTHONPATH=str(Path(__file__).resolve().parents[1]), PYTHONDONTWRITEBYTECODE="1")
        result = subprocess.run([sys.executable, "-m", "forge_agents", "--root", str(self.root), "list"],
                                env=environment, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(json.loads(result.stdout), {"version": 1, "ok": True, "data": []})
        result = subprocess.run([sys.executable, "-m", "forge_agents", "--root", str(self.root), "review", "unknown"],
                                env=environment, capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertFalse(json.loads(result.stdout)["ok"])


if __name__ == "__main__":
    unittest.main()
