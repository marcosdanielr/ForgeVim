import os
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))
import session  # noqa: E402


class SessionTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.mkdtemp(prefix="fs", dir="/tmp")
        self.previous = os.environ.get("XDG_STATE_HOME")
        os.environ["XDG_STATE_HOME"] = self.directory

    def tearDown(self):
        if self.previous is None:
            del os.environ["XDG_STATE_HOME"]
        else:
            os.environ["XDG_STATE_HOME"] = self.previous

    def test_socket_lives_in_state_directory(self):
        path = session.socket_path("agent-1")
        self.assertEqual(path.parent, session.sessions_directory())
        self.assertEqual(path.name, "agent-1.sock")

    def test_long_names_use_stable_digest(self):
        name = "x" * 200
        self.assertEqual(session.socket_path(name), session.socket_path(name))
        self.assertLess(len(str(session.socket_path(name))), 100)

    def test_unreachable_socket_is_not_alive_or_listed(self):
        self.assertFalse(session.alive(session.socket_path("missing")))
        self.assertEqual(session.names(), [])


if __name__ == "__main__":
    unittest.main()
