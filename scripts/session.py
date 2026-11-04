#!/usr/bin/env python3
"""Persistent Forge editor sessions: a headless Neovim server per name.

Closing the terminal UI detaches it; buffers, windows, and chat terminals stay
alive in the server. Standard library only; no multiplexer.
"""
import argparse
import hashlib
import os
import socket
import subprocess
import sys
import time
from pathlib import Path


def sessions_directory():
    base = os.environ.get("XDG_STATE_HOME") or str(Path.home() / ".local/state")
    return Path(base) / "forge.nvim" / "sessions"


def socket_path(name):
    # AF_UNIX paths are short on macOS, so long names fall back to a digest.
    path = sessions_directory() / (name + ".sock")
    if len(str(path)) > 100:
        path = sessions_directory() / (hashlib.sha256(name.encode()).hexdigest()[:16] + ".sock")
    if len(str(path)) > 100:
        raise SystemExit("Session directory path is too long for a socket; set XDG_STATE_HOME shorter.")
    return path


def alive(path):
    probe = socket.socket(socket.AF_UNIX)
    try:
        probe.connect(str(path))
        return True
    except OSError:
        return False
    finally:
        probe.close()


def start(name, directory, nvim, forge_root):
    path = socket_path(name)
    path.parent.mkdir(parents=True, exist_ok=True)
    if alive(path):
        return path
    path.unlink(missing_ok=True)
    environment = dict(os.environ, NVIM_APPNAME="forge.nvim", FORGE_ROOT=str(forge_root))
    subprocess.Popen(
        [nvim, "--headless", "--listen", str(path), "-u", str(forge_root / "apps/nvim/init.lua")],
        cwd=directory,
        env=environment,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        if alive(path):
            return path
        time.sleep(0.05)
    raise SystemExit("Session did not start: " + name)


def attach(name, directory, nvim, forge_root):
    path = start(name, directory, nvim, forge_root)
    os.execvp(nvim, [nvim, "--server", str(path), "--remote-ui"])


def names():
    directory = sessions_directory()
    if not directory.is_dir():
        return []
    return sorted(item.stem for item in directory.glob("*.sock") if alive(item))


def kill(name, nvim):
    path = socket_path(name)
    if not alive(path):
        path.unlink(missing_ok=True)
        raise SystemExit("No live session: " + name)
    subprocess.run(
        [nvim, "--server", str(path), "--remote-expr", "execute('qa!')"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    path.unlink(missing_ok=True)


def main(argv=None):
    parser = argparse.ArgumentParser(prog="forge session")
    commands = parser.add_subparsers(dest="command", required=True)
    for command in ("attach", "kill"):
        item = commands.add_parser(command)
        item.add_argument("name")
        if command == "attach":
            item.add_argument("--cwd", default=os.getcwd())
    commands.add_parser("list")
    arguments = parser.parse_args(argv)
    nvim = os.environ.get("FORGE_NVIM", "nvim")
    forge_root = Path(os.environ.get("FORGE_ROOT") or Path(__file__).resolve().parent.parent)
    if arguments.command == "list":
        print("\n".join(names()))
    elif arguments.command == "kill":
        kill(arguments.name, nvim)
    else:
        attach(arguments.name, arguments.cwd, nvim, forge_root)


if __name__ == "__main__":
    sys.exit(main())
