"""Git operations. Commands use argument arrays and preserve binary patches."""
import subprocess
from pathlib import Path

from .errors import ForgeError


def run(root, *arguments, input=None):
    result = subprocess.run(
        ["git", "-C", str(root), *arguments], input=input,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    if result.returncode:
        raise ForgeError(result.stderr.decode("utf-8", "replace").strip())
    return result.stdout


def repository(path):
    root = Path(run(path, "rev-parse", "--show-toplevel").decode().strip()).resolve()
    return root


def head(root):
    return run(root, "rev-parse", "HEAD").decode().strip()


def ensure_clean(root):
    if run(root, "status", "--porcelain", "--untracked-files=normal").strip():
        raise ForgeError("Commit or stash source changes before starting or accepting a task.")


def prepare_state(root):
    # Local exclusion avoids requiring every target project to change .gitignore.
    exclude = Path(run(root, "rev-parse", "--git-path", "info/exclude").decode().strip())
    if not exclude.is_absolute():
        exclude = root / exclude
    exclude.parent.mkdir(parents=True, exist_ok=True)
    content = exclude.read_text() if exclude.exists() else ""
    if "/.forge/" not in content.splitlines():
        with exclude.open("a") as stream:
            stream.write("\n/.forge/\n")


def create_worktree(root, path, branch, base):
    run(root, "worktree", "add", "-b", branch, str(path), base)


def snapshot(task):
    worktree = Path(task["worktree"])
    # Intent-to-add includes untracked files without committing agent output.
    run(worktree, "add", "--intent-to-add", "--all", "--", ".")
    paths = run(worktree, "diff", "--no-renames", "--name-only", "-z", task["base"], "--", ".")
    if any(path.split(b"/")[0] in (b".git", b".forge") for path in paths.split(b"\0") if path):
        raise ForgeError("Agent patch contains reserved Forge or Git state paths.")
    return run(worktree, "diff", "--binary", "--no-ext-diff", "--no-textconv",
               task["base"], "--", ".")


def apply(root, patch):
    run(root, "apply", "--check", "--binary", "-", input=patch)
    run(root, "apply", "--binary", "-", input=patch)
