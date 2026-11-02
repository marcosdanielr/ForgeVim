"""Prepare managed sources and apply only clean, fast-forward updates."""
import shutil
import subprocess

REPOSITORY = "https://github.com/marcosdanielr/ForgeVim.git"
SPARSE_PATHS = ("bin", "apps/nvim", "packages/agent-core", "packages/protocol", "scripts")


def canonical_repository(repository):
    """Keep installations created before the ForgeVim repository rename reusable."""
    if isinstance(repository, str) and repository.lower() in {
        "https://github.com/marcosdanielr/forge.nvim.git", REPOSITORY.lower()
    }:
        return REPOSITORY
    return repository


def git(root, *arguments):
    result = subprocess.run(["git", "-C", str(root), *arguments], text=True, capture_output=True, timeout=180)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "Git command failed")
    return result.stdout.strip()


def validate_revision(revision):
    if not revision or revision.startswith("-") or "\n" in revision or "\r" in revision:
        raise RuntimeError("Choose a valid Git branch, tag or commit")


def github_login():
    return bool(shutil.which("gh")) and subprocess.run(["gh", "auth", "status", "--hostname", "github.com"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=15).returncode == 0


def clone(repository, destination, revision):
    validate_revision(revision)
    repository = canonical_repository(repository)
    if repository == REPOSITORY and github_login():
        command = ["gh", "repo", "clone", "marcosdanielr/ForgeVim", str(destination), "--", "--filter=blob:none", "--sparse"]
    else:
        command = ["git", "clone", "--filter=blob:none", "--sparse", "--", repository, str(destination)]
    subprocess.run(command, check=True, timeout=240)
    git(destination, "sparse-checkout", "set", *SPARSE_PATHS)
    git(destination, "fetch", "origin", revision)
    commit = git(destination, "rev-parse", "FETCH_HEAD")
    git(destination, "checkout", "--detach", commit)
    return commit


def update(root, revision):
    validate_revision(revision)
    if git(root, "status", "--porcelain", "--untracked-files=all"):
        raise RuntimeError("Installation source has local changes. Commit or stash them before updating.")
    previous = git(root, "rev-parse", "HEAD")
    git(root, "fetch", "origin", revision)
    target = git(root, "rev-parse", "FETCH_HEAD")
    try:
        git(root, "merge-base", "--is-ancestor", previous, target)
    except RuntimeError:
        raise RuntimeError("Update would replace local history. Existing source was preserved.")
    git(root, "checkout", "--detach", target)
    return previous, target
