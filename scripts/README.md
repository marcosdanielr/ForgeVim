# Developer commands

These tools support development; the editor launcher does not run verification or
benchmark programs during startup.

| Directory | Responsibility |
| --- | --- |
| `installer/` and `install.py` | Stable per-user installation and management entry point |
| `verify/` | Isolated editor, terminal, plugin, Git, and Dart checks |
| `benchmarks/` | Startup and resource measurements with platform helpers |
| `setup/` | Explicit language-tool provisioning for enabled profiles |
| `deploy/` | Website deployment filtering |

Run `make test` and `make smoke` for the normal verification gates. Optional
installed-plugin checks use `python3 scripts/verify/plugins.py`. Individual checks
accept the same arguments as before; only their source paths have changed.
