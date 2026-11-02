#!/usr/bin/env python3
"""Verify diagnostic presentation with an installed Dart language server, without plugins."""
import argparse
import os
import signal
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument("--dart", default="dart")
parser.add_argument("--nvim", default="nvim")
arguments = parser.parse_args()
with tempfile.TemporaryDirectory(prefix="forge-dart-") as temporary:
    project = Path(temporary)
    (project / "main.dart").write_text("void main() {\n  sdadsa\n}\n")
    (project / "pubspec.yaml").write_text("name: forge_diagnostic_fixture\nenvironment:\n  sdk: '>=3.0.0 <4.0.0'\n")
    environment = dict(os.environ, FORGE_OFFLINE="1", FORGE_NVIM=arguments.nvim,
        FORGE_DART_PROJECT=str(project), FORGE_DART_BIN=arguments.dart,
        FORGE_DART_SCRIPT=str(root / "tests/nvim/dart.lua"),
        XDG_CONFIG_HOME=str(project / "config"), XDG_STATE_HOME=str(project / "state"),
        XDG_DATA_HOME=str(project / "data"), XDG_CACHE_HOME=str(project / "cache"),
        DART_SUPPRESS_ANALYTICS="true")
    process = subprocess.Popen([str(root / "bin/forge"), "--headless", "-c",
        "lua dofile(vim.env.FORGE_DART_SCRIPT)"], cwd=project, env=environment, start_new_session=True)
    try:
        status = process.wait(timeout=45)
        if status:
            raise subprocess.CalledProcessError(status, process.args)
    finally:
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
