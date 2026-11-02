"""Read macOS process accounting using the SDK rusage_info_v1 ABI."""
import ctypes


class Usage(ctypes.Structure):
    _fields_ = [("uuid", ctypes.c_uint8 * 16)] + [
        (name, ctypes.c_uint64) for name in (
            "user_time", "system_time", "pkg_idle_wkups", "interrupt_wkups", "pageins",
            "wired_size", "resident_size", "phys_footprint", "proc_start_abstime", "proc_exit_abstime",
            "child_user_time", "child_system_time", "child_pkg_idle_wkups", "child_interrupt_wkups",
            "child_pageins", "child_elapsed_abstime",
        )
    ]


library = ctypes.CDLL("/usr/lib/libproc.dylib", use_errno=True)
library.proc_pid_rusage.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_void_p]
library.proc_pid_rusage.restype = ctypes.c_int


class Timebase(ctypes.Structure):
    _fields_ = [("numer", ctypes.c_uint32), ("denom", ctypes.c_uint32)]


timebase = Timebase()
system = ctypes.CDLL("/usr/lib/libSystem.B.dylib")
system.mach_timebase_info(ctypes.byref(timebase))
seconds_per_tick = timebase.numer / timebase.denom / 1_000_000_000


def read(pid):
    usage = Usage()
    if library.proc_pid_rusage(pid, 1, ctypes.byref(usage)) != 0:
        return None
    return {
        "cpu_seconds": (usage.user_time + usage.system_time + usage.child_user_time + usage.child_system_time) * seconds_per_tick,
        "rss_kib": usage.resident_size / 1024,
        "footprint_mib": usage.phys_footprint / (1024 * 1024),
    }
