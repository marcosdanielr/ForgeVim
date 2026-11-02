"""Exercise installer ownership, retries, updates and actual launcher behavior."""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
from installer import service, source
from installer.paths import InstallPaths, load


class InstallationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="forge install ' ")
        self.directory = Path(self.temporary.name)
        self.paths = InstallPaths(self.directory / "prefix ' spaced", self.directory / "data",
            self.directory / "config", self.directory / "state")
        self.dependencies = patch("installer.dependencies.check")
        self.dependencies.start()
        self.addCleanup(self.dependencies.stop)
        self.addCleanup(self.temporary.cleanup)

    def install(self, **kwargs):
        return service.install(self.paths, ROOT, local=True, plugins=False, **kwargs)

    def fixture(self):
        root = self.directory / "remote ' source"
        (root / "apps/nvim").mkdir(parents=True)
        (root / "apps/web").mkdir(parents=True)
        (root / "bin").mkdir()
        (root / "apps/nvim/init.lua").write_text("-- fixture\n")
        (root / "apps/web/excluded.txt").write_text("not an editor dependency")
        (root / "bin/forge").write_text("#!/bin/sh\nexit 0\n")
        (root / "bin/forge").chmod(0o755)
        (root / ".gitignore").write_text("__pycache__/\n")
        self.git(root, "init", "-b", "main")
        self.git(root, "config", "user.name", "Installer test")
        self.git(root, "config", "user.email", "installer@example.com")
        self.commit(root, "chore: add fixture")
        return root

    def git(self, root, *arguments):
        subprocess.run(["git", "-C", str(root), *arguments], check=True, capture_output=True)

    def commit(self, root, message):
        self.git(root, "add", ".")
        self.git(root, "commit", "-m", message)

    def test_local_install_preserves_config_and_repeats(self):
        personal = self.paths.config / "lua/user.lua"
        personal.parent.mkdir(parents=True)
        personal.write_text("return { leader = ',' }\n")
        first = self.install()
        self.assertEqual(self.install(), first)
        self.assertEqual(personal.read_text(), "return { leader = ',' }\n")
        self.assertTrue(os.access(self.paths.command, os.X_OK))
        self.assertEqual(load(self.paths.manifest)["root"], str(ROOT))
        self.assertFalse((self.paths.data / "runtime").exists())

    def test_repository_rename_reuses_existing_profile(self):
        legacy = "https://github.com/marcosdanielr/forge.nvim.git"
        record = self.install(repository=legacy)
        record["local"] = False
        self.paths.manifest.write_text(json.dumps(record))
        before = self.paths.command.read_bytes()
        reused = service.install(self.paths, ROOT, local=False, plugins=False)
        self.assertEqual(reused["repository"], legacy)
        self.assertEqual(self.paths.command.read_bytes(), before)
        self.assertEqual(source.canonical_repository(legacy), source.REPOSITORY)
        self.assertEqual(source.canonical_repository(source.REPOSITORY.lower()), source.REPOSITORY)
        self.assertEqual(source.canonical_repository("file:///custom"), "file:///custom")

    def test_launcher_quotes_source_and_preserves_arguments_and_cwd(self):
        self.install()
        fake = self.directory / "fake nvim"
        fake.write_text("#!/usr/bin/env python3\nimport json, os, sys\nfrom pathlib import Path\nPath(os.environ['CAPTURE']).write_text(json.dumps([os.getcwd(), sys.argv[1:], os.environ['NVIM_APPNAME']]))\n")
        fake.chmod(0o755)
        capture = self.directory / "capture.json"
        subprocess.run([str(self.paths.command), "file with spaces.lua"], cwd=self.directory,
            env=dict(os.environ, FORGE_NVIM=str(fake), CAPTURE=str(capture)), check=True)
        cwd, arguments, appname = json.loads(capture.read_text())
        self.assertEqual(Path(cwd).resolve(), self.directory.resolve())
        self.assertEqual(arguments, ["-u", str(ROOT / "apps/nvim/init.lua"), "file with spaces.lua"])
        self.assertEqual(appname, "forge.nvim")

    def test_foreign_command_and_symlink_are_never_overwritten(self):
        self.paths.command.parent.mkdir(parents=True)
        self.paths.command.write_text("other application")
        with self.assertRaisesRegex(RuntimeError, "overwrite"):
            self.install()
        self.assertEqual(self.paths.command.read_text(), "other application")
        self.paths.command.unlink()
        target = self.directory / "important"
        target.write_text("keep")
        self.paths.command.symlink_to(target)
        with self.assertRaisesRegex(RuntimeError, "overwrite"):
            self.install()
        self.assertEqual(target.read_text(), "keep")

    def test_uninstall_preserves_source_config_and_state(self):
        self.install()
        preferences = self.paths.state / "preferences.json"
        preferences.write_text("personal state")
        service.uninstall(self.paths.manifest)
        self.assertFalse(self.paths.command.exists())
        self.assertTrue((self.paths.config / "lua/user.lua").exists())
        self.assertTrue((ROOT / "bin/forge").exists())
        self.assertEqual(preferences.read_text(), "personal state")
        self.install()
        self.assertTrue(self.paths.command.exists())

    def test_modified_launcher_is_not_deleted(self):
        self.install()
        self.paths.command.write_text("changed")
        with self.assertRaisesRegex(RuntimeError, "changed"):
            service.uninstall(self.paths.manifest)
        self.assertEqual(self.paths.command.read_text(), "changed")
        self.assertTrue(self.paths.manifest.exists())

    def test_missing_owned_launcher_is_recoverable(self):
        first = self.install()
        self.paths.command.unlink()
        self.assertEqual(self.install(), first)
        self.assertEqual(service.digest(self.paths.command), first["command_sha256"])

    def test_managed_install_is_sparse_and_can_fast_forward(self):
        remote = self.fixture()
        record = service.install(self.paths, ROOT, repository=str(remote), plugins=False)
        runtime = Path(record["root"])
        self.assertFalse((runtime / "apps/web/excluded.txt").exists())
        self.assertTrue((runtime / "apps/nvim/init.lua").exists())
        (remote / "apps/nvim/next.lua").write_text("return true\n")
        self.commit(remote, "feat: add next fixture")
        service.update(self.paths.manifest, plugins=False)
        self.assertTrue((runtime / "apps/nvim/next.lua").exists())
        (runtime / "local-work.txt").write_text("preserve")
        with self.assertRaisesRegex(RuntimeError, "local changes"):
            service.update(self.paths.manifest, plugins=False)
        self.assertEqual((runtime / "local-work.txt").read_text(), "preserve")

    def test_failed_plugin_setup_cleans_staging_and_can_retry(self):
        remote = self.fixture()
        with patch("installer.service.setup_plugins", side_effect=RuntimeError("fixture failure")):
            with self.assertRaisesRegex(RuntimeError, "fixture failure"):
                service.install(self.paths, ROOT, repository=str(remote))
        self.assertFalse(self.paths.command.exists())
        self.assertFalse(self.paths.manifest.exists())
        self.assertFalse((self.paths.data / "runtime").exists())
        self.assertEqual(list(self.paths.data.glob(".forge-install-*")), [])
        service.install(self.paths, ROOT, repository=str(remote), plugins=False)
        self.assertTrue(self.paths.command.exists())

    def test_update_failure_restores_previous_source(self):
        remote = self.fixture()
        record = service.install(self.paths, ROOT, repository=str(remote), plugins=False)
        runtime = Path(record["root"])
        previous = source.git(runtime, "rev-parse", "HEAD")
        (remote / "apps/nvim/next.lua").write_text("return true\n")
        self.commit(remote, "feat: add next fixture")
        with patch("installer.service.setup_plugins", side_effect=RuntimeError("fixture failure")):
            with self.assertRaisesRegex(RuntimeError, "restored"):
                service.update(self.paths.manifest)
        self.assertEqual(source.git(runtime, "rev-parse", "HEAD"), previous)

    def test_development_install_never_updates_working_tree(self):
        self.install()
        with self.assertRaisesRegex(RuntimeError, "Local development"):
            service.update(self.paths.manifest, plugins=False)


if __name__ == "__main__":
    unittest.main()
