#!/usr/bin/env bash
set -euo pipefail

if ! command -v python3 >/dev/null 2>&1; then
  echo "Python 3.9+ is required. Install it, then run this installer again." >&2
  exit 1
fi
if ! command -v git >/dev/null 2>&1; then
  echo "Git is required. Install it, then run this installer again." >&2
  exit 1
fi
forge_installer_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$forge_installer_root/scripts/install.py" ]; then
  exec python3 "$forge_installer_root/scripts/install.py" "$@"
fi

# A downloaded bootstrap owns only this freshly-created temporary directory.
for forge_argument in "$@"; do
  if [ "$forge_argument" = "--local" ]; then
    echo "For --local, clone the repository and run its install.sh." >&2
    exit 1
  fi
done
forge_repository="${FORGE_REPOSITORY:-https://github.com/marcosdanielr/forgevim.git}"
forge_staging="$(mktemp -d "${TMPDIR:-/tmp}/forge-bootstrap.XXXXXX")"
trap 'rm -rf -- "$forge_staging"' EXIT
if command -v gh >/dev/null 2>&1 && gh auth status --hostname github.com >/dev/null 2>&1 && [ "$forge_repository" = "https://github.com/marcosdanielr/forgevim.git" ]; then
  gh repo clone marcosdanielr/forgevim "$forge_staging/source" -- --filter=blob:none --sparse
else
  git clone --filter=blob:none --sparse -- "$forge_repository" "$forge_staging/source"
fi
git -C "$forge_staging/source" sparse-checkout set bin apps/nvim packages/agent-core packages/protocol scripts
python3 "$forge_staging/source/scripts/install.py" "$@"
