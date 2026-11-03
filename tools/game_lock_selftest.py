"""Offline self-test of the game lock (tools/game_lock.py) and of the gates in game.py and build_mod.py.

    python tools/game_lock.py selftest [--keep]

Everything runs in a temporary folder (TGM_LOCK_SELFTEST_ROOT): a fake state folder, a fake
Documents\\The Witcher 3 with settings files, saves and a script log, a fake backup folder and a
file that stands for the running game. The real lock state, settings, saves and game are never
touched: game.py and build_mod.py stop right after their gate check in this mode. Short timings
(claim deadline 3 s, lease 4 s) keep it under a minute.
"""

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
PY = sys.executable
SAVES = ("<save name>", "<save name>")


class T:
    def __init__(self, root: Path):
        self.root = root
        self.env = dict(os.environ, TGM_LOCK_SELFTEST_ROOT=str(root), PYTHONIOENCODING="utf-8")
        self.docs = root / "docs" / "The Witcher 3"
        self.state = root / "state"
        self.flag = root / "game_running"
        self.passed = self.failed = 0

    def run(self, *args, tool="game_lock.py", timeout=60):
        r = subprocess.run([PY, str(TOOLS / tool), *args], env=self.env, capture_output=True, text=True,
                           encoding="utf-8", errors="replace", timeout=timeout)
        return r.returncode, (r.stdout + r.stderr).strip()

    def bg(self, *args, tool="game_lock.py"):
        return subprocess.Popen([PY, str(TOOLS / tool), *args], env=self.env, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace")

    def check(self, ok, label, detail=""):
        if ok:
            self.passed += 1
            print(f"PASS {label}")
        else:
            self.failed += 1
            print(f"FAIL {label}" + (f"\n     {detail}" if detail else ""))

    def expect(self, args, code, pattern, label, **kw):
        rc, out = self.run(*args, **kw)
        self.check(rc == code and re.search(pattern, out, re.S | re.I), label, f"exit {rc}: {out[-600:]}")
        return out

    def token(self, out):
        m = re.search(r"token ([0-9a-f]{8})", out)
        return m.group(1) if m else "none"

    def events(self):
        return [json.loads(x) for x in (self.state / "events.log").read_text(encoding="utf-8").splitlines()]


def setup(root: Path) -> T:
    t = T(root)
    t.docs.mkdir(parents=True)
    for n in ("dx12user.settings", "input.settings", "profile.settings", "mods.settings"):
        (t.docs / n).write_text(f"[{n}]\nvalue=baseline\n", encoding="utf-8")
    saves = t.docs / "gamesaves"
    saves.mkdir()
    for n in (*SAVES, "AutoSave_old_1", "ManualSave_owner_1"):
        (saves / f"{n}.sav").write_bytes(n.encode() * 10)
    (t.docs / "scriptslog.txt").write_text("[GMTest] PASS fake\n", encoding="utf-8")
    t.state.mkdir()
    (t.state / "config.json").write_text(json.dumps({"claim_deadline_s": 3, "lease_s": 4, "stale_s": 2, "poll_s": 0.2}),
                                         encoding="utf-8")
    fake = root / "fakebuild" / "modGhostMode"
    fake.mkdir(parents=True)
    (fake / ".built-by-build_mod").write_text("gm/test 0123456789abcdef\n", encoding="utf-8")
    return t


def finish(p, timeout=15):
    try:
        out, _ = p.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        p.kill()
        out, _ = p.communicate()
        return None, out
    return p.returncode, out


def scenario(t: T) -> None:
    # --- no baseline: nothing is granted -----------------------------------------------------
    t.expect(["request", "--who", "A", "--why", "first"], 2, r"queued: position 1.*no settings baseline",
             "no baseline: the request is queued, grants blocked")
    t.expect(["baseline"], 1, r"parent only", "baseline refused without --parent")
    t.flag.touch()
    t.expect(["baseline", "--parent"], 1, r"game is running", "baseline refused while the game runs")
    t.flag.unlink()
    t.expect(["baseline", "--parent", "--why", "selftest"], 0, r"baseline taken", "baseline taken with the game closed")

    # --- grant, wait, the backup ------------------------------------------------------------
    out = t.expect(["wait", "--who", "A", "--timeout", "5"], 0, r"granted: token [0-9a-f]{8}.*robocopy exit [0-7]",
                   "A granted after the baseline; wait exits 0 with the token")
    ta = t.token(out)
    backed = sorted(p.name for p in (t.root / "backup" / "gamesaves").iterdir())
    t.check(len(backed) == 4, "the grant backed up the saves (robocopy /E /XO)", str(backed))

    # --- FIFO: B then C wait in the background ----------------------------------------------
    t.expect(["request", "--who", "B", "--why", "second"], 2, r"queued: position 1 of 1", "B queued first")
    t.expect(["request", "--who", "C", "--why", "third"], 2, r"queued: position 2 of 2", "C queued second")
    t.expect(["request", "--who", "C", "--why", "again"], 2, r"queued: position 2 of 2", "a second request keeps C's place")
    wb = t.bg("wait", "--who", "B", "--timeout", "30")
    wc = t.bg("wait", "--who", "C", "--timeout", "40")

    # --- gates: game.py and build_mod.py ----------------------------------------------------
    t.expect(["exec", "gmtest_x()"], 1, r"refused: .*--holder AREA:TOKEN", "game.py exec refused without --holder", tool="game.py")
    t.expect(["exec", "gmtest_x()", "--holder", "A:00000000"], 1, r"refused: A does not hold", "game.py exec refused with a wrong token", tool="game.py")
    t.expect(["exec", "gmtest_x()", "--holder", f"B:{ta}"], 1, r"refused: B does not hold", "game.py exec refused for a queued agent", tool="game.py")
    t.expect(["run", "--holder", f"A:{ta}"], 1, r"refused: name the save", "game.py run refused without a save name", tool="game.py")
    t.expect(["run", "<save name>", "--holder", f"A:{ta}"], 1, r"not an allowed test save",
             "game.py run refused for a save off the allow-list", tool="game.py")
    t.expect(["exec", 'autoload("x")', "--holder", f"A:{ta}"], 1, r"loads or saves", "game.py exec refuses a load behind the allow-list", tool="game.py")
    t.expect(["run", SAVES[0], "--holder", f"A:{ta}"], 0, r"selftest: gate passed for game.py run", "game.py run passes with A's token", tool="game.py")
    t.expect(["load", SAVES[1].lower(), "--holder", f"A:{ta}"], 0, r"gate passed", "game.py load takes the test-only slot by full name", tool="game.py")
    fake = str(t.root / "fakebuild")
    t.expect(["--install-from", fake], 1, r"refused: .*--holder", "build_mod.py --install-from refused without --holder", tool="build_mod.py")
    t.expect(["--install-from", fake, "--holder", f"A:{ta}"], 0, r"gate passed for build_mod.py install",
             "build_mod.py --install-from passes with A's token", tool="build_mod.py")
    t.expect(["--ref", "5.x-GM", "--out", fake, "--install", "--scripts", "x"], 2, r"parent's", "build_mod.py refuses --scripts installs without --parent", tool="build_mod.py")
    t.expect(["--out", fake], 2, r"--ref is required", "build_mod.py needs --ref", tool="build_mod.py")
    st = json.loads((t.state / "state.json").read_text(encoding="utf-8"))
    t.check(st["holder"]["claimed"] and st["holder"]["last_cmd"] == "build_mod.py install", "gated commands claim the grant and renew the lease",
            json.dumps(st["holder"]))

    # --- release: refusals, then the restore, the log, the saves comparison -----------------
    t.flag.touch()
    t.expect(["release", "--holder", f"A:{ta}"], 1, r"game is running", "release refused while the game runs")
    t.flag.unlink()
    t.expect(["release", "--holder", "A:00000000"], 1, r"does not hold", "release refused with a wrong token")
    (t.docs / "dx12user.settings").write_text("[changed by the game]\n", encoding="utf-8")
    (t.docs / "scriptslog.txt").write_text("[GMTest] PASS from A\n", encoding="utf-8")
    (t.docs / "gamesaves" / "AutoSave_old_1.sav").unlink()       # an autosave rotation deleted an old save
    (t.docs / "gamesaves" / "AutoSave_new_2.sav").write_bytes(b"x")  # and wrote a new one
    out = t.expect(["release", "--holder", f"A:{ta}"], 0, r"settings restored.*archived.*1 gone, 1 new.*next: B",
                   "release restores, archives, compares, and grants B")
    t.check((t.docs / "dx12user.settings").read_text() == (t.state / "baseline" / "dx12user.settings").read_text(),
            "dx12user.settings restored from the baseline")
    logs = list((t.state / "logs").glob("A-*-scriptslog.txt"))
    t.check(len(logs) == 1 and "from A" in logs[0].read_text(), "A's script log archived", str(logs))
    t.check("gone: AutoSave_old_1.sav" in out and "new: AutoSave_new_2.sav" in out and "backup only: AutoSave_old_1.sav" in out,
            "the saves comparison names the deleted and the new save (nothing restored)", out)
    t.check(not (t.docs / "gamesaves" / "AutoSave_old_1.sav").exists(), "no save restored by the release")
    rc, out = finish(wb)
    t.check(rc == 0 and "granted" in (out or ""), "B's background wait exits 0 with the grant (FIFO)", str(out))
    tb = t.token(out or "")
    t.check(wc.poll() is None, "C still waits while B holds the slot")

    # --- the claim deadline: B never runs a game command --------------------------------------
    rc, out = finish(wc, 20)
    t.check(rc == 0 and "granted" in (out or ""), "B's grant skipped after the claim deadline; C granted", str(out))
    tc = t.token(out or "")
    t.expect(["exec", "x()", "--holder", f"B:{tb}"], 3, r"revoked.*claim deadline", "B's token refused after the skip (exit 3)", tool="game.py")
    t.check(any(e["event"] == "skip" and e["who"] == "B" for e in t.events()), "the skip is in the event log")
    t.expect(["wait", "--who", "B", "--timeout", "1"], 3, r"not queued: your last token was revoked", "B's wait reports the revocation (exit 3)")

    # --- game running and unrestored settings block grants ----------------------------------
    t.expect(["exec", "x()", "--holder", f"C:{tc}"], 0, r"gate passed", "C claims its grant", tool="game.py")
    t.flag.touch()
    t.expect(["release", "--holder", f"C:{tc}"], 1, r"game is running", "C's release refused while the game runs")
    t.flag.unlink()
    t.expect(["release", "--holder", f"C:{tc}"], 0, r"next: nobody waiting", "C released")
    t.flag.touch()
    t.expect(["request", "--who", "D", "--why", "x"], 2, r"blocked: the game is running", "no grant while the game runs (simulated)")
    t.flag.unlink()
    t.expect(["wait", "--who", "D", "--timeout", "5"], 0, r"granted", "D granted once the game is closed")
    out = t.expect(["status"], 0, r"holder: D", "status shows the holder")
    td = t.token(t.run("request", "--who", "D", "--why", "x")[1])
    t.expect(["exec", "x()", "--holder", f"D:{td}"], 0, r"gate passed", "D claims", tool="game.py")
    t.expect(["release", "--holder", f"D:{td}"], 0, r"released", "D released")
    (t.docs / "input.settings").write_text("[the owner played]\n", encoding="utf-8")
    t.expect(["request", "--who", "E", "--why", "x"], 2, r"settings differ from the baseline: input.settings",
             "no grant while the settings differ from the baseline")
    t.expect(["watch", "--once"], 4, r"ALERT: grants blocked: .*input.settings", "watch alerts on blocked grants")
    shutil.copy2(t.state / "baseline" / "input.settings", t.docs / "input.settings")
    te = t.token(t.expect(["wait", "--who", "E", "--timeout", "5"], 0, r"granted", "E granted once the settings match"))

    # --- the lease: expiry, watch, reclaim ----------------------------------------------------
    t.expect(["exec", "x()", "--holder", f"E:{te}"], 0, r"gate passed", "E claims", tool="game.py")
    time.sleep(4.5)
    t.expect(["status"], 0, r"lease EXPIRED", "status shows the expired lease")
    t.expect(["watch", "--once"], 4, r"ALERT: E's lease expired", "watch alerts on the expired lease")
    t.expect(["reclaim"], 1, r"parent only", "reclaim refused without --parent")
    t.flag.touch()
    t.expect(["reclaim", "--parent"], 0, r"settings restored.*reclaimed E's turn", "reclaim --parent quits the game and ends E's turn")
    t.check(not t.flag.exists(), "reclaim quit the (simulated) game")
    t.expect(["exec", "x()", "--holder", f"E:{te}"], 3, r"revoked.*reclaimed", "E's token refused after the reclaim (exit 3)", tool="game.py")

    # --- pause wakes the waiters with 3 and stops the holder ----------------------------------
    tf = t.token(t.expect(["request", "--who", "F", "--why", "x"], 0, r"granted", "F granted at once (slot free)"))
    t.expect(["exec", "x()", "--holder", f"F:{tf}"], 0, r"gate passed", "F claims", tool="game.py")
    t.expect(["request", "--who", "G", "--why", "x"], 2, r"queued", "G queued")
    wg = t.bg("wait", "--who", "G", "--timeout", "30")
    time.sleep(1)
    t.expect(["pause", "--by", "selftest", "--why", "owner wants the computer"], 0, r"paused", "pause")
    rc, out = finish(wg)
    t.check(rc == 3 and "paused" in (out or ""), "G's wait woken by the pause with exit 3", str(out))
    t.expect(["exec", "x()", "--holder", f"F:{tf}"], 3, r"paused by selftest", "F's game commands refused while paused (exit 3)", tool="game.py")
    t.expect(["request", "--who", "H", "--why", "x"], 3, r"queued: position 2.*paused", "a request while paused queues and exits 3")
    t.expect(["watch", "--once"], 4, r"ALERT: paused", "watch alerts on the pause")
    t.expect(["release", "--holder", f"F:{tf}"], 0, r"next: nobody", "F releases during the pause; nobody is granted")
    t.expect(["resume"], 0, r"resumed; holder: G", "resume grants G")

    # --- preempt ----------------------------------------------------------------------------
    tg = t.token(t.run("request", "--who", "G", "--why", "x")[1])
    t.expect(["exec", "x()", "--holder", f"G:{tg}"], 0, r"gate passed", "G claims", tool="game.py")
    t.flag.touch()
    (t.docs / "profile.settings").write_text("[changed]\n", encoding="utf-8")
    t.expect(["preempt"], 1, r"parent only", "preempt refused without --parent")
    t.expect(["preempt", "--parent", "--why", "selftest"], 0, r"settings restored.*preempted G's turn; next: H",
             "preempt --parent quits the game, restores the settings and grants H")
    t.check(not t.flag.exists(), "preempt quit the (simulated) game")
    t.check((t.docs / "profile.settings").read_text() == (t.state / "baseline" / "profile.settings").read_text(),
            "profile.settings restored by the preempt")
    t.expect(["exec", "x()", "--holder", f"G:{tg}"], 3, r"revoked.*preempted", "G's token refused after the preempt (exit 3)", tool="game.py")
    t.expect(["exec", "x()", "--parent"], 0, r"gate passed for game.py exec \(parent\)", "--parent bypasses the gate (logged)", tool="game.py")
    t.check(any(e["event"] == "parent-bypass" for e in t.events()), "the parent's bypass is in the event log")
    th = t.token(t.run("request", "--who", "H", "--why", "x")[1])
    t.expect(["cancel", "--who", "H"], 0, r"release it instead", "cancel tells a holder to release")
    t.expect(["request", "--who", "I", "--why", "x"], 2, r"queued", "I queued")
    t.expect(["cancel", "--who", "I"], 0, r"left the queue", "cancel leaves the queue")
    t.expect(["config", "--claim-deadline", "600"], 0, r'"claim_deadline_s": 600', "the claim deadline is configurable")
    t.expect(["config", "--claim-deadline", "3"], 0, r'"claim_deadline_s": 3', "and set back")
    t.expect(["exec", "x()", "--holder", f"H:{th}"], 0, r"gate passed", "H claims", tool="game.py")
    t.expect(["release", "--holder", f"H:{th}"], 0, r"released", "H released")

    # --- a process killed while it holds the msvcrt lock -------------------------------------
    holder = subprocess.Popen([PY, "-c", "import sys,time; sys.path.insert(0, r'%s'); import game_lock; "
                               "l = game_lock.FileLock(game_lock.Env().lockfile); l.__enter__(); print('locked', flush=True); time.sleep(120)"
                               % TOOLS], env=t.env, stdout=subprocess.PIPE, text=True)
    t.check(holder.stdout.readline().strip() == "locked", "a helper process takes the msvcrt lock")
    st_proc = t.bg("status")
    time.sleep(2)
    t.check(st_proc.poll() is None, "status waits while the helper holds the lock")
    holder.kill()
    holder.wait()
    rc, out = finish(st_proc, 20)
    t.check(rc == 0 and "holder: none" in (out or ""), "after the helper is killed, the next process gets in", str(out))

    # --- concurrent requests: one queue entry each, state intact ------------------------------
    procs = [t.bg("request", "--who", f"P{i}", "--why", "race") for i in range(6)]
    for p in procs:
        finish(p, 30)
    st = json.loads((t.state / "state.json").read_text(encoding="utf-8"))
    names = ([st["holder"]["who"]] if st["holder"] else []) + [q["who"] for q in st["queue"]]
    t.check(sorted(names) == [f"P{i}" for i in range(6)], "six concurrent requests: each agent once, state intact", str(names))


def run(keep: bool = False) -> int:
    root = Path(tempfile.mkdtemp(prefix="tgm-lock-selftest-"))
    print(f"selftest folder: {root}")
    t = setup(root)
    t0 = time.monotonic()
    try:
        scenario(t)
    finally:
        if not keep:
            shutil.rmtree(root, ignore_errors=True)
    print(f"SUMMARY selftest: {t.passed} passed, {t.failed} failed ({time.monotonic() - t0:.0f} s)")
    return 0 if t.failed == 0 else 1


if __name__ == "__main__":
    sys.exit(run("--keep" in sys.argv))
