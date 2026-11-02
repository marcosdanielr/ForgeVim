"""Own command installation while preserving all user config and editor state."""
import hashlib
import os
import shlex
import signal
import shutil
import subprocess
import tempfile
from pathlib import Path

from . import dependencies, source
from .paths import InstallPaths, load, save

MARKER = "# Managed by the Forge.nvim installer (v1)."
TEMPLATE = "-- Personal overrides. Defaults remain in the distribution.\nreturn {\n  -- leader = \" \",\n  -- nerd_fonts = false,\n}\n"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def wrapper(root, manifest):
    return "#!/bin/sh\n" + MARKER + "\nexport FORGE_INSTALL_MANIFEST=" + shlex.quote(str(manifest)) + "\nexec " + shlex.quote(str(root / "bin/forge")) + ' "$@"\n'


def write_command(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    with temporary.open("x") as stream:
        stream.write(text)
    temporary.chmod(0o755)
    try:
        os.link(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def setup_plugins(root):
    environment = dict(os.environ)
    environment.pop("FORGE_OFFLINE", None)
    environment["FORGE_INSTALL_PLUGIN_SCRIPT"] = str(root / "scripts/installer/plugins.lua")
    log = InstallPaths.defaults().state / "forge/install.log"
    log.parent.mkdir(parents=True, exist_ok=True)
    print("Plugin setup log: " + str(log), flush=True)
    with log.open("w") as output:
        log.chmod(0o600)
        process = subprocess.Popen([str(root / "bin/forge"), "--headless", "-c",
            "lua dofile(vim.env.FORGE_INSTALL_PLUGIN_SCRIPT)"], env=environment,
            stdin=subprocess.DEVNULL, stdout=output, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            for _ in range(30):
                try:
                    status = process.wait(timeout=20)
                    if status:
                        raise RuntimeError("Plugin setup failed. Read " + str(log) + " and retry.")
                    print("Selected plugins ready.", flush=True)
                    return
                except subprocess.TimeoutExpired:
                    print("Still preparing selected plugins...", flush=True)
            raise RuntimeError("Plugin setup timed out. Read " + str(log) + " and retry.")
        finally:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait()


def install(paths, checkout, local=False, repository=source.REPOSITORY, revision="main", plugins=True):
    dependencies.check()
    if paths.manifest.exists():
        existing = load(paths.manifest)
        command = Path(existing["command"])
        if command.exists() or command.is_symlink():
            if command.is_symlink() or digest(command) != existing["command_sha256"]:
                raise RuntimeError("The installed launcher changed. Restore it or use a different prefix; nothing was overwritten.")
        if command != paths.command or bool(existing["local"]) != local or (local and Path(existing["root"]) != checkout):
            raise RuntimeError("A different installation already uses this profile. Keep it or uninstall its launcher first.")
        if not local and (source.canonical_repository(existing.get("repository")) != source.canonical_repository(repository) or existing["revision"] != revision):
            raise RuntimeError("A different repository or revision is already installed; existing source was preserved.")
        if not (Path(existing["root"]) / "apps/nvim/init.lua").is_file():
            raise RuntimeError("Installed source is missing; restore its checkout before retrying.")
        if not command.exists():
            text = wrapper(Path(existing["root"]), paths.manifest)
            if hashlib.sha256(text.encode()).hexdigest() != existing["command_sha256"]:
                raise RuntimeError("Cannot recover a launcher from a different installer version")
            write_command(command, text)
        if existing.get("active") is False:
            existing["active"] = True
            save(paths.manifest, existing)
        print("Already installed. Use forge --update for managed updates.")
        return existing
    if paths.command.exists() or paths.command.is_symlink():
        raise RuntimeError("Refusing to overwrite an existing command: " + str(paths.command))
    root = checkout
    staging = None
    destination = paths.data / "runtime"
    if not local:
        if destination.exists() or destination.is_symlink():
            raise RuntimeError("Runtime directory already exists; preserved: " + str(destination))
        destination.parent.mkdir(parents=True, exist_ok=True)
        staging = Path(tempfile.mkdtemp(prefix=".forge-install-", dir=destination.parent))
        root = staging / "runtime"
    try:
        if staging:
            source.clone(repository, root, revision)
        if not (root / "apps/nvim/init.lua").is_file() or not os.access(root / "bin/forge", os.X_OK):
            raise RuntimeError("The selected source is not a ForgeVim checkout")
        personal = paths.config / "lua/user.lua"
        personal.parent.mkdir(parents=True, exist_ok=True)
        try:
            with personal.open("x") as stream:
                stream.write(TEMPLATE)
        except FileExistsError:
            pass
        if plugins:
            print("Installing selected plugins from the lockfile...", flush=True)
            setup_plugins(root)
        if staging:
            root.rename(destination)
            root = destination
    finally:
        if staging:
            shutil.rmtree(staging)
    text = wrapper(root, paths.manifest)
    record = {"product": "forge.nvim", "version": 1, "active": True, "root": str(root), "command": str(paths.command),
        "local": local, "repository": repository, "revision": revision, "command_sha256": hashlib.sha256(text.encode()).hexdigest()}
    save(paths.manifest, record)
    write_command(paths.command, text)
    print("Installed: " + str(paths.command))
    print("Run: forge .")
    if str(paths.command.parent) not in os.environ.get("PATH", "").split(os.pathsep):
        print("Add to your shell profile: export PATH=" + shlex.quote(str(paths.command.parent)) + ':"$PATH"')
    print("Select a Nerd Font in your terminal. Existing Neovim config and language profiles are preserved.")
    return record


def uninstall(manifest):
    record = load(manifest)
    command = Path(record["command"])
    if command.is_symlink() or (command.exists() and digest(command) != record["command_sha256"]):
        raise RuntimeError("Launcher changed; refusing to delete it")
    if command.exists() or command.is_symlink():
        command.unlink()
    record["active"] = False
    save(manifest, record)
    print("Launcher removed. Source, preferences, plugins, logs and worktrees were preserved.")


def update(manifest, plugins=True):
    record = load(manifest)
    if record["local"]:
        raise RuntimeError("Local development install: update your checkout with Git. The installer never changes your working tree.")
    root = Path(record["root"])
    previous, target = source.update(root, record["revision"])
    try:
        if plugins:
            setup_plugins(root)
    except (RuntimeError, subprocess.SubprocessError):
        source.git(root, "checkout", "--detach", previous)
        raise RuntimeError("Plugin verification failed; distribution source restored to its previous commit")
    print("Updated source: " + previous[:8] + " -> " + target[:8])
    print("Personal plugin locks remain authoritative; use :Lazy for intentional dependency updates.")
