#!/usr/bin/env python3
"""Exercise actual legacy terminal bytes: Ctrl-backtick/NUL and Alt-Enter."""
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

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument("--nvim", default="nvim")
arguments = parser.parse_args()
with tempfile.TemporaryDirectory(prefix="forge-terminal-input-") as temporary:
    project = Path(temporary)
    config = project / "config/forge.nvim/lua/user.lua"
    config.parent.mkdir(parents=True)
    config.write_text("return { workspace = false, startup_panels = { files = false, agents = false, navigation = false, chat = false, output = false } }\n")
    result = project / "result"
    environment = dict(os.environ, FORGE_OFFLINE="1", FORGE_NVIM=arguments.nvim,
        FORGE_INPUT_RESULT=str(result), FORGE_INPUT_SCRIPT=str(root / "tests/nvim/terminal-input.lua"),
        XDG_CONFIG_HOME=str(project / "config"), XDG_STATE_HOME=str(project / "state"),
        XDG_DATA_HOME=str(project / "data"), XDG_CACHE_HOME=str(project / "cache"), TERM="xterm-256color")
    pid, master = pty.fork()
    if pid == 0:
        fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 38, 120, 0, 0))
        os.chdir(project)
        os.execve(root / "bin/forge", [str(root / "bin/forge"), "-c", "lua dofile(vim.env.FORGE_INPUT_SCRIPT)"], environment)
    inputs = {"ready": b"\x00", "opened": b"\x1b\r", "multiple": b" pa", "agents_shown": b" pa", "agents_hidden": b"\x00", "hidden": b"\x00"}
    sent, transcript, status = set(), bytearray(), None
    deadline = time.monotonic() + 20
    try:
        while time.monotonic() < deadline:
            if select.select([master], [], [], 0.05)[0]:
                try:
                    transcript.extend(os.read(master, 65536))
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
            value = result.read_text().strip() if result.exists() else ""
            if value in inputs and value not in sent:
                os.write(master, inputs[value])
                sent.add(value)
            finished, status_value = os.waitpid(pid, os.WNOHANG)
            if finished:
                status = status_value
                break
        if status is None:
            raise RuntimeError("Terminal input timed out at " + (result.read_text() if result.exists() else "startup"))
        if os.waitstatus_to_exitcode(status) or result.read_text().strip() != "passed":
            raise RuntimeError(result.read_text() + "\n" + transcript.decode(errors="replace")[-2000:])
    finally:
        if status is None:
            os.kill(pid, signal.SIGTERM)
            os.waitpid(pid, 0)
        os.close(master)
print("Real TUI input, multiple live shells and hide/restore passed")
