"""Run every generator in its dependency order, check or verify them all, or list what they write.

    python tools/gen_all.py --worktree ../TGM-<area>              write: every generator in ORDER, one after another
    python tools/gen_all.py --worktree ../TGM-<area> --check      every --check (nothing written), in parallel
    python tools/gen_all.py --worktree ../TGM-<area> --verify     every --check and --verify, plus dlc_conflicts.py
                                                                  and check_modsigns.py (nothing written), in parallel
    python tools/gen_all.py --worktree ../TGM-<area> --list       the generated paths, by generator

The integrator's tool (docs/proposals/parallel-ports.md, section 6): after merging an area, take either side
of a generated file, then rebuild them all with the merged tools and verify. Area agents run it before
requesting the game slot (`--verify`).

Order (each generator's inputs are written before it runs):
- writers that read only git and attribution.csv: gen_test_dummy, gen_ai, gen_diff, gen_xp;
- gen_npc_stamina after gen_ai and gen_diff (it leaves out the abilities they give whole);
- gen_ngplus after every writer of `abilities/` (test dummy, AI, DIFF, XP, NPC stamina): it copies the folder
  into `abilities_plus/`;
- the item writers: gen_ench, gen_alch, gen_food, gen_xbow, gen_trph, gen_arm_items, gen_swd_items, gen_arm_km,
  gen_arm_new, gen_craft;
- gen_ai_ent, then gen_loot (both write the entity files LOOT and AI share; gen_loot reads the DLC's items);
- gen_item after the other item tools (it skips the names they define);
- gen_econ (it skips the names every other DLC file defines, and verifies the final items), then gen_wgt
  (WGT's weights as the game reads them, and their data test).

Every generator runs at below-normal priority, with its output in a log folder (printed at the end; the
last lines of a failed one are printed). Exit code 1 if any fails.
"""

import argparse
import concurrent.futures
import datetime
import glob
import os
import subprocess
import sys
import tempfile
import time

TOOLS = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, TOOLS)
import paths  # noqa: E402

# (generator, has --verify)
ORDER = [
    ("gen_test_dummy", False), ("gen_ai", True), ("gen_diff", True), ("gen_xp", True),
    ("gen_npc_stamina", False), ("gen_ngplus", True),
    ("gen_ench", True), ("gen_alch", True), ("gen_food", True), ("gen_xbow", True),
    ("gen_trph", True),
    ("gen_arm_items", True),
    ("gen_swd_items", True), ("gen_arm_km", True), ("gen_arm_new", False), ("gen_craft", True),
    ("gen_ai_ent", True), ("gen_loot", True), ("gen_item", True), ("gen_econ", True), ("gen_wgt", True),
]
CHECKS = ["dlc_conflicts", "check_modsigns"]  # guards run with --verify
DLC = "modGhostMode/files/dlc/dlcghostmode/data/gameplay/"
TESTS = "modGhostMode/scripts/local/gm/tests/"


def run(tool, args, wt, logdir):
    t0 = time.monotonic()
    log = os.path.join(logdir, f"{tool}{('_' + args[0].lstrip('-')) if args else ''}.log")
    with open(log, "w", encoding="utf-8", errors="replace") as f:
        r = subprocess.run([sys.executable, os.path.join(TOOLS, tool + ".py"), "--worktree", wt, *args], stdout=f,
                           stderr=subprocess.STDOUT, creationflags=paths.BELOW_NORMAL, env=dict(os.environ, PYTHONIOENCODING="utf-8"))
    return tool, " ".join(args) or ("check" if tool in CHECKS else "write"), r.returncode, time.monotonic() - t0, log


def report(res):
    tool, mode, rc, secs, log = res
    print(f"{'ok  ' if rc == 0 else 'FAIL'} {tool:16} {mode:9} exit {rc}  {secs:5.0f} s", flush=True)
    if rc != 0:
        lines = open(log, encoding="utf-8", errors="replace").read().splitlines()
        for line in lines[-12:]:
            print(f"     | {line}")
    return rc == 0


def generated(wt):
    """{path: generator} of every file the generators write (relative to the worktree)."""
    import gen_ai, gen_ai_ent, gen_arm_items, gen_craft, gen_diff, gen_econ, gen_loot, gen_npc_stamina, gen_test_dummy, gen_xp  # noqa: E401
    out = {}

    def add(gen, *ps):
        for p in ps:
            out.setdefault(p.replace("\\", "/"), gen)
    add("gen_test_dummy", gen_test_dummy.DEST, gen_test_dummy.DEST_WS)
    add("gen_ai", *(DLC + f"{folder}/{f}" for folder, f in gen_ai.outputs()), gen_ai.TESTS)
    add("gen_diff", DLC + "abilities/" + gen_diff.OUT, gen_diff.TESTS)
    add("gen_xp", DLC + "abilities/" + gen_xp.OUT, gen_xp.TESTS, gen_xp.TESTS_X2, gen_xp.NAMES_WS, *gen_xp.QUEST_LEVELS)
    add("gen_npc_stamina", gen_npc_stamina.OUT)
    for f in sorted(glob.glob(os.path.join(wt, DLC, "abilities", "*.xml"))):
        add("gen_ngplus", DLC + "abilities_plus/" + os.path.basename(f))
    for gen, name in (("gen_ench", "gm_ench.xml"), ("gen_alch", "gm_alch.xml"), ("gen_food", "gm_food.xml"),
                      ("gen_xbow", "gm_xbow.xml"), ("gen_arm_items", gen_arm_items.OUT), ("gen_arm_items", gen_arm_items.OUT_EXT),
                      ("gen_swd_items", "gm_swd_items.xml"), ("gen_arm_km", "gm_arm_kaer_morhen.xml"),
                      ("gen_arm_new", "gm_arm_new.xml"), ("gen_item", "gm_item.xml"), ("gen_econ", gen_econ.OUT)):
        add(gen, DLC + "items/" + name, DLC + "items_plus/" + name)
    add("gen_food", *(f"modGhostMode/localization/modGhostModeFood/{lang}.csv" for lang in ("br", "cz", "de", "en", "es", "fr", "it", "pl", "ru")))
    add("gen_craft", *gen_craft.units(), gen_craft.DLC_FILE % "items", gen_craft.DLC_FILE % "items_plus")
    add("gen_ai_ent", *gen_ai_ent.units(), *gen_ai_ent.GAME_FILES, gen_ai_ent.TESTS)
    add("gen_loot", *gen_loot.units(), *gen_loot.bin_units(), gen_loot.ECON_TESTS)
    add("gen_econ", gen_econ.TEST)
    add("gen_wgt", TESTS + "gmTestsWgtData.ws")
    import gen_trph
    add("gen_trph", DLC + "items/" + gen_trph.OUT, DLC + "items_plus/" + gen_trph.OUT, gen_trph.TESTS)
    return out


def cmd_list(wt):
    gen = generated(wt)
    missing = [p for p in gen if not os.path.exists(os.path.join(wt, p))]
    for p, g in sorted(gen.items(), key=lambda x: (x[1], x[0])):
        print(f"{g:16} {p}" + ("   (not in the worktree: 5.x's own file is used)" if p in missing else ""))
    # files that say they are generated but are not listed: the list is out of date
    marked = subprocess.run(["git", "-C", wt, "grep", "-l", "-I", "-i", "-E", r"^\W*(<!--\s*)?(Generated by|New Game\+ copy of .*generated by) tools/gen_",
                             "--", "modGhostMode"], capture_output=True, text=True).stdout.split()
    unlisted = sorted(set(marked) - set(gen))
    print(f"{len(gen)} generated paths ({len(gen) - len(missing)} in the worktree)")
    for p in unlisted:
        print(f"WARNING: {p} is marked as generated but no generator lists it")
    return 1 if unlisted else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    paths.add_worktree(ap)
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--check", action="store_true", help="every generator's --check (writes nothing)")
    g.add_argument("--verify", action="store_true", help="every --check and --verify, dlc_conflicts and check_modsigns")
    g.add_argument("--list", action="store_true", help="the generated paths")
    ap.add_argument("-j", "--jobs", type=int, default=4, help="parallel jobs for --check and --verify (default 4)")
    ap.add_argument("--only", nargs="+", metavar="GEN", help="only these generators (e.g. gen_item gen_econ)")
    a = ap.parse_args()
    wt = os.path.abspath(a.worktree)
    if a.list:
        sys.exit(cmd_list(wt))
    order = [(n, v) for n, v in ORDER if not a.only or n in a.only]
    logdir = os.path.join(tempfile.gettempdir(), f"gen_all-{datetime.datetime.now():%Y%m%d-%H%M%S}")
    os.makedirs(logdir, exist_ok=True)
    t0 = time.monotonic()
    ok = True
    if not (a.check or a.verify):
        for name, _ in order:  # in order: later generators read earlier ones' output
            ok &= report(run(name, [], wt, logdir))
            if not ok:
                print(f"stopped: {name} failed (the later generators read its output)")
                break
        st = subprocess.run(["git", "-C", wt, "status", "--porcelain", "--", "modGhostMode"], capture_output=True, text=True).stdout
        print("changed in the worktree:" if st.strip() else "nothing changed in the worktree")
        print(st.rstrip())
    else:
        jobs = [(name, ["--check"]) for name, _ in order]
        if a.verify:
            jobs += [(name, ["--verify"]) for name, v in order if v]
            jobs += [(name, []) for name in CHECKS if not a.only or name in a.only]
        with concurrent.futures.ThreadPoolExecutor(max_workers=a.jobs) as ex:  # read-only: any order
            for fut in [ex.submit(run, n, args, wt, logdir) for n, args in jobs]:
                ok &= report(fut.result())
    print(f"{'all passed' if ok else 'FAILED'} in {time.monotonic() - t0:.0f} s; logs: {logdir}")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
