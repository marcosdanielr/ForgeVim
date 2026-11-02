#!/usr/bin/env python3
"""Exercise the replacement dialog through actual TUI keyboard and mouse input."""
import argparse
import errno
import fcntl
import json
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
with tempfile.TemporaryDirectory(prefix="forge-replace-input-") as temporary:
    project = Path(temporary)
    config = project / "config/forge.nvim/lua/user.lua"
    config.parent.mkdir(parents=True)
    config.write_text("return { workspace = false, startup_panels = { files = false, agents = false, navigation = false, chat = false, output = false } }\n")
    result = project / "result"
    environment = dict(os.environ, FORGE_OFFLINE="1", FORGE_NVIM=arguments.nvim,
        FORGE_INPUT_RESULT=str(result), FORGE_INPUT_SCRIPT=str(root / "tests/nvim/replace-input.lua"),
        XDG_CONFIG_HOME=str(project / "config"), XDG_STATE_HOME=str(project / "state"),
        XDG_DATA_HOME=str(project / "data"), XDG_CACHE_HOME=str(project / "cache"), TERM="xterm-256color")
    pid, master = pty.fork()
    if pid == 0:
        fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 38, 120, 0, 0))
        os.chdir(project)
        os.execve(root / "bin/forge", [str(root / "bin/forge"), "-c", "lua dofile(vim.env.FORGE_INPUT_SCRIPT)"], environment)
    inputs = {"open_find": b"\x06", "find": b"needle\t", "replacement": b"done\t",
              "option_case": b" \t", "option_word": b" \t", "option_regex": b" \t", "option_scope": b" \t",
              "next_result": b"\r", "previous_result": b"\t\r", "next_button": b"\t\r",
              "previous_button": b"\x1b[Z\r", "replace_first": b"\x1b[Zy",
              "one": b"y", "all": b"\x01", "cancel": b"\r", "all_again": b"\x01", "confirm": b"h\r"}
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
            raw = result.read_text().strip() if result.exists() else ""
            try:
                event = json.loads(raw) if raw.startswith("{") else {"phase": raw}
            except json.JSONDecodeError:
                continue
            value = event["phase"]
            if value and value not in sent:
                if value in inputs:
                    os.write(master, inputs[value])
                elif value.startswith("mouse_"):
                    point = f"{event['column']};{event['row']}".encode()
                    os.write(master, b"\x1b[<0;" + point + b"M\x1b[<0;" + point + b"m")
                elif value == "resize":
                    fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack("HHHH", 34, 80, 0, 0))
                    os.kill(pid, signal.SIGWINCH)
                sent.add(value)
            finished, status_value = os.waitpid(pid, os.WNOHANG)
            if finished:
                status = status_value
                break
        if status is None:
            raise RuntimeError("Replace input timed out at " + (result.read_text() if result.exists() else "startup"))
        if os.waitstatus_to_exitcode(status) or result.read_text().strip() != "passed":
            raise RuntimeError(result.read_text() + "\n" + transcript.decode(errors="replace")[-2000:])
    finally:
        if status is None:
            os.kill(pid, signal.SIGKILL)
            os.waitpid(pid, 0)
        os.close(master)
print("Real find/replace: Ctrl F, Tab/Space options, next/previous, repeated replace, all/cancel, mouse and resize passed")
