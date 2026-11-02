#!/usr/bin/env python3
"""Measure warm headless process startup; not typing latency or full UI readiness."""
import argparse
import json
import os
import platform
import statistics
import subprocess
import time
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--nvim", default="nvim")
    parser.add_argument("--samples", type=int, default=7)
    arguments = parser.parse_args()
    if not 1 <= arguments.samples <= 30:
        parser.error("samples must be between 1 and 30")
    root = Path(__file__).resolve().parent.parent
    environment = dict(os.environ, FORGE_NVIM=arguments.nvim)
    command = [str(root / "bin/forge"), "--headless", "+qa"]
    subprocess.run(command, env=environment, cwd=root, check=True, capture_output=True, timeout=60)
    samples = []
    for _ in range(arguments.samples):
        start = time.perf_counter()
        subprocess.run(command, env=environment, cwd=root, check=True, capture_output=True, timeout=30)
        samples.append(round((time.perf_counter() - start) * 1000, 2))
    version = subprocess.check_output([arguments.nvim, "--version"], text=True).splitlines()[0]
    print(json.dumps({
        "metric": "warm_headless_process_ms", "neovim": version,
        "system": platform.system(), "architecture": platform.machine(),
        "samples": samples, "median": round(statistics.median(samples), 2),
        "limits": "Includes launcher and exit. Excludes interactive panels, LSPs, debug adapters, and model calls.",
    }, indent=2))


if __name__ == "__main__":
    main()
