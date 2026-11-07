"""Drive the game for automated tests: launch, load a save, run exec functions, quit.

Works through the test-only automation mod (tools/automation, installed as modAutomation),
rw3d_cli (tools/rw3d) and the script log, so normal runs need no key presses or
screenshots. See docs/game-automation.md.

Usage:
    python tools/game.py run SAVE --holder AREA:TOKEN       start, load SAVE and wait until playable
    python tools/game.py start --holder AREA:TOKEN          launch and wait for the main menu
    python tools/game.py load SAVE --holder AREA:TOKEN      load SAVE (file name without .sav)
    python tools/game.py exec "CMD" ... --holder AREA:TOKEN run exec functions, print their output
    python tools/game.py resume --holder AREA:TOKEN         close the open menu, if any
    python tools/game.py status              what the game is doing (in game, paused, open menu)
    python tools/game.py saves [-n N]        list the N newest saves (default 10)
    python tools/game.py log [-n N]          print the last N script log lines
    python tools/game.py quit                exit the game (falls back to closing the window, then killing it)

The game is one shared slot (tools/game_lock.py, docs/game-automation.md#the-game-slot): run, start,
load, exec and resume need --holder AREA:TOKEN from the lock's grant (the parent's --parent skips
the check, for emergencies; it is logged). SAVE must be one of the allowed test saves
(ALLOWED_SAVES, by full name); every load locks saving for the session with gmtest_nosave().
`start` refuses a modGhostMode build the holder did not install this turn (build_mod.py --install-from).

Exit code 0 on success, 1 on a timeout, error or refusal (the last script log lines are printed),
3 when the lock refuses because the slot is paused or the holder's token was revoked.
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
import game_lock  # noqa: E402
from paths import documents_dir, game_dir  # noqa: E402

REPO = Path(__file__).resolve().parent.parent
RW3D = REPO / "tools" / "rw3d" / "rw3d_cli.exe"
GAME = game_dir()
EXE = GAME / "bin" / "x64_dx12" / "witcher3.exe"
LOG = documents_dir() / "The Witcher 3" / "scriptslog.txt"
PORT = 37001
TAG = "[Automation] "
EXEC_WAIT_MS = 500
STARTUP_SCREENS = ("StartupMoviesMenu", "RecapMoviesMenu", "StartupExperienceMenu")
GATED = ("run", "start", "load", "exec", "resume")
# The saves run and load accept, by full name: the test save and the test-only slot (docs/game-automation.md#test-saves).
# The owner's playthrough save, loaded read-only (saving locked) with the owner's OK of 2026-11-06 to reproduce bugs.
ALLOWED_SAVES = ("<save name>", "<save name>", "<save name>",
                 "<save name>")  # a new game's first checkpoint (new tree, build 1090142), kept as a test save by the owner, 2026-11-07
# Exec calls that load or save behind the allow-list's back (the parent passes --parent for its own saves).
DENIED_EXEC = (r"\bautoload\s*\(", r"savegame", r"\bgmtest_diff04_lsave_save\b", r"\bgmtest_diff04_save_mk\b",
               r"\bgmtest_xp08_vit_b\s*\(\s*true", r"\bgmtest_arm09_mksave\b")
MARKER = GAME / "mods" / "modGhostMode" / ".built-by-build_mod"
GATE = None  # the lock's answer for this call (game_lock.Gate)


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

def check_installed() -> None:
    """The installed modGhostMode must be the build the holder installed this turn."""
    marker = MARKER.read_text(encoding="utf-8").splitlines()[0].strip() if MARKER.exists() else ""
    rec = (GATE.installed or {}).get("marker", "") if GATE else ""
    if GATE and GATE.parent:
        say(f"installed build: {marker or 'none'} (--parent: not checked)")
        return
    if not marker:
        fail(f"no modGhostMode installed by build_mod.py ({MARKER})")
    if marker != rec:
        fail(f"the installed build ({marker}) is not one you installed this turn"
             + (f" (you installed {rec})" if rec else "")
             + ": python tools/build_mod.py --install-from <your build> --holder AREA:TOKEN")
    say(f"installed build: {marker}")


def cmd_start(args) -> None:
    if game_pids():
        say("already running")
        return
    check_installed()
    if not (GAME / "mods" / "modAutomation").exists():
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
    exec_once(f'autoload("{args.save}")')
    cursor.wait_for("loading", 10)
    cursor.wait_for("game started", args.timeout)
    cursor.wait_for("ready", args.timeout)
    say(f"loaded after {time.monotonic() - t0:.0f} s")
    settle()
    if args.allow_saves:
        say("saving NOT locked (--allow-saves)")
        return
    ok, out = rw3d_exec("gmtest_nosave()")
    if not ok or "saves locked" not in out:
        fail(f"gmtest_nosave() did not lock saving (is modGhostMode with its tests installed?): {out}")
    say("saving locked for this session (gmtest_nosave)")


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
        if name in GATED:
            p.add_argument("--holder", help="AREA:TOKEN from python tools/game_lock.py request/wait")
            p.add_argument("--parent", action="store_true", help="the parent only: skip the lock check (logged)")
        if extra == "save":
            p.add_argument("save", nargs="?", default="", help="one of the allowed saves: " + ", ".join(ALLOWED_SAVES))
            p.add_argument("--allow-saves", action="store_true", help="with --parent: do not lock saving")
        elif extra == "cmds":
            p.add_argument("cmds", nargs="+", help='exec calls, e.g. "gmpilot()"')
        if name in ("log", "saves"):
            p.add_argument("-n", type=int, default=40 if name == "log" else 10, help="how many lines / saves")
        p.add_argument("--timeout", type=float, default=180, help="seconds to wait for each step (default: 180)")
        p.add_argument("--wait", type=int, default=500, help="ms rw3d_cli waits for exec output (default: 500)")
    args = ap.parse_args()
    global EXEC_WAIT_MS, GATE
    EXEC_WAIT_MS = args.wait
    if args.command in GATED:
        precheck(args)
        try:
            GATE = game_lock.gate(args.holder, args.parent, f"game.py {args.command}")
        except game_lock.Refused as e:
            say(f"refused: {e}")
            sys.exit(e.code)
        game_lock.selftest_stop(GATE, f"game.py {args.command}")
    args.fn(args)


def precheck(args) -> None:
    """Refusals that need no lock: saves off the allow-list, exec calls that load or save."""
    def refuse(msg):
        say(f"refused: {msg}")
        sys.exit(1)
    if args.command in ("run", "load"):
        if not args.save:
            refuse("name the save (the newest save is never loaded): " + " or ".join(ALLOWED_SAVES))
        if args.save.lower() not in (s.lower() for s in ALLOWED_SAVES):
            refuse(f"{args.save} is not an allowed test save: " + " or ".join(ALLOWED_SAVES))
        if args.allow_saves and not args.parent:
            refuse("--allow-saves is for the parent (--parent)")
    if args.command == "exec" and not args.parent:
        for cmd in args.cmds:
            for pat in DENIED_EXEC:
                if re.search(pat, cmd, re.I):
                    refuse(f"{cmd!r} loads or saves a game: run and load take the allowed saves; saves are the parent's")


if __name__ == "__main__":
    main()
