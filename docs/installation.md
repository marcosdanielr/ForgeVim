# Installation

ForgeVim uses an isolated per-user command, inspired by LunarVim's installer
workflow. It requires macOS/Linux, Neovim 0.11+, Git, ripgrep, and Python 3.9+.
No sudo, system package installation, shell-profile edits, or model login runs
automatically. Node.js, SDKs, language tools, and AI CLIs remain explicit choices.

## Install from a checkout

The repository is private during development. Authenticate Git or use GitHub CLI
with an account that has access:

```sh
gh repo clone marcosdanielr/ForgeVim
cd ForgeVim
bash install.sh
forge .
```

The installer validates tools, creates a sparse managed runtime under
`${XDG_DATA_HOME:-~/.local/share}/forge.nvim/runtime`, installs selected plugins
from the lockfile, and creates `${INSTALL_PREFIX:-~/.local}/bin/forge`.
The website and its pnpm dependencies are not installed with the editor.

If `forge` is not found, add `~/.local/bin` to PATH or use `~/.local/bin/forge`.
The installer prints the exact PATH line for a custom `--prefix`. It never replaces
an existing executable, symlink, or personal `user.lua`. Existing `~/.config/nvim`
remains independent through `NVIM_APPNAME=forge.nvim`.

## One command with authenticated GitHub access

While the repository is private, fetch the bootstrap through your authenticated
GitHub CLI. Anonymous raw-GitHub downloads will not work for a private repository.

```sh
bash <(gh api repos/marcosdanielr/ForgeVim/contents/install.sh -H 'Accept: application/vnd.github.raw+json')
```

The bootstrap downloads a sparse source copy and delegates to the same installer.
No npm or pnpm is required for the editor. This is executable project code, just
like installing its plugins; use the checkout flow when you want to inspect it.

## Develop directly from an external SSD

```sh
cd /Volumes/DEV_SSD/Projects/forge.nvim
bash install.sh --local
forge .
```

`--local` points the launcher to this checkout without copying it or running Git
updates against your work. Keep the SSD mounted. Update a development checkout
through your usual Git workflow. XDG locations and INSTALL_PREFIX remain supported.

## Manage an installation

```sh
forge --doctor
forge --update
forge --uninstall
```

Managed updates require a clean source tree and a fast-forward. Plugin verification
failure restores the previous distribution source. Personal plugin lock choices
remain authoritative; use :Lazy for intentional dependency changes. Development
installs refuse automatic source updates. The installer preserves user config,
preferences, plugins, source, logs, and worktrees when uninstalling the launcher;
retained ownership metadata allows reinstalling the same profile safely.

`--no-plugins` skips provisioning for offline testing. A later interactive launch
may install plugins, so it is not a permanent offline switch. `FORGE_OFFLINE=1`
continues to disable plugin startup. Installer logs live in the Forge state
folder at `forge/install.log`, with owner-only permissions. Rerunning a matching
install is safe; changed launchers and unrelated runtime folders are preserved.

## Verification and provenance

`make test` covers temporary local/managed installation, command collisions,
quoting, repeatability, uninstall/reinstall, failed provisioning, and update rollback.
Actual plugin provisioning and installed-command launch are verified separately.
The workflow is inspired by the [LunarVim installer](https://github.com/LunarVim/LunarVim/blob/master/utils/installer/install.sh);
its source is not copied or vendored.

ForgeVim retains the `forge` command and the `forge.nvim` XDG profile name for compatibility. Existing personal plugins, logins, settings, installer metadata, and SSD checkout paths remain valid after the repository rename.
