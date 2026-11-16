"""The regression run in one or both skill trees, through game.py (docs/development.md#testing-in-game).

    python tools/regress.py --holder AREA:TOKEN [--trees both|classic|new] [--wait 6000] [--no-retry]

Per tree, on a fresh launch of the test save (game.py run, which locks saving with gmtest_nosave()):
  1. autoconfigset(GMGameplayOptions, GMClassicSkillTree, false) and gmreset() in one call for the new tree,
     the same with true for the classic tree (the settings baseline may hold either tree);
  2. gmtest_regress() (exec --wait 6000), ingamemenu(), gmtest_panel(), each its own call; resume;
  3. the new tree only: the classic tree set back (autoconfigset(..., true)), always, also after a failure;
  4. quit; the script log archived (%LOCALAPPDATA%\\TGM\\logs\\regress-<holder>-<tree>-<time>.txt).
Counts: gmtest_regress()'s SUMMARY line, and the PASS and FAIL lines after it (gmtest_panel() and the
regression checks it reports later). god() is never called (it hides effects the checks read).

Known timing flakes (AI-18's stone knockdown, AI-10's counter window): when they are a tree's only failures,
the tree runs once more on a fresh launch, and a flake counts as failed only if it fails in both runs.

Needs the game slot (tools/game_lock.py) and the holder's build installed (build_mod.py --install-from).
Exit code 0 when every tree passed, 1 otherwise.

Needs, not in this repository: the same as game.py (it drives the game through it), and a Ghost Mode build with its test scripts installed.
"""

import argparse
import datetime
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
import game_lock  # noqa: E402
from paths import documents_dir  # noqa: E402

TO_NEW = ["autoconfigset(GMGameplayOptions, GMClassicSkillTree, false)", "gmreset()"]
TO_CLASSIC = ["autoconfigset(GMGameplayOptions, GMClassicSkillTree, true)"]
FLAKES = (re.compile(r"^AI-18 a stone"), re.compile(r"^AI-10 (hit and defend counters|counters' window)"))
LOG = documents_dir() / "The Witcher 3" / "scriptslog.txt"
SETTINGS = documents_dir() / "The Witcher 3" / "dx12user.settings"


def say(msg):
    print(f"[regress] {msg}", flush=True)


class Run:
    def __init__(self, a):
        self.a = a
        self.gate = ["--parent"] if a.parent else ["--holder", a.holder]

    def game(self, *args, check=True, wait=None):
        cmd = [sys.executable, str(TOOLS / "game.py"), *args]
        if args[0] in ("run", "start", "load", "exec", "resume"):
            cmd += self.gate
        if wait:
            cmd += ["--wait", str(wait)]
        r = subprocess.run(cmd, capture_output=True, text=True, errors="replace")
        out = (r.stdout + r.stderr).strip()
        if check and r.returncode != 0:
            raise RuntimeError(f"game.py {' '.join(args)} failed (exit {r.returncode}):\n{out[-2000:]}")
        return out

    def running(self):
        return game_lock.Env().game_running()


def read_log():
    try:
        return LOG.read_text(encoding="utf-8", errors="replace").splitlines()
    except FileNotFoundError:
        return []


def settle(timeout=40, quiet=3.0):
    """Wait until the script log stops growing (checks that report a frame or more later)."""
    end, last, since = time.monotonic() + timeout, -1, time.monotonic()
    while time.monotonic() < end:
        n = len(read_log())
        if n != last:
            last, since = n, time.monotonic()
        elif time.monotonic() - since >= quiet:
            return
        time.sleep(0.5)


def parse(lines):
    """(regress passed, failed, panel passed, failed, FAIL labels, problems) from one run's script log."""
    problems = []
    idx = next((i for i, l in enumerate(lines) if "SUMMARY regress:" in l), None)
    if idx is None:
        return None, None, None, None, [], ["no 'SUMMARY regress' line in the script log"]
    m = re.search(r"SUMMARY regress: (\d+) passed, (\d+) failed", lines[idx])
    rp, rf = int(m.group(1)), int(m.group(2))
    start = max((i for i, l in enumerate(lines[:idx]) if "[Automation] ready" in l), default=0)
    before = lines[start:idx]
    lp = sum(1 for l in before if re.search(r"\] PASS ", l))
    lf = sum(1 for l in before if re.search(r"\] FAIL ", l))
    if (lp, lf) != (rp, rf):
        problems.append(f"note: {lp} PASS and {lf} FAIL lines before the SUMMARY line (the SUMMARY says {rp}, {rf})")
    after = lines[idx + 1:]
    pp = sum(1 for l in after if re.search(r"\] PASS ", l))
    pf = sum(1 for l in after if re.search(r"\] FAIL ", l))
    fails = [l.split("] FAIL ", 1)[1] for l in lines[start:] if "] FAIL " in l]
    return rp, rf, pp, pf, fails, problems


def one_tree(r, tree, attempt):
    a = r.a
    label = f"{tree}" + (f" (run {attempt})" if attempt > 1 else "")
    say(f"--- {label}: launching {a.save}")
    switched = False
    archived = None
    error = None
    try:
        if r.running():
            raise RuntimeError("the game is already running: quit it first (python tools/game.py quit)")
        print(r.game("run", a.save))
        if tree == "new":
            print(r.game("exec", *TO_NEW, wait=3000))
            switched = True
        else:  # the save takes its tree from the option at load, and the baseline may hold the new tree
            print(r.game("exec", *TO_CLASSIC, "gmreset()", wait=3000))
        print(r.game("exec", "gmtest_regress()", wait=a.wait)[-400:])
        settle(timeout=20, quiet=2)
        r.game("exec", "ingamemenu()")
        print(r.game("exec", "gmtest_panel()", wait=3000)[-400:])
        settle()
        r.game("resume")
    except RuntimeError as e:
        error = str(e)
        say(f"ERROR: {error}")
    finally:
        if switched:
            try:
                print(r.game("exec", *TO_CLASSIC))
                say("classic tree set back")
            except Exception as e:  # the release restores the settings baseline anyway
                say(f"WARNING: could not set the classic tree back in game: {e}")
        lines = read_log()
        say(r.game("quit", check=False))
        dst = game_lock.Env().logs / f"regress-{a.who}-{tree}-{datetime.datetime.now():%Y%m%d-%H%M%S}.txt"
        if LOG.exists():
            shutil.copy2(LOG, dst)
            archived = dst
            say(f"script log archived: {dst}")
    if switched and SETTINGS.exists() and "GMClassicSkillTree=true" not in SETTINGS.read_text(encoding="utf-8", errors="replace"):
        say("WARNING: dx12user.settings does not hold GMClassicSkillTree=true after the run (the release restores the baseline)")
    res = parse(lines)
    if error:
        res = (None,) * 4 + (res[4], [f"error: {error.splitlines()[0]}"] + res[5])
    return label, res, archived


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--holder", help="AREA:TOKEN of the game slot (tools/game_lock.py)")
    ap.add_argument("--parent", action="store_true", help="the parent only: no lock check (logged by the lock)")
    ap.add_argument("--trees", choices=("both", "classic", "new"), default="both")
    ap.add_argument("--save", default="test", help="the save to load: test (default, the configured test save), slot "
                                                   "or an allowed save's full name (docs/game-automation.md#test-saves)")
    ap.add_argument("--wait", type=int, default=6000, help="exec --wait for gmtest_regress() (default 6000 ms)")
    ap.add_argument("--no-retry", action="store_true", help="no second run when only a known flake failed")
    a = ap.parse_args()
    if not a.holder and not a.parent:
        ap.error("--holder AREA:TOKEN is required (the game slot's holder)")
    a.who = "parent" if a.parent else a.holder.split(":", 1)[0]
    r = Run(a)
    trees = ["classic", "new"] if a.trees == "both" else [a.trees]
    results, ok = [], True
    for tree in trees:
        attempt, prev_flakes = 1, None
        while True:
            label, res, archived = one_tree(r, tree, attempt)
            rp, rf, pp, pf, fails, problems = res
            results.append((label, res, archived))
            if rp is None:
                ok = False
                break
            flakes = {f for f in fails if any(p.match(f) for p in FLAKES)}
            only_flakes = fails and len(flakes) == len(fails)
            if not fails:
                break
            if only_flakes and prev_flakes is None and not a.no_retry:
                say(f"{tree}: only known flakes failed ({len(fails)}); once more on a fresh launch")
                prev_flakes, attempt = flakes, attempt + 1
                continue
            if only_flakes and prev_flakes is not None and not (flakes & prev_flakes):
                say(f"{tree}: a different flake failed than in the first run: not twice in a row")
                break
            ok = False
            break
    print()
    say("=== results")
    for label, (rp, rf, pp, pf, fails, problems), archived in results:
        if rp is None:
            say(f"{label}: no result ({'; '.join(problems)})")
            continue
        say(f"{label}: gmtest_regress() {rp} passed, {rf} failed; gmtest_panel() {pp} passed, {pf} failed")
        for f in fails:
            say(f"  FAIL {f}")
        for p in problems:
            say(f"  {p}")
        if archived:
            say(f"  log: {archived}")
    say("PASSED" if ok else "FAILED")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
