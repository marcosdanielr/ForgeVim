#!/usr/bin/env python3
"""Verify restart-safe Leader changes preserve symbolic action mappings and unknown preferences."""
import argparse
import json
import os
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument("--nvim", default="nvim")
arguments = parser.parse_args()
with tempfile.TemporaryDirectory(prefix="forge-leader-") as temporary:
    directory = Path(temporary)
    environment = dict(os.environ, FORGE_OFFLINE="1", FORGE_NVIM=arguments.nvim,
        FORGE_LEADER_SCRIPT=str(root / "tests/nvim/leader.lua"))
    for kind in ("CONFIG", "DATA", "STATE", "CACHE"):
        environment["XDG_" + kind + "_HOME"] = str(directory / kind.lower())
    state = directory / "state/forge.nvim/forge/preferences.json"
    state.parent.mkdir(parents=True)
    state.write_text(json.dumps({"plugins": {}, "future_marker": "preserved", "keymaps": {"ForgeFiles": ["<leader>fz"]}}))
    def launch(expected, next_key=None):
        run_environment = dict(environment, FORGE_EXPECTED_LEADER=expected)
        if next_key is not None:
            run_environment["FORGE_NEXT_LEADER"] = next_key
        subprocess.run([str(root / "bin/forge"), "--headless", "-c",
            "lua dofile(vim.env.FORGE_LEADER_SCRIPT)"], env=run_environment, check=True, timeout=15)
    launch(" ", ",")
    launch(",", " ")
    launch(" ")
    preferences = json.loads(state.read_text())
    preferences.pop("leader")
    state.write_text(json.dumps(preferences))
    user = directory / "config/forge.nvim/lua/user.lua"
    user.parent.mkdir(parents=True)
    user.write_text('return { leader = ";", localleader = "$" }\n')
    launch(";")
print("Default, saved, restored and user-configured Leader passed")
