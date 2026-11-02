#!/usr/bin/env python3
"""macOS resource probe for headless Neovim panels and local PTY-agent fixtures."""
import argparse
import json
import os
import platform
import sys
import tempfile
import subprocess
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "packages/agent-core"))
from forge_agents import git
from forge_agents.service import AgentService


def scenario(directory, name, arguments):
    from benchmarks.processes import sample
    project = directory / name / "project"
    project.mkdir(parents=True)
    git.run(project, "init", "-b", "main")
    git.run(project, "config", "user.email", "benchmark@example.com")
    git.run(project, "config", "user.name", "Forge Benchmark")
    (project / "main.lua").write_text("return true\n")
    git.run(project, "add", ".")
    git.run(project, "commit", "-m", "chore: add local benchmark fixture")
    tasks = []
    if name == "agents":
        service = AgentService(project)
        for index in range(4):
            tasks.append(service.create_chat("Local benchmark fixture " + str(index + 1), "command",
                [sys.executable, "-c", "import time; print('Local fixture, no model',flush=True); time.sleep(120)"]))
    task_file = directory / name / "tasks.json"
    task_file.write_text(json.dumps(tasks))
    ready = directory / name / "ready"
    environment = dict(os.environ, FORGE_NVIM=arguments.nvim,
        XDG_CONFIG_HOME=str(directory / name / "config"), XDG_STATE_HOME=str(directory / name / "state"),
        XDG_DATA_HOME=str(arguments.data_home.resolve()), XDG_CACHE_HOME=str(directory / "cache"),
        FORGE_RESOURCE_CASE=name, FORGE_RESOURCE_TASKS=str(task_file), FORGE_RESOURCE_READY=str(ready),
        FORGE_RESOURCE_LIFETIME=str(arguments.seconds + 7),
        FORGE_RESOURCE_SCRIPT=str(ROOT / "tests/nvim/benchmark.lua"), TERM="xterm-256color")
    environment.pop("FORGE_OFFLINE", None)
    log = directory / name / "nvim.log"
    with log.open("wb") as output:
        process = subprocess.Popen([str(ROOT / "bin/forge"), "--headless", "main.lua", "-c",
            "lua dofile(vim.env.FORGE_RESOURCE_SCRIPT)"], cwd=project, env=environment,
            stdin=subprocess.DEVNULL, stdout=output, stderr=output)
        try:
            deadline = time.monotonic() + 30
            while not ready.exists():
                if process.poll() is not None or time.monotonic() > deadline:
                    raise RuntimeError("Benchmark did not become ready: " + name + "\n" + log.read_text(errors="replace")[-4000:])
                time.sleep(0.05)
            time.sleep(2)
            result = sample(process.pid, arguments.seconds)
            result["scenario"] = name
            process.wait(timeout=10)
            if process.returncode != 0:
                raise RuntimeError(log.read_text(errors="replace")[-4000:])
            return result
        finally:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=3)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--nvim", default="nvim")
    parser.add_argument("--data-home", type=Path, required=True, help="XDG data root with Forge plugins already installed")
    parser.add_argument("--seconds", type=int, default=10)
    parser.add_argument("--scenario", choices=["all", "editor", "terminals", "agents"], default="all")
    arguments = parser.parse_args()
    if platform.system() != "Darwin":
        parser.error("This ps CPU accounting probe currently supports macOS only")
    if not (arguments.data_home / "forge.nvim/lazy/lazy.nvim").is_dir():
        parser.error("data-home must contain Forge plugins already installed")
    if not 4 <= arguments.seconds <= 60:
        parser.error("seconds must be between 4 and 60")
    with tempfile.TemporaryDirectory(prefix="forge resource fixture ") as temporary:
        names = ("editor", "terminals", "agents") if arguments.scenario == "all" else (arguments.scenario,)
        results = [scenario(Path(temporary).resolve(), name, arguments) for name in names]
    print(json.dumps({"system": platform.system(), "architecture": platform.machine(), "mode": "headless_panels_and_real_child_ptys", "logical_cpus": os.cpu_count(), "results": results,
        "limits": ["CPU uses macOS process accounting converted with the Mach timebase, percent of one core including reaped child CPU.",
                   "RSS can double-count shared pages. Footprint is macOS charged process memory, not universal unique RAM; peaks are sampled.",
                   "Agents are four real local Python sleep fixtures, not authenticated model CLIs.",
                   "Terminal-app/UI rendering, language profiles, LSPs, debug adapters, and inference are excluded."]}, indent=2))


if __name__ == "__main__":
    main()
