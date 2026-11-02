#!/usr/bin/env python3
"""Resolve a real temporary Git conflict through Diffview without touching user repos."""
import os
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix="forge-merge-") as temporary:
    project = Path(temporary)
    def git(*arguments, check=True):
        return subprocess.run(["git", "-C", str(project), *arguments], check=check,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    git("init", "-b", "main")
    git("config", "user.email", "test@example.com")
    git("config", "user.name", "Forge Merge Test")
    sample = project / "sample.txt"
    sample.write_text("base\n")
    git("add", ".")
    git("commit", "-m", "chore: add base")
    git("checkout", "-b", "incoming")
    sample.write_text("theirs\n")
    git("commit", "-am", "feat: add theirs")
    git("checkout", "main")
    sample.write_text("ours\n")
    git("commit", "-am", "feat: add ours")
    assert git("merge", "incoming", check=False).returncode != 0
    environment = dict(os.environ, FORGE_GIT_PROJECT=str(project),
                       FORGE_GIT_SCRIPT=str(root / "tests/nvim/git.lua"))
    environment.pop("FORGE_OFFLINE", None)
    subprocess.run([str(root / "bin/forge"), "--headless", "-c",
                    "lua dofile(vim.env.FORGE_GIT_SCRIPT)"], cwd=project,
                   env=environment, check=True, timeout=30)
    assert sample.read_text() == "ours\n"
    assert git("diff", "--name-only", "--diff-filter=U").stdout.strip() == b"sample.txt"
    # The user still must stage the resolved file; the editor never stages implicitly.
