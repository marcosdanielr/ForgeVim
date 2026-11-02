"""Installer CLI shared by the bootstrap and installed management commands."""
import argparse
import os
import subprocess
from pathlib import Path

from . import dependencies, service, source
from .paths import InstallPaths, lock


def main():
    parser = argparse.ArgumentParser(description="Install ForgeVim as an isolated per-user command.")
    parser.add_argument("operation", nargs="?", choices=("install", "doctor", "update", "uninstall"), default="install")
    parser.add_argument("--local", action="store_true", help="Use this checkout directly, including an external SSD")
    parser.add_argument("--prefix", help="Command prefix; defaults to INSTALL_PREFIX or ~/.local")
    parser.add_argument("--repository", default=source.REPOSITORY, help="Trusted Git source for a managed installation")
    parser.add_argument("--ref", default="main", help="Git branch, tag or commit for a managed install")
    parser.add_argument("--no-plugins", action="store_true", help="Skip plugin provisioning; first interactive launch may install them")
    arguments = parser.parse_args()
    paths = InstallPaths.defaults(arguments.prefix)
    manifest = Path(os.environ.get("FORGE_INSTALL_MANIFEST", paths.manifest))
    try:
        if arguments.operation == "doctor":
            dependencies.check()
        else:
            with lock(manifest.parent):
                if arguments.operation == "uninstall":
                    service.uninstall(manifest)
                elif arguments.operation == "update":
                    dependencies.check()
                    service.update(manifest, plugins=not arguments.no_plugins)
                else:
                    checkout = Path(__file__).resolve().parents[2]
                    service.install(paths, checkout, local=arguments.local, repository=arguments.repository,
                        revision=arguments.ref, plugins=not arguments.no_plugins)
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        parser.exit(1, "Installation error: " + str(error) + "\n")
