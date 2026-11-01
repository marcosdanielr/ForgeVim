#!/usr/bin/env python3
"""Verify already-installed plugin APIs without launching models or debuggers."""
import os
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parent.parent
environment = dict(os.environ, FORGE_PLUGIN_SMOKE=str(root / "tests/nvim/plugins.lua"))
environment.pop("FORGE_OFFLINE", None)
subprocess.run([str(root / "bin/forge"), "--headless", "-c",
                "lua dofile(vim.env.FORGE_PLUGIN_SMOKE)"], env=environment, check=True, timeout=45)
