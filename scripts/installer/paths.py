"""Resolve XDG locations and write installation metadata atomically."""
import contextlib
import fcntl
import json
import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class InstallPaths:
    prefix: Path
    data: Path
    config: Path
    state: Path

    @classmethod
    def defaults(cls, prefix=None):
        home = Path.home()
        return cls(Path(prefix or (os.environ.get("INSTALL_PREFIX") or home / ".local")).expanduser().resolve(),
            Path((os.environ.get("XDG_DATA_HOME") or home / ".local/share")).resolve() / "forge.nvim",
            Path((os.environ.get("XDG_CONFIG_HOME") or home / ".config")).resolve() / "forge.nvim",
            Path((os.environ.get("XDG_STATE_HOME") or home / ".local/state")).resolve() / "forge.nvim")

    @property
    def command(self):
        return self.prefix / "bin/forge"

    @property
    def manifest(self):
        return self.state / "forge/install.json"


def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    temporary.replace(path)


def load(path):
    data = json.loads(path.read_text())
    if data.get("product") != "forge.nvim" or data.get("version") != 1:
        raise RuntimeError("Unrecognized installation record: " + str(path))
    for field in ("root", "command", "revision", "command_sha256"):
        if not isinstance(data.get(field), str):
            raise RuntimeError("Incomplete installation record: " + str(path))
    if not isinstance(data.get("local"), bool):
        raise RuntimeError("Invalid installation mode: " + str(path))
    return data


@contextlib.contextmanager
def lock(state):
    state.mkdir(parents=True, exist_ok=True)
    with (state / "install.lock").open("a") as stream:
        try:
            fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError("Another installation operation is already running")
        try:
            yield
        finally:
            fcntl.flock(stream, fcntl.LOCK_UN)
