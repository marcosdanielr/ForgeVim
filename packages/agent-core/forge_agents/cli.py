"""Versioned JSON CLI: stdout is a single envelope; failures exit nonzero."""
import argparse
import json
import sqlite3
import sys

from .errors import ForgeError
from .service import AgentService


def parser():
    result = argparse.ArgumentParser(prog="forge-agents")
    result.add_argument("--root", default=".")
    commands = result.add_subparsers(dest="action", required=True)
    start = commands.add_parser("start")
    start.add_argument("--prompt", required=True)
    start.add_argument("--provider", choices=["codex", "claude", "gemini", "command"], default="codex")
    start.add_argument("--command-json", help="Trusted local executable argument array; prompt is stdin")
    chat = commands.add_parser("chat")
    chat.add_argument("--prompt", required=True, help="Human-readable conversation title")
    chat.add_argument("--provider", choices=["codex", "claude", "gemini", "command"], default="codex")
    chat.add_argument("--command-json", help="Trusted local interactive executable array")
    commands.add_parser("list")
    for action in ("review", "reject", "cancel", "logs"):
        commands.add_parser(action).add_argument("id")
    accept = commands.add_parser("accept")
    accept.add_argument("id")
    accept.add_argument("--hash", required=True)
    events = commands.add_parser("events")
    events.add_argument("--after", type=int, default=0)
    return result


def dispatch(service, arguments):
    action = arguments.action
    if action == "start":
        custom = json.loads(arguments.command_json) if arguments.command_json else None
        return service.start(arguments.prompt, arguments.provider, custom)
    if action == "chat":
        custom = json.loads(arguments.command_json) if arguments.command_json else None
        return service.create_chat(arguments.prompt, arguments.provider, custom)
    if action == "list":
        return service.tasks()
    if action == "events":
        return service.store.events(arguments.after)
    if action == "accept":
        return service.accept(arguments.id, arguments.hash)
    return getattr(service, action)(arguments.id)


def main():
    arguments = parser().parse_args()
    try:
        initialize = arguments.action not in {"list", "logs", "events"}
        data = dispatch(AgentService(arguments.root, initialize=initialize), arguments)
        print(json.dumps({"version": 1, "ok": True, "data": data}))
    except (ForgeError, OSError, ValueError, sqlite3.Error) as error:
        print(json.dumps({"version": 1, "ok": False, "error": str(error)}))
        sys.exit(1)
