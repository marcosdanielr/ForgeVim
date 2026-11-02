"""Sample a locally owned process tree with macOS ps; never report other processes."""
import statistics
import subprocess
import time

from .darwin import read


def seconds(value):
    days, separator, remainder = value.partition("-")
    total = 0
    for field in (remainder if separator else value).split(":"):
        total = total * 60 + float(field)
    return total + (int(days) * 86400 if separator else 0)


def snapshot(root):
    # -S includes exited children, retaining CPU cost of short-lived status CLIs.
    output = subprocess.check_output(["/bin/ps", "-S", "-axo", "pid=,ppid=,rss=,time=,comm="], text=True)
    processes = {}
    for line in output.splitlines():
        fields = line.split(None, 4)
        if len(fields) == 5:
            pid, parent, rss, cpu, command = fields
            processes[int(pid)] = {"parent": int(parent), "rss_kib": int(rss), "cpu_seconds": seconds(cpu), "command": command}
    owned = {root}
    while True:
        children = {pid for pid, process in processes.items() if process["parent"] in owned}
        if children <= owned:
            break
        owned |= children
    selected = {pid: process for pid, process in processes.items() if pid in owned}
    for pid, process in selected.items():
        native = read(pid)
        if native is not None:
            process.update(native)
    groups = {"neovim": 0, "forge_python": 0, "fixture_providers": 0, "shells_and_helpers": 0}
    footprints = {group: 0 for group in groups}
    for pid, process in selected.items():
        name = process["command"].lower()
        if pid == root:
            group = "neovim"
        elif "python" in name:
            group = "forge_python" if process["parent"] == root else "fixture_providers"
        else:
            group = "shells_and_helpers"
        groups[group] += process["rss_kib"] / 1024
        footprints[group] += process.get("footprint_mib", 0)
    return {"time": time.monotonic(), "cpu": sum(item["cpu_seconds"] for item in selected.values()),
            "rss_mib": sum(item["rss_kib"] for item in selected.values()) / 1024,
            "processes": len(selected), "groups": groups, "footprints": footprints,
            "footprint_mib": sum(footprints.values())}


def sample(root, duration, on_tick=None):
    readings = [snapshot(root)]
    deadline = time.monotonic() + duration
    while time.monotonic() < deadline:
        time.sleep(0.4)
        if on_tick is not None:
            on_tick()
        readings.append(snapshot(root))
    elapsed = readings[-1]["time"] - readings[0]["time"]
    cpu = max(0, readings[-1]["cpu"] - readings[0]["cpu"])
    return {
        "window_seconds": round(elapsed, 2),
        "cpu_percent_one_core": round(100 * cpu / elapsed, 2),
        "cpu_seconds": round(cpu, 3),
        "median_rss_mib": round(statistics.median(item["rss_mib"] for item in readings), 2),
        "sampled_peak_rss_mib": round(max(item["rss_mib"] for item in readings), 2),
        "median_footprint_mib": round(statistics.median(item["footprint_mib"] for item in readings), 2),
        "sampled_peak_footprint_mib": round(max(item["footprint_mib"] for item in readings), 2),
        "median_footprint_by_role_mib": {group: round(statistics.median(item["footprints"][group] for item in readings), 2) for group in readings[0]["footprints"]},
        "median_processes": statistics.median(item["processes"] for item in readings),
        "median_rss_by_role_mib": {group: round(statistics.median(item["groups"][group] for item in readings), 2)
                                   for group in readings[0]["groups"]},
    }
