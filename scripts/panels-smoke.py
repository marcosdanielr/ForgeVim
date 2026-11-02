#!/usr/bin/env python3
"""Verify native panels, live terminals, search flags, and isolated PTY chat review."""
import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "packages/agent-core"))
from forge_agents import git
from forge_agents.service import AgentService


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--nvim", default="nvim")
    arguments = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="forge panels ") as temporary:
        directory = Path(temporary)
        project = directory / "project"
        project.mkdir()
        git.run(project, "init", "-b", "main")
        git.run(project, "config", "user.email", "panels@example.com")
        git.run(project, "config", "user.name", "Forge Panels")
        (project / "sample.txt").write_text("alpha Alpha alphabet alpha.one\nbeta alphaone\n")
        (project / "second.txt").write_text("second\n")
        git.run(project, "add", ".")
        git.run(project, "commit", "-m", "chore: add fixture")
        service = AgentService(project)
        task = service.create_chat("Local PTY chat fixture", "command", [sys.executable, "-c",
            "import time; from pathlib import Path; print('CHAT_READY',flush=True); "
            "time.sleep(2); Path('chat.txt').write_text('reviewed chat\\n')"])
        task_file = directory / "chat.json"
        task_file.write_text(json.dumps(task))
        environment = dict(os.environ, FORGE_OFFLINE="1", FORGE_NVIM=arguments.nvim,
            FORGE_PANEL_SCRIPT=str(ROOT / "tests/nvim/panels.lua"),
            FORGE_PANEL_ROOT=str(project), FORGE_PANEL_TASK=str(task_file), PYTHONDONTWRITEBYTECODE="1")
        for kind in ("CONFIG", "DATA", "STATE", "CACHE"):
            environment["XDG_" + kind + "_HOME"] = str(directory / kind.lower())
        subprocess.run([str(ROOT / "bin/forge"), "--headless", "-c",
                        "lua dofile(vim.env.FORGE_PANEL_SCRIPT)"], env=environment, cwd=project,
                       check=True, timeout=45)
        assert (project / "chat.txt").read_text() == "reviewed chat\n"
        assert service.store.get(task["id"])["status"] == "accepted"
        print("Panels, persistent terminals, search semantics, and isolated CLI chat review passed")


if __name__ == "__main__":
    main()
