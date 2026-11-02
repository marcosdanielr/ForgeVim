"""Relay a locally owned PTY, including input, output, resize, and cancellation."""
import errno
import fcntl
import os
import selectors
import signal
import subprocess
import termios
import time
import tty

from .worker import terminate


class OwnedPty:
    def __init__(self, arguments, directory):
        self.pid, self.master = os.forkpty()
        self.returncode = None
        if self.pid == 0:
            try:
                os.chdir(directory)
                os.execvp(arguments[0], arguments)
            except OSError as error:
                os.write(2, (str(error) + "\n").encode())
                os._exit(127)

    def poll(self):
        if self.returncode is None:
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                self.returncode = os.waitstatus_to_exitcode(status)
        return self.returncode

    def wait(self, timeout=None):
        deadline = time.monotonic() + timeout if timeout is not None else None
        while self.poll() is None:
            if deadline is not None and time.monotonic() >= deadline:
                raise subprocess.TimeoutExpired(str(self.pid), timeout)
            time.sleep(0.02)
        return self.returncode

    def resize(self):
        if os.isatty(0):
            size = fcntl.ioctl(0, termios.TIOCGWINSZ, b"\0" * 8)
            fcntl.ioctl(self.master, termios.TIOCSWINSZ, size)


def write_all(descriptor, data):
    while data:
        count = os.write(descriptor, data)
        data = data[count:]


def relay(arguments, directory, output, tick):
    """tick returns true only when this session should stop its own provider."""
    process = OwnedPty(arguments, directory)
    previous = None
    handlers = {}
    stopping = False

    def request_stop(_signal, _frame):
        nonlocal stopping
        stopping = True

    def resize(_signal, _frame):
        process.resize()

    try:
        previous = termios.tcgetattr(0) if os.isatty(0) else None
        for number in (signal.SIGTERM, signal.SIGHUP, signal.SIGINT):
            handlers[number] = signal.signal(number, request_stop)
        handlers[signal.SIGWINCH] = signal.signal(signal.SIGWINCH, resize)
        process.resize()
        if previous is not None:
            tty.setraw(0)
        with selectors.DefaultSelector() as selector:
            selector.register(process.master, selectors.EVENT_READ)
            try:
                selector.register(0, selectors.EVENT_READ)
            except (PermissionError, OSError):
                pass
            while True:
                if stopping or tick():
                    terminate(process)
                    return process.returncode, True
                for key, _ in selector.select(0.25):
                    try:
                        data = os.read(key.fd, 65536)
                    except OSError as error:
                        if error.errno != errno.EIO:
                            raise
                        data = b""
                    if not data:
                        selector.unregister(key.fd)
                        if key.fd == 0:
                            try:
                                write_all(process.master, b"\x04")
                            except OSError as error:
                                if error.errno != errno.EIO:
                                    raise
                        continue
                    if key.fd == process.master:
                        output.write(data)
                        output.flush()
                        write_all(1, data)
                    else:
                        write_all(process.master, data)
                if process.poll() is not None and process.master not in selector.get_map():
                    return process.returncode, False
    finally:
        terminate(process)
        os.close(process.master)
        if previous is not None:
            termios.tcsetattr(0, termios.TCSANOW, previous)
        for number, handler in handlers.items():
            signal.signal(number, handler)
