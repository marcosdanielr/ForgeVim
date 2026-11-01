import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from forge_agents import providers
from forge_agents.errors import ForgeError


class ProviderTests(unittest.TestCase):
    @patch("forge_agents.providers.shutil.which", side_effect=lambda executable: "/trusted/" + executable)
    def test_official_provider_commands_preserve_permission_controls(self, _):
        expected = {
            "codex": ["/trusted/codex", "-a", "never", "exec", "--sandbox", "workspace-write", "--json", "-"],
            "claude": ["/trusted/claude", "--print", "--output-format", "stream-json", "--verbose", "--permission-mode", "acceptEdits"],
            "gemini": ["/trusted/gemini", "--output-format", "stream-json", "--approval-mode", "auto_edit"],
        }
        for provider, arguments in expected.items():
            with self.subTest(provider=provider):
                self.assertEqual(providers.command(provider), arguments)
                self.assertNotIn("--yolo", arguments)
                self.assertNotIn("--dangerously-skip-permissions", arguments)

    @patch("forge_agents.providers.shutil.which", return_value=None)
    def test_missing_cli_is_actionable(self, _):
        with self.assertRaisesRegex(ForgeError, "executable not found"):
            providers.command("gemini")

    def test_custom_command_cannot_be_a_shell_string(self):
        with self.assertRaises(ForgeError):
            providers.command("command", "echo bad; rm something")
