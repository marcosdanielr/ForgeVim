"""Check required tools without installing system packages or changing PATH."""
import os
import shutil
import subprocess
import sys


def check():
    if sys.version_info < (3, 9):
        raise RuntimeError("Python 3.9 or newer is required")
    missing = [tool for tool in ("git", "rg") if not shutil.which(tool)]
    nvim = os.environ.get("FORGE_NVIM", "nvim")
    if not shutil.which(nvim):
        missing.append("Neovim 0.11+")
    if missing:
        raise RuntimeError("Missing tools: " + ", ".join(missing) + ". Install them and retry. On macOS: brew install neovim git ripgrep python")
    result = subprocess.run([nvim, "--headless", "-u", "NONE", "-i", "NONE", "-c",
        "if !has('nvim-0.11') | cquit 1 | endif", "-c", "qa!"],
        stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=15)
    if result.returncode:
        raise RuntimeError("Neovim 0.11 or newer is required")
    print("Required tools ready: Neovim 0.11+, Git, ripgrep, Python 3.9+", flush=True)
    print("Node.js, language SDKs and provider CLIs are optional; enable them when needed.")
