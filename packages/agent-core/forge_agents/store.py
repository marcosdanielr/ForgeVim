"""SQLite persistence and one cross-process mutation lock per source checkout."""
import fcntl
import json
import sqlite3
import time
from contextlib import contextmanager, closing

from .errors import ForgeError


class Store:
    def __init__(self, directory):
        self.directory = directory
        directory.mkdir(parents=True, exist_ok=True)
        self.database = directory / "state.sqlite3"
        with self.connection() as connection:
            connection.executescript("""
                CREATE TABLE IF NOT EXISTS tasks (
                    id TEXT PRIMARY KEY, data TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS events (
                    sequence INTEGER PRIMARY KEY AUTOINCREMENT,
                    task_id TEXT NOT NULL, kind TEXT NOT NULL,
                    timestamp REAL NOT NULL, data TEXT NOT NULL
                );
            """)

    @contextmanager
    def connection(self):
        with closing(sqlite3.connect(str(self.database), timeout=15)) as connection:
            connection.row_factory = sqlite3.Row
            with connection:
                yield connection

    @contextmanager
    def locked(self):
        with (self.directory / "mutation.lock").open("a") as stream:
            fcntl.flock(stream, fcntl.LOCK_EX)
            try:
                yield
            finally:
                fcntl.flock(stream, fcntl.LOCK_UN)

    def save(self, task, kind=None):
        with self.connection() as connection:
            connection.execute("INSERT OR REPLACE INTO tasks VALUES (?, ?)",
                               (task["id"], json.dumps(task)))
            if kind:
                connection.execute(
                    "INSERT INTO events(task_id,kind,timestamp,data) VALUES(?,?,?,?)",
                    (task["id"], kind, time.time(), json.dumps({"status": task["status"]})),
                )
        return task

    def get(self, task_id):
        with self.connection() as connection:
            row = connection.execute("SELECT data FROM tasks WHERE id=?", (task_id,)).fetchone()
        if row is None:
            raise ForgeError("Unknown task: " + task_id)
        return json.loads(row["data"])

    def tasks(self):
        with self.connection() as connection:
            rows = connection.execute("SELECT data FROM tasks ORDER BY rowid DESC").fetchall()
        return [json.loads(row["data"]) for row in rows]

    def events(self, after):
        with self.connection() as connection:
            rows = connection.execute(
                "SELECT * FROM events WHERE sequence > ? ORDER BY sequence LIMIT 500", (after,)
            ).fetchall()
        return [{**dict(row), "data": json.loads(row["data"])} for row in rows]
