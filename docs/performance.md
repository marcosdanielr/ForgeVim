# Resource measurements

Observed on November 2, 2026: macOS arm64, eight logical CPUs, Neovim 0.12.6,
Python 3.13.18, and the source checkout on DEV_SSD. Installed plugins are reused;
language profiles are disabled. These are engineering probes, not a resource SLA.

## Method

The probe starts a headless Neovim process, creates actual native panel buffers,
and runs real child PTYs. Each scenario warms up, then samples about six seconds
of idle operation. Four agents means four explicitly local Python provider
fixtures that print once and sleep; no model account, network inference, or paid
tokens are used. Terminal-app/TUI rendering, LSPs, debug adapters, build tools,
and real Codex/Claude/Gemini resident costs are excluded.

CPU uses macOS proc_pid_rusage v1 accounting, converted through the host Mach
timebase. Own and reaped-child CPU is included. The conversion was checked against
POSIX process and child CPU clocks. CPU percentages use one core as 100%; they
are window averages, not peak CPU or whole-machine percentages.

RSS is the sum of sampled resident sizes and can count shared pages repeatedly.
Footprint is memory charged by macOS process accounting, including its compressed
memory treatment. Neither summed measure is a universal unique-physical-RAM
metric. Sampled peaks can miss short-lived processes between observations.

## Results

| Idle workload | Median footprint (MiB) | Median RSS (MiB) | CPU / one core |
| --- | ---: | ---: | ---: |
| Editor and native panel buffers | 13.45 | 18.94 | 0.00% |
| Editor plus four shell terminals | 38.13 | 17.05 | 0.00% |
| Editor plus four local provider fixtures | 74.27 | 117.22 | 2.60% |

In the four-provider fixture, the Python coordination processes account for about
40.54 MiB of footprint, Neovim about 13.20 MiB, and the fixture provider processes
about 20.52 MiB. Category medians need not sum exactly to the total median.
Observed 0.00% is a short idle sample rounded to two decimals, not a guarantee of
zero CPU in use. Active editing, completion, debugging, tool execution, rendering,
and authenticated providers need separate measurements.

## Changes motivated by measurement

Status/log/event reads reuse existing SQLite state rather than bootstrapping Git
and schema on each request. Task creation, review, and application keep their Git
checks. Panels and notifications share one event-driven subscription per project;
heartbeats never emit UI wakeups. A five-second active-task fallback preserves
lost-worker detection and platforms where file events are unavailable.

These measurements do not establish a Rust/Python comparison. Python has a
measurable per-session memory cost. A Rust coordinator or shared process may
reduce it, but its implementation must be measured under the same workload before
claiming a saving. Neovim/Lua remains the editor/rendering boundary.

## Reproduce

Install Forge plugins first. Pass the XDG data root that contains
forge.nvim/lazy/lazy.nvim; the probe uses temporary projects and isolated settings.

```sh
python3 scripts/benchmark-resources.py --nvim nvim --data-home /path/to/xdg/data --seconds 6
python3 scripts/benchmark-resources.py --nvim nvim --data-home /path/to/xdg/data --scenario agents
python3 scripts/benchmark-startup.py --nvim nvim
```

The resource probe currently supports macOS only. It does not modify the source
project or authenticate providers. Raw observations are versioned in
[the benchmark record](benchmarks/2026-11-02-macos-arm64.json).
