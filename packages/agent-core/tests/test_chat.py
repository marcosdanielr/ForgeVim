"""Real local PTY lifecycle tests. No paid models or account authentication."""
import json
import fcntl
import pty
import signal
import struct
import termios
import os
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from forge_agents import git, providers
from forge_agents.errors import ForgeError
from forge_agents.service import AgentService


class InteractiveTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="forge chat ")
        self.root = Path(self.temporary.name)
        git.run(self.root, "init", "-b", "main")
        git.run(self.root, "config", "user.email", "test@example.com")
        git.run(self.root, "config", "user.name", "Forge Tests")
        (self.root / "sample.txt").write_text("before\n")
        git.run(self.root, "add", ".")
        git.run(self.root, "commit", "-m", "chore: add fixture")
        self.service = AgentService(self.root)
        self.runners = []
        self.environment = dict(os.environ, PYTHONPATH=str(Path(__file__).resolve().parents[1]),
                                PYTHONDONTWRITEBYTECODE="1")

    def tearDown(self):
        for process, task in self.runners:
            if process.poll() is None:
                self.service.cancel(task["id"])
                process.communicate(timeout=8)
        self.temporary.cleanup()

    def prepare(self, script):
        return self.service.create_chat("Inspect this project", "command", [sys.executable, "-c", script])

    def command(self, task):
        return [sys.executable, "-m", "forge_agents.chat", "--root", str(self.root), task["id"]]

    def running(self):
        task = self.prepare("import time; print('ready',flush=True); time.sleep(20)")
        process = subprocess.Popen(self.command(task), env=self.environment,
                                   stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.runners.append((process, task))
        deadline = time.monotonic() + 5
        while "ready" not in self.service.logs(task["id"]):
            if time.monotonic() > deadline:
                self.fail("PTY provider did not start")
            time.sleep(0.02)
        return process, task

    def test_interactive_input_stays_isolated_until_review(self):
        task = self.prepare("import os; from pathlib import Path; "
                            "print('tty=' + str(os.isatty(0)),flush=True); "
                            "text=input(); Path('sample.txt').write_text(text+'\\n')")
        result = subprocess.run(self.command(task), input=b"after\n", capture_output=True,
                                env=self.environment, timeout=8)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(b"tty=True", result.stdout)
        self.assertEqual(self.service.store.get(task["id"])["status"], "ready")
        self.assertEqual((self.root / "sample.txt").read_text(), "before\n")
        review = self.service.review(task["id"])
        self.service.accept(task["id"], review["hash"])
        self.assertEqual((self.root / "sample.txt").read_text(), "after\n")
        self.assertEqual(git.head(self.root), task["base"])

    def test_cancel_owned_session_and_block_running_review(self):
        process, task = self.running()
        with self.assertRaises(ForgeError):
            self.service.review(task["id"])
        self.service.cancel(task["id"])
        process.communicate(timeout=8)
        self.assertEqual(self.service.store.get(task["id"])["status"], "cancelled")
        self.assertTrue(Path(task["worktree"]).is_dir())

    def test_duplicate_runner_cannot_take_ownership(self):
        process, task = self.running()
        duplicate = subprocess.run(self.command(task), capture_output=True, env=self.environment, timeout=5)
        self.assertNotEqual(duplicate.returncode, 0)
        self.assertIn(b"Only a queued interactive task", duplicate.stderr)
        self.assertIsNone(process.poll())

    def test_queued_cancel_does_not_require_a_worker(self):
        task = self.prepare("raise SystemExit('must not run')")
        self.assertEqual(self.service.cancel(task["id"])["status"], "cancelled")
        result = subprocess.run(self.command(task), capture_output=True, env=self.environment, timeout=5)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.service.store.get(task["id"])["status"], "cancelled")

    def test_terminal_output_drains_after_provider_exit(self):
        task = self.prepare("import sys; sys.stdout.write('x'*200000+'COMPLETE\\n'); sys.stdout.flush()")
        result = subprocess.run(self.command(task), stdin=subprocess.DEVNULL, capture_output=True,
                                env=self.environment, timeout=8)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(result.stdout.endswith(b"COMPLETE\r\n"))
        self.assertEqual((Path(task["directory"]) / "agent.log").read_bytes(), result.stdout)

    def test_ui_wakeup_follows_events_not_heartbeats(self):
        task = self.prepare("raise SystemExit(0)")
        marker = self.service.store.directory / "events.signal"
        self.assertTrue(marker.is_file())
        os.utime(marker, ns=(1, 1))
        self.service.store.save(task)
        self.assertEqual(marker.stat().st_mtime_ns, 1)
        self.service.cancel(task["id"])
        self.assertGreater(marker.stat().st_mtime_ns, 1)

    def test_resize_reaches_the_owned_provider_terminal(self):
        master, slave = pty.openpty()
        process = None
        try:
            fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 0, 0))
            task = self.prepare("import os; print('ready',flush=True); input(); "
                                "size=os.get_terminal_size(); print('SIZE='+str(size.columns)+'x'+str(size.lines),flush=True)")
            process = subprocess.Popen(self.command(task), env=self.environment,
                                       stdin=slave, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            self.runners.append((process, task))
            deadline = time.monotonic() + 5
            while "ready" not in self.service.logs(task["id"]):
                if time.monotonic() > deadline:
                    self.fail("Resize fixture did not start")
                time.sleep(0.02)
            fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack("HHHH", 31, 112, 0, 0))
            process.send_signal(signal.SIGWINCH)
            time.sleep(0.05)
            os.write(master, b"check\n")
            output, error = process.communicate(timeout=8)
            self.assertEqual(process.returncode, 0, error)
            self.assertIn(b"SIZE=112x31", output)
        finally:
            os.close(master)
            os.close(slave)

    def test_failed_chat_preserves_partial_changes_for_review(self):
        task = self.prepare("from pathlib import Path; Path('partial.txt').write_text('inspect'); raise SystemExit(2)")
        result = subprocess.run(self.command(task), stdin=subprocess.DEVNULL, capture_output=True,
                                env=self.environment, timeout=8)
        self.assertEqual(result.returncode, 2)
        self.assertEqual(self.service.store.get(task["id"])["status"], "failed")
        self.assertFalse((self.root / "partial.txt").exists())
        self.assertIn("partial.txt", self.service.review(task["id"])["patch"])

    def test_interactive_provider_contracts_preserve_permissions(self):
        with patch("shutil.which", side_effect=lambda name: "/bin/" + name):
            self.assertEqual(providers.interactive_command("codex"),
                             ["/bin/codex", "-a", "on-request", "--sandbox", "workspace-write"])
            self.assertEqual(providers.interactive_command("claude"), ["/bin/claude"])
            self.assertEqual(providers.interactive_command("gemini"), ["/bin/gemini"])
            with self.assertRaises(ForgeError):
                providers.interactive_command("command", "echo unsafe")

    def test_json_chat_preparation_does_not_start_provider(self):
        result = subprocess.run([sys.executable, "-m", "forge_agents", "--root", str(self.root),
                                 "chat", "--prompt", "Conversation", "--provider", "command",
                                 "--command-json", json.dumps([sys.executable, "-c", "raise SystemExit(99)"])],
                                capture_output=True, text=True, env=self.environment, timeout=5)
        self.assertEqual(result.returncode, 0, result.stderr)
        task = json.loads(result.stdout)["data"]
        self.assertEqual(task["mode"], "interactive")
        self.assertEqual(task["status"], "queued")
        self.assertFalse((Path(task["directory"]) / "agent.log").exists())
        self.service.cancel(task["id"])
