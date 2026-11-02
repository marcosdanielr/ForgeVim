#!/usr/bin/env python3
"""Verify the welcome dashboard only starts on an empty interactive launch."""
import argparse
import errno
import fcntl
import os
import pty
import select
import signal
import struct
import tempfile
import termios
import time
from pathlib import Path

root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument("--nvim", default="nvim")
arguments = parser.parse_args()


def run(mode: str, project: Path, result: Path, environment: dict[str, str]) -> None:
    pid, master = pty.fork()
    if pid == 0:
        fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 38, 120, 0, 0))
        os.chdir(project.parent)
        command = [str(root / "bin/forge")]
        if mode == "project":
            command.append(str(project))
        command.extend(["-c", "lua dofile(vim.env.FORGE_WORKSPACE_SCRIPT)"])
        os.execve(command[0], command, environment)
    transcript = bytearray()
    status = None
    deadline = time.monotonic() + 20
    try:
        while time.monotonic() < deadline:
            if select.select([master], [], [], 0.05)[0]:
                try:
                    transcript.extend(os.read(master, 65536))
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
            finished, status_value = os.waitpid(pid, os.WNOHANG)
            if finished:
                status = status_value
                break
        if status is None:
            raise RuntimeError(f"{mode} launch timed out")
        if os.waitstatus_to_exitcode(status) or not result.exists() or result.read_text().strip() != "passed":
            raise RuntimeError(transcript.decode(errors="replace")[-2000:])
    finally:
        if status is None:
            os.kill(pid, signal.SIGTERM)
            os.waitpid(pid, 0)
        os.close(master)


with tempfile.TemporaryDirectory(prefix="forge-workspace-startup-") as temporary:
    directory = Path(temporary)
    project = directory / "project"
    project.mkdir()
    environment = dict(
        os.environ,
        FORGE_OFFLINE="1",
        FORGE_NVIM=arguments.nvim,
        FORGE_WORKSPACE_SCRIPT=str(root / "tests/nvim/workspace-startup.lua"),
        XDG_CONFIG_HOME=str(directory / "config"),
        XDG_STATE_HOME=str(directory / "state"),
        XDG_DATA_HOME=str(directory / "data"),
        XDG_CACHE_HOME=str(directory / "cache"),
        TERM="xterm-256color",
    )
    for mode in ("empty", "project"):
        result = directory / f"{mode}.result"
        environment["FORGE_WORKSPACE_RESULT"] = str(result)
        environment["FORGE_WORKSPACE_MODE"] = str(project) if mode == "project" else mode
        run(mode, project, result, environment)

print("Interactive dashboard is fullscreen only without a project path")
