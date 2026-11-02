"""Provider command construction; no shell, embedded credentials, or model defaults."""
import shutil

from .errors import ForgeError


def command(provider, custom=None):
    if provider == "codex":
        arguments = ["codex", "-a", "never", "exec", "--sandbox", "workspace-write", "--json", "-"]
    elif provider == "claude":
        arguments = ["claude", "--print", "--output-format", "stream-json", "--verbose",
                     "--permission-mode", "acceptEdits"]
    elif provider == "gemini":
        arguments = ["gemini", "--output-format", "stream-json", "--approval-mode", "auto_edit"]
    elif provider == "command" and custom:
        arguments = custom
    else:
        raise ForgeError("Provider must be codex, claude, gemini, or command with an explicit command array.")
    return resolve(arguments)


def resolve(arguments):
    if not isinstance(arguments, list) or not all(isinstance(item, str) and item and "\0" not in item for item in arguments):
        raise ForgeError("Provider command must be a nonempty JSON array of strings.")
    executable = shutil.which(arguments[0])
    if not executable:
        raise ForgeError("Provider executable not found: " + arguments[0])
    return [executable, *arguments[1:]]


def interactive_command(provider, custom=None):
    """Interactive CLIs keep their normal permission prompts and account login."""
    if provider == "codex":
        arguments = ["codex", "-a", "on-request", "--sandbox", "workspace-write"]
    elif provider == "claude":
        arguments = ["claude"]
    elif provider == "gemini":
        arguments = ["gemini"]
    elif provider == "command" and custom:
        arguments = custom
    else:
        raise ForgeError("Unknown interactive provider.")
    return resolve(arguments)


def instruction(prompt):
    return (
        "Work only on the requested task in this worktree. Do not modify the source checkout "
        "or .forge state. Do not push or remove worktrees. Preserve user instructions. "
        "Run focused checks and report changes and remaining limitations. "
        "The user will review a patch before applying it.\n\n" + prompt
    )
