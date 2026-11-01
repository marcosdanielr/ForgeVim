#!/usr/bin/env python3
"""Optional real Pyright, StyLua, and debugpy verification in a temporary project.

Install those three tools on PATH and lazy plugins in the current XDG environment.
This script does not install dependencies, authenticate accounts, or call models.
"""
import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument("--nvim", default="nvim")
parser.add_argument("--python", default=sys.executable)
arguments = parser.parse_args()
with tempfile.TemporaryDirectory(prefix="forge-runtime-") as temporary:
    project = Path(temporary)
    (project / "fixture.py").write_text("message: str = 1\nprint(message)\n")
    (project / "pyrightconfig.json").write_text('{"typeCheckingMode":"basic"}')
    (project / "fixture.lua").write_text("local answer={value=42}\nreturn answer\n")
    environment = dict(os.environ, FORGE_NVIM=arguments.nvim,
        FORGE_RUNTIME_SCRIPT=str(root / "tests/nvim/runtime.lua"),
        FORGE_RUNTIME_PROJECT=str(project), FORGE_RUNTIME_PYTHON=arguments.python)
    environment.pop("FORGE_OFFLINE", None)
    subprocess.run([str(root / "bin/forge"), "--headless", "-c",
                    "lua dofile(vim.env.FORGE_RUNTIME_SCRIPT)"], cwd=project,
                   env=environment, check=True, timeout=65)
