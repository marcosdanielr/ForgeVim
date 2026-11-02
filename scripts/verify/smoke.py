#!/usr/bin/env python3
"""Exercise native editing and the async Lua-to-agent review path in isolation."""
import argparse
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "packages/agent-core"))
from forge_agents import git
from forge_agents.service import AgentService


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--nvim", default="nvim")
    arguments = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="forge-smoke-") as temporary:
        directory = Path(temporary)
        project = directory / "project"
        project.mkdir()
        git.run(project, "init", "-b", "main")
        git.run(project, "config", "user.email", "smoke@example.com")
        git.run(project, "config", "user.name", "Forge Smoke")
        (project / "sample.txt").write_text("before\n")
        git.run(project, "add", ".")
        git.run(project, "commit", "-m", "chore: add smoke fixture")
        service = AgentService(project)
        task = service.start("Change fixture", "command", [sys.executable, "-c",
            "from pathlib import Path; Path('sample.txt').write_text('after\\n')"])
        deadline = time.monotonic() + 12
        while time.monotonic() < deadline:
            if service.store.get(task["id"])["status"] == "ready":
                break
            time.sleep(0.05)
        else:
            raise RuntimeError("Smoke provider did not become ready")
        environment = dict(os.environ, FORGE_OFFLINE="1", FORGE_NVIM=arguments.nvim,
            FORGE_SMOKE_SCRIPT=str(ROOT / "tests/nvim/smoke.lua"),
            FORGE_SMOKE_ROOT=str(project), FORGE_SMOKE_TASK=task["id"], PYTHONDONTWRITEBYTECODE="1")
        for kind in ("CONFIG", "DATA", "STATE", "CACHE"):
            environment["XDG_" + kind + "_HOME"] = str(directory / kind.lower())
        subprocess.run([str(ROOT / "bin/forge"), "--headless", "-c",
                        "lua dofile(vim.env.FORGE_SMOKE_SCRIPT)"], env=environment, cwd=project,
                       check=True, timeout=30)
        assert (project / "sample.txt").read_text() == "after\n"
        assert service.store.get(task["id"])["status"] == "accepted"
        print("Native editing and async review acceptance passed")


if __name__ == "__main__":
    main()
