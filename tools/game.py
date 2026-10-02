"""Drive the game for automated tests: launch, load a save, run exec functions, quit.

Works through the test-only automation mod (tools/automation, installed as modAutomation),
rw3d_cli (tools/rw3d) and the script log, so normal runs need no key presses or
screenshots. See docs/game-automation.md.

Usage:
    python tools/game.py run [SAVE]          start, load SAVE (default: newest) and wait until playable
    python tools/game.py start               launch and wait for the main menu
    python tools/game.py load [SAVE]         load SAVE (file name without .sav; default: newest)
    python tools/game.py exec "CMD" ...      run exec functions, print their output
    python tools/game.py status              what the game is doing (in game, paused, open menu)
    python tools/game.py resume              close the open menu, if any
    python tools/game.py saves [-n N]        list the N newest saves (default 10)
    python tools/game.py log [-n N]          print the last N script log lines
    python tools/game.py quit                exit the game (falls back to closing the window, then killing it)

Exit code 0 on success, 1 on a timeout or error (the last script log lines are printed).
"""

import argparse
import ctypes
import re
import socket
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_mod import DEFAULT_GAME, documents_dir  # noqa: E402

REPO = Path(__file__).resolve().parent.parent
RW3D = REPO / "tools" / "rw3d" / "rw3d_cli.exe"
EXE = DEFAULT_GAME / "bin" / "x64_dx12" / "witcher3.exe"
LOG = documents_dir() / "The Witcher 3" / "scriptslog.txt"
PORT = 37001
TAG = "[Automation] "
EXEC_WAIT_MS = 500
STARTUP_SCREENS = ("StartupMoviesMenu", "RecapMoviesMenu", "StartupExperienceMenu")


def say(msg: str) -> None:
    print(f"[game] {msg}", flush=True)


def fail(msg: str) -> None:
    say(f"error: {msg}")
    for line in read_log()[-15:]:
        print(f"  | {line}")
    sys.exit(1)


# --- process -------------------------------------------------------------------------

def game_pids() -> list[int]:
    out = subprocess.run(["tasklist", "/FI", "IMAGENAME eq witcher3.exe", "/FO", "CSV", "/NH"],
                         capture_output=True, text=True).stdout
    return [int(m.group(1)) for m in re.finditer(r'^"witcher3\.exe","(\d+)"', out, re.M)]


def port_open() -> bool:
    with socket.socket() as s:
        s.settimeout(0.5)
        return s.connect_ex(("127.0.0.1", PORT)) == 0


def wait_until(check, timeout: float, what: str, interval: float = 0.5):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        result = check()
        if result:
            return result
        time.sleep(interval)
    fail(f"timed out after {timeout:.0f} s waiting for {what}")


# --- script log ----------------------------------------------------------------------

def read_log() -> list[str]:
    try:
        return LOG.read_text(encoding="utf-8", errors="replace").splitlines()
    except FileNotFoundError:
        return []


class LogCursor:
    """Remembers how much of the script log has been seen, to wait for new lines."""

    def __init__(self, from_start: bool = False):
        self.pos = 0 if from_start else len(read_log())

    def new_lines(self) -> list[str]:
        lines = read_log()
        if len(lines) < self.pos:  # the game rewrote the log (restart)
            self.pos = 0
        new, self.pos = lines[self.pos:], len(lines)
        return new

    def find(self, pattern: str) -> str | None:
        """The first new [Automation] line starting with pattern (without the tag), if any."""
        for line in self.new_lines():
            if TAG in line:
                event = line.split(TAG, 1)[1]
                if event.startswith("error"):
                    fail(event)
                if event.startswith(pattern):
                    return event
        return None

    def wait_for(self, pattern: str, timeout: float) -> str:
        """Wait for an [Automation] line starting with pattern; return the line without the tag."""
        return wait_until(lambda: self.find(pattern), timeout, f'"{TAG}{pattern}" in the script log')


# --- rw3d_cli ------------------------------------------------------------------------

def rw3d_exec(cmd: str, timeout_ms: int | None = None) -> tuple[bool, str]:
    """Run an exec function. rw3d_cli always waits timeout_ms for more output after the reply,
    so keep it short; raise it (--wait) for functions that log over a longer time."""
    timeout_ms = timeout_ms or EXEC_WAIT_MS
    if not RW3D.exists():
        fail(f"{RW3D} not found (see docs/game-automation.md for the download)")
    r = subprocess.run([str(RW3D), "--no-delay", "--target", "game", "-l", "output-only",
                        "-t", str(timeout_ms), "exec", cmd], capture_output=True, text=True, errors="replace")
    out = (r.stdout + r.stderr).strip()
    ok = r.returncode == 0 and "Command failed to execute" not in out and "Error:" not in out
    return ok, out


def responsive(timeout: float = 60) -> None:
    """Wait until the game answers exec calls (it does not while starting or loading)."""
    if not game_pids():
        fail("the game is not running")
    wait_until(port_open, timeout, f"the debug port {PORT}")
    wait_until(lambda: rw3d_exec("autostatus()")[0], timeout, "the game to answer exec calls", 1)


def exec_once(cmd: str) -> str:
    """Run one exec function (no retries: it may have run even when the reply times out)."""
    ok, out = rw3d_exec(cmd)
    if not ok:
        fail(f"exec {cmd}: {out}")
    return out


def status() -> dict[str, str]:
    responsive()
    line = exec_once("autostatus()")
    return dict(re.findall(r"(\w+)=(\S+)", line))


# --- commands ------------------------------------------------------------------------

def cmd_start(args) -> None:
    if game_pids():
        say("already running")
        return
    if not (DEFAULT_GAME / "mods" / "modAutomation").exists():
        fail("modAutomation is not installed: python tools/build_mod.py --scripts tools/automation/scripts "
             "--name modAutomation --out build/automation --install --enable")
    LOG.unlink(missing_ok=True)
    cursor = LogCursor(from_start=True)
    t0 = time.monotonic()
    subprocess.Popen([str(EXE), "-net", "-debugscripts"], cwd=EXE.parent)
    say("launched")

    # Before the main menu the game queues screens that wait for input or take long: the
    # logo videos (StartupMoviesMenu, about 45 s), the intro video (RecapMoviesMenu) and, on some launches, the CD PROJEKT RED account sign-in
    # (StartupExperienceMenu). Closing one moves on to the next; closing the sign-in screen
    # leaves the sign-in and telemetry questions unanswered.
    def menu_shown():
        if cursor.find("main menu"):
            return True
        if port_open():
            ok, out = rw3d_exec("autostatus()")
            menu = re.search(r"menu=(\S+)", out)
            if ok and menu and menu.group(1) in STARTUP_SCREENS:
                rw3d_exec("autoresume()")
                say(f"closed {menu.group(1)}")
        return False
    wait_until(menu_shown, args.timeout, f'"{TAG}main menu" in the script log', 0.5)
    say(f"main menu after {time.monotonic() - t0:.0f} s")


def cmd_load(args) -> None:
    responsive()
    cursor = LogCursor()
    t0 = time.monotonic()
    exec_once(f'autoload("{args.save}")' if args.save else "autoload()")
    cursor.wait_for("loading", 10)
    cursor.wait_for("game started", args.timeout)
    cursor.wait_for("ready", args.timeout)
    say(f"loaded after {time.monotonic() - t0:.0f} s")
    settle()


def settle() -> None:
    """After a load: make sure no menu is open and the game is not paused."""
    st = status()
    if st.get("menu", "none") != "none":
        say(f"closing menu {st['menu']}")
        exec_once("autoresume()")
        st = status()
    say("status: " + " ".join(f"{k}={v}" for k, v in st.items()))
    if st.get("ingame") != "true" or st.get("paused") == "true" or st.get("menu") != "none":
        fail("the game is not in a playable state")


def cmd_run(args) -> None:
    cmd_start(args)
    cmd_load(args)


def cmd_exec(args) -> None:
    responsive()
    for cmd in args.cmds:
        print(exec_once(cmd))


def cmd_status(args) -> None:
    print(" ".join(f"{k}={v}" for k, v in status().items()))


def cmd_resume(args) -> None:
    responsive()
    print(exec_once("autoresume()"))


def cmd_saves(args) -> None:
    responsive()
    print(exec_once(f"autosaves({args.n})"))


def cmd_log(args) -> None:
    for line in read_log()[-args.n:]:
        print(line)


def cmd_quit(args) -> None:
    pids = game_pids()
    if not pids:
        say("not running")
        return
    t0 = time.monotonic()
    if port_open():
        rw3d_exec("autoquit()")  # the reply often never comes: the game is already exiting
        if wait_for_exit(60):
            say(f"exited after {time.monotonic() - t0:.0f} s")
            return
        say("still running after autoquit(); closing the window")
    close_window(pids[0])
    if wait_for_exit(30):
        say(f"exited after closing the window ({time.monotonic() - t0:.0f} s)")
        return
    say("still running; killing it")
    subprocess.run(["taskkill", "/F", "/IM", "witcher3.exe"], capture_output=True)
    wait_for_exit(10) or fail("could not stop the game")


def wait_for_exit(timeout: float) -> bool:
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        if not game_pids():
            return True
        time.sleep(0.5)
    return False


def close_window(pid: int) -> None:
    """Post WM_CLOSE to the game's top-level windows."""
    user32 = ctypes.windll.user32
    proc = ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_void_p, ctypes.c_void_p)

    def each(hwnd, _):
        owner = ctypes.c_ulong()
        user32.GetWindowThreadProcessId(hwnd, ctypes.byref(owner))
        if owner.value == pid and user32.IsWindowVisible(hwnd):
            user32.PostMessageW(hwnd, 0x0010, 0, 0)  # WM_CLOSE
        return True
    user32.EnumWindows(proc(each), 0)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="command", required=True)
    for name, fn, extra in (("run", cmd_run, "save"), ("start", cmd_start, None), ("load", cmd_load, "save"),
                            ("exec", cmd_exec, "cmds"), ("status", cmd_status, None), ("resume", cmd_resume, None),
                            ("saves", cmd_saves, None), ("log", cmd_log, None), ("quit", cmd_quit, None)):
        p = sub.add_parser(name)
        p.set_defaults(fn=fn)
        if extra == "save":
            p.add_argument("save", nargs="?", default="", help="save file name without .sav (default: newest)")
        elif extra == "cmds":
            p.add_argument("cmds", nargs="+", help='exec calls, e.g. "gmpilot()"')
        if name in ("log", "saves"):
            p.add_argument("-n", type=int, default=40 if name == "log" else 10, help="how many lines / saves")
        p.add_argument("--timeout", type=float, default=180, help="seconds to wait for each step (default: 180)")
        p.add_argument("--wait", type=int, default=500, help="ms rw3d_cli waits for exec output (default: 500)")
    args = ap.parse_args()
    global EXEC_WAIT_MS
    EXEC_WAIT_MS = args.wait
    args.fn(args)


if __name__ == "__main__":
    main()
